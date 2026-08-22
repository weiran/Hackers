//
//  PostRepository+Commenting.swift
//  Data
//
//  Hacker News website comment submission, confirmation, classification,
//  and server-comment resolution.
//

import Domain
import Foundation
import Networking
import SwiftSoup

// MARK: - Form model

/// A Hacker News `<form action="comment">` extracted from an item or reply page.
struct HNCommentForm {
    let action: URL
    /// All named controls in document order, including server-provided hidden fields.
    let fields: [FormField]
}

// MARK: - Comment submission

extension PostRepository {
    public func submitComment(
        _ request: CommentSubmissionRequest,
        baselineChildIDs: Set<Int>
    ) async throws -> CommentSubmissionOutcome {
        try Self.validate(request)

        guard let hnURL = URL(string: urlBase) else {
            throw HackersKitError.requestFailure
        }
        guard networkManager.containsCookie(named: "user", for: hnURL) else {
            throw CommentSubmissionError.unauthenticated
        }

        let startedAt = Date()
        let page = try await fetchCommentFormPage(for: request)

        do {
            let form = try commentForm(
                in: page.body,
                expectedParent: request.parentID
            )
            let outcome = try await submit(form: form, request: request, allowConfirmation: true)
            switch outcome {
            case let .accepted(response):
                if let submitted = try await resolveSubmittedComment(
                    in: response,
                    request: request,
                    baselineChildIDs: baselineChildIDs,
                    startedAt: startedAt
                ) {
                    return .confirmed(submitted)
                }
                let attempt = CommentSubmissionAttempt(
                    request: request,
                    baselineChildIDs: baselineChildIDs,
                    startedAt: startedAt
                )
                if let submitted = try await reconcileComment(attempt) {
                    return .confirmed(submitted)
                }
                return .unconfirmed(attempt)
            case let .rejected(message):
                throw CommentSubmissionError.rejected(message: message)
            }
        } catch let error as CommentSubmissionError {
            throw error
        } catch {
            // The form was fetched and the POST may have reached Hacker News
            // before the transport failure; never offer a blind retry.
            let attempt = CommentSubmissionAttempt(
                request: request,
                baselineChildIDs: baselineChildIDs,
                startedAt: startedAt
            )
            if let submitted = try await reconcileComment(attempt) {
                return .confirmed(submitted)
            }
            return .unconfirmed(attempt)
        }
    }

    public func reconcileComment(
        _ attempt: CommentSubmissionAttempt
    ) async throws -> SubmittedComment? {
        let request = attempt.request
        if let submitted = try await resolveFromItemPage(
            storyID: request.storyID,
            request: request,
            baselineChildIDs: attempt.baselineChildIDs
        ) {
            return submitted
        }
        return try await resolveFromThreadsPage(request: request)
    }

    // MARK: - Validation

    private static func validate(_ request: CommentSubmissionRequest) throws {
        guard request.storyID > 0, request.parentID > 0 else {
            throw CommentSubmissionError.invalidTarget
        }
        guard !request.expectedAuthor.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw CommentSubmissionError.invalidTarget
        }
        guard !request.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw CommentSubmissionError.empty
        }
    }

    // MARK: - Form fetching

    private func fetchCommentFormPage(for request: CommentSubmissionRequest) async throws -> NetworkResponse {
        let formURL: URL
        if request.parentID == request.storyID {
            guard let url = URL(string: "\(urlBase)/item?id=\(request.storyID)") else {
                throw HackersKitError.requestFailure
            }
            formURL = url
        } else {
            let goto = "item%3Fid%3D\(request.storyID)%23\(request.parentID)"
            guard let url = URL(string: "\(urlBase)/reply?id=\(request.parentID)&goto=\(goto)") else {
                throw HackersKitError.requestFailure
            }
            formURL = url
        }

        let page = try await networkManager.getResponse(url: formURL)

        if page.body.contains("You have to be logged in to comment.")
            || page.body.contains("name=\"acct\"") {
            throw CommentSubmissionError.unauthenticated
        }

        guard (try? commentForm(in: page.body, expectedParent: request.parentID)) != nil else {
            throw CommentSubmissionError.commentingUnavailable
        }
        return page
    }

    // MARK: - Form extraction

    func commentForm(in html: String, expectedParent: Int) throws -> HNCommentForm {
        let document = try SwiftSoup.parse(html)
        let forms = try document.select("form").array()

        for form in forms {
            let actionValue = try form.attr("action")
            guard let resolvedAction = URL(string: actionValue, relativeTo: URL(string: urlBase)),
                  let absoluteAction = URL(string: resolvedAction.absoluteString) else {
                continue
            }
            guard absoluteAction.scheme == "https",
                  absoluteAction.host == "news.ycombinator.com",
                  absoluteAction.path == "/comment" else {
                continue
            }

            var fields: [FormField] = []
            var parentValue: Int?
            for input in try form.select("input").array() {
                let name = try input.attr("name")
                guard !name.isEmpty else { continue }
                let value = try input.attr("value")
                if name == "parent" {
                    parentValue = Int(value)
                }
                if try input.attr("type") == "hidden" {
                    fields.append(FormField(name: name, value: value))
                }
            }
            for textarea in try form.select("textarea").array() {
                let name = try textarea.attr("name")
                guard !name.isEmpty else { continue }
                fields.append(FormField(name: name, value: try textarea.text()))
            }

            guard parentValue == expectedParent, fields.contains(where: { $0.name == "hmac" }) else {
                continue
            }

            return HNCommentForm(action: absoluteAction, fields: fields)
        }

        throw CommentSubmissionError.commentingUnavailable
    }

    // MARK: - Submission

    private enum SubmissionResponse {
        /// Hacker News accepted the submission and landed on an item page.
        case accepted(NetworkResponse)
        /// A safe, definite rejection message extracted from a server page.
        case rejected(String?)
    }

    private func submit(
        form: HNCommentForm,
        request: CommentSubmissionRequest,
        allowConfirmation: Bool
    ) async throws -> SubmissionResponse {
        let fields = form.fields.map { field in
            switch field.name {
            case "parent":
                FormField(name: field.name, value: String(request.parentID))
            case "text":
                FormField(name: field.name, value: request.text)
            default:
                field
            }
        }

        let response = try await networkManager.postResponse(
            url: form.action,
            body: FormEncoder.encode(fields)
        )

        if response.body.contains("You have to be logged in to comment.") {
            throw CommentSubmissionError.unauthenticated
        }

        // URLSession follows redirects, so /x confirm and message pages arrive
        // as their final 200 responses keyed by the final URL.
        if let components = URLComponents(url: response.finalURL, resolvingAgainstBaseURL: false),
           components.path == "/x" {
            let operation = components.queryItems?.first(where: { $0.name == "fnop" })?.value
            if operation == "commconfirm" {
                guard allowConfirmation else {
                    throw CommentSubmissionError.malformedResponse
                }
                let confirmForm = try commentForm(
                    in: response.body,
                    expectedParent: request.parentID
                )
                // The confirmation page re-renders the same form with the
                // submitted text prefilled; resubmitting once is the confirm.
                let confirmRequest = CommentSubmissionRequest(
                    storyID: request.storyID,
                    parentID: request.parentID,
                    expectedAuthor: request.expectedAuthor,
                    text: request.text
                )
                return try await submit(
                    form: confirmForm,
                    request: confirmRequest,
                    allowConfirmation: false
                )
            }
            return .rejected(Self.safeMessage(fromXPageBody: response.body))
        }

        if let components = URLComponents(url: response.finalURL, resolvingAgainstBaseURL: false),
           components.path == "/login" {
            throw CommentSubmissionError.unauthenticated
        }

        // A 2xx landing on the item page (redirect followed) — or staying on
        // /comment without a redirect — is apparently accepted; resolution
        // decides. Anything else is a definite rejection.
        guard (200 ... 299).contains(response.statusCode),
              response.finalURL.host == "news.ycombinator.com",
              response.finalURL.path == "/item" || response.finalURL.path == "/comment" else {
            return .rejected(nil)
        }

        return .accepted(response)
    }

    /// Extracts a short, safe message from an /x server message page.
    private static func safeMessage(fromXPageBody body: String) -> String? {
        guard let document = try? SwiftSoup.parse(body),
              let message = try? document.body()?.text() else {
            return nil
        }
        let knownMessages = [
            "Please try again.",
            "You're posting too fast. Please slow down.",
            "You have to be logged in to comment."
        ]
        return knownMessages.first { message.contains($0) }
    }

    // MARK: - Resolution

    private func resolveSubmittedComment(
        in response: NetworkResponse,
        request: CommentSubmissionRequest,
        baselineChildIDs: Set<Int>,
        startedAt: Date
    ) async throws -> SubmittedComment? {
        try matchSubmittedComment(
            in: response.body,
            request: request,
            baselineChildIDs: baselineChildIDs,
            startedAt: startedAt
        )
    }

    private func resolveFromItemPage(
        storyID: Int,
        request: CommentSubmissionRequest,
        baselineChildIDs: Set<Int>
    ) async throws -> SubmittedComment? {
        for delay in [0.0, 1.5, 3.0] {
            if delay > 0 {
                await submissionWaiter(delay)
            }
            guard let url = URL(string: "\(urlBase)/item?id=\(storyID)") else {
                throw HackersKitError.requestFailure
            }
            let page = try await networkManager.getResponse(url: url)
            if let submitted = try matchSubmittedComment(
                in: page.body,
                request: request,
                baselineChildIDs: baselineChildIDs,
                startedAt: Date()
            ) {
                return submitted
            }
        }
        return nil
    }

    private func resolveFromThreadsPage(request: CommentSubmissionRequest) async throws -> SubmittedComment? {
        guard let url = URL(string: "\(urlBase)/threads?id=\(request.expectedAuthor)") else {
            throw HackersKitError.requestFailure
        }
        let page = try await networkManager.getResponse(url: url)

        guard let document = try? SwiftSoup.parse(page.body) else {
            return nil
        }
        let rows = (try? document.select("tr.athing").array()) ?? []
        for row in rows.prefix(10) {
            guard let rowID = Int(try row.attr("id")) else {
                continue
            }
            // The row's on-link must point at the target story.
            let onLink = (try? row.select("a[href^=item?id=]").array())?.first
            guard let href = try onLink?.attr("href"),
                  href.contains("id=\(request.storyID)") else {
                continue
            }
            // Hydrate the candidate through the item page so the inserted
            // comment carries server-rendered HTML.
            guard let itemURL = URL(string: "\(urlBase)/item?id=\(request.storyID)") else {
                continue
            }
            let itemPage = try await networkManager.getResponse(url: itemURL)
            if let submitted = try matchSubmittedComment(
                in: itemPage.body,
                request: request,
                baselineChildIDs: [],
                startedAt: Date(),
                requiredID: rowID
            ) {
                return submitted
            }
        }
        return nil
    }

    // MARK: - Matching

    func matchSubmittedComment(
        in html: String,
        request: CommentSubmissionRequest,
        baselineChildIDs: Set<Int>,
        startedAt: Date,
        requiredID: Int? = nil
    ) throws -> SubmittedComment? {
        guard let document = try? SwiftSoup.parse(html) else {
            return nil
        }
        let parsed = try comments(from: document)

        var candidates = parsed.filter { comment in
            comment.by == request.expectedAuthor && !baselineChildIDs.contains(comment.id)
        }
        if let requiredID {
            candidates = candidates.filter { $0.id == requiredID }
        }
        guard !candidates.isEmpty else { return nil }

        if request.parentID != request.storyID {
            // Keep only comments that live inside the parent's subtree.
            candidates = candidates.filter { comment in
                child(of: request.parentID, comment: comment, in: parsed)
            }
        } else {
            candidates = candidates.filter { $0.level == 0 }
        }

        if candidates.count > 1 {
            let normalizedText = CommentTextNormalizer.normalizeSubmitted(request.text)
            let exact = candidates.filter {
                CommentTextNormalizer.normalizeServerHTML($0.text) == normalizedText
            }
            guard exact.count == 1 else { return nil }
            candidates = exact
        }

        guard let match = candidates.last else { return nil }
        return SubmittedComment(
            id: match.id,
            parentID: request.parentID,
            author: match.by,
            htmlText: match.text,
            createdAt: startedAt,
            upvoted: match.upvoted,
            voteLinks: match.voteLinks
        )
    }

    private func child(of parentID: Int, comment: Domain.Comment, in all: [Domain.Comment]) -> Bool {
        guard let parentIndex = all.firstIndex(where: { $0.id == parentID }) else {
            return false
        }
        guard let commentIndex = all.firstIndex(where: { $0.id == comment.id }) else {
            return false
        }
        guard commentIndex > parentIndex else { return false }
        let parentLevel = all[parentIndex].level
        for index in (parentIndex + 1) ..< commentIndex where all[index].level <= parentLevel {
            return false
        }
        return comment.level > parentLevel
    }
}

// MARK: - Text normalisation

enum CommentTextNormalizer {
    /// Sentinel that survives SwiftSoup's `text()` whitespace collapsing so
    /// paragraph boundaries inserted from markup are preserved.
    private static let newlineSentinel = "\u{01}"

    /// Normalises user-submitted plain text for matching only.
    static func normalizeSubmitted(_ text: String) -> String {
        normalize(text.replacingOccurrences(of: "\r\n", with: "\n"))
    }

    /// Normalises server-rendered comment HTML for matching only.
    static func normalizeServerHTML(_ html: String) -> String {
        let paragraphSeparated = html
            .replacingOccurrences(of: "<p>", with: "\n", options: .caseInsensitive)
            .replacingOccurrences(of: "<br>", with: "\n", options: .caseInsensitive)
            .replacingOccurrences(of: "<br/>", with: "\n", options: .caseInsensitive)
            .replacingOccurrences(of: "\n", with: newlineSentinel)
        let decoded = (try? SwiftSoup.parse(paragraphSeparated).text()) ?? paragraphSeparated
        return normalize(decoded.replacingOccurrences(of: newlineSentinel, with: "\n"))
    }

    private static func normalize(_ text: String) -> String {
        text
            .split(separator: "\n", omittingEmptySubsequences: false)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
            .joined(separator: "\n")
    }
}
