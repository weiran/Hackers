//
//  CommentSubmissionTests.swift
//  DataTests
//
//  Hacker News website comment submission against inline fixtures modeled on
//  live captures from 2026-08-21 (sanitized: fake IDs, authors, and tokens).
//

@testable import Data
import Domain
@testable import Networking
import Testing
import Foundation

@Suite("Comment submission")
struct CommentSubmissionTests {
    let network = CommentNetworkMock()
    var repository: PostRepository {
        PostRepository(networkManager: network, submissionWaiter: { _ in })
    }

    static let storyID = 100
    static let existingCommentID = 9_000
    static let newCommentID = 9_001

    static func request(
        parentID: Int = storyID,
        text: String = "First paragraph.\n\nSecond paragraph.",
        author: String = "alice"
    ) -> CommentSubmissionRequest {
        CommentSubmissionRequest(
            storyID: CommentSubmissionTests.storyID,
            parentID: parentID,
            expectedAuthor: author,
            text: text
        )
    }

    // MARK: - Fixtures

    static func commentRow(
        id: Int,
        author: String,
        indent: Int,
        html: String,
        voteLinksHTML: String = ""
    ) -> String {
        """
        <tr class="athing comtr" id="\(id)"><td><table border="0"><tr>\
        <td class="ind" indent="\(indent)"><img src="s.gif" height="1" width="\(indent * 40)"></td>\
        \(voteLinksHTML)\
        <td class="default"><div style="margin-top:2px; margin-bottom:-10px;">\
        <span class="comhead"><a href="user?id=\(author)" class="hnuser">\(author)</a> \
        <span class="age" title="2026-08-21T12:00:00 1787313600"><a href="item?id=\(id)">0 minutes ago</a></span> \
        <span class="par"></span></span><br><div class="comment"><div class="commtext">\(html)</div></div>\
        </div></td></tr></table></td></tr>
        """
    }

    static var storyTable: String {
        """
        <table class="fatitem"><tr class="athing" id="100"><td class="title">\
        <span class="titleline"><a href="https://example.com">Example story</a></span></td></tr></table>
        """
    }

    static func topLevelFormPage(parentID: Int, hmac: String = "a1b2c3") -> String {
        """
        <html><body>\(storyTable)<table border="0" class="comment-tree"></table><br>
        <form action="comment" method="post">\
        <input type="hidden" name="parent" value="\(parentID)">\
        <input type="hidden" name="goto" value="item?id=\(storyID)">\
        <input type="hidden" name="hmac" value="\(hmac)">\
        <textarea name="text" rows="8" cols="80"></textarea>\
        <input type="submit" value="add comment"></form>
        </body></html>
        """
    }

    static func replyFormPage(parentID: Int, hmac: String = "d4e5f6", prefilled: String = "") -> String {
        """
        <html><body><title>Add Comment</title>
        <form action="comment" method="post">\
        <input type="hidden" name="parent" value="\(parentID)">\
        <input type="hidden" name="goto" value="item?id=\(storyID)#\(parentID)">\
        <input type="hidden" name="hmac" value="\(hmac)">\
        <textarea name="text" rows="8" cols="80">\(prefilled)</textarea>\
        <input type="submit" value="add comment"></form>
        </body></html>
        """
    }

    static func itemPage(rows: [String]) -> String {
        """
        <html><body>\(storyTable)<table border="0" class="comment-tree">\(rows.joined())</table></body></html>
        """
    }

    static var itemURL: URL {
        URL(string: "https://news.ycombinator.com/item?id=\(storyID)")!
    }

    static var replyURL: URL {
        URL(string: "https://news.ycombinator.com/reply?id=\(existingCommentID)&goto=item%3Fid%3D\(storyID)%23\(existingCommentID)")!
    }

    static var commentURL: URL {
        URL(string: "https://news.ycombinator.com/comment")!
    }

    static var acceptedPage: CommentNetworkMock.Stub {
        let html = itemPage(rows: [
            commentRow(
                id: newCommentID,
                author: "alice",
                indent: 0,
                html: "First paragraph.<p>Second paragraph.",
                voteLinksHTML: "<td class=\"votelinks\"><center><a id=\"up_9001\" class=\"nosee\" href=\"vote?id=9001&amp;how=up\">▲</a><a id=\"un_9001\" href=\"vote?id=9001&amp;how=un\">unvote</a></center></td>"
            ),
        ])
        return .init(body: html, statusCode: 200, finalURL: itemURL)
    }

    // MARK: - Local validation

    @Test("Empty and invalid targets fail before any network request")
    func localValidation() async {
        await #expect {
            try await repository.submitComment(Self.request(text: "   "), baselineChildIDs: [])
        } throws: { error in
            (error as? CommentSubmissionError) == CommentSubmissionError.empty
        }
        await #expect {
            try await repository.submitComment(Self.request(parentID: 0), baselineChildIDs: [])
        } throws: { error in
            (error as? CommentSubmissionError) == CommentSubmissionError.invalidTarget
        }
        #expect(network.getRequestURLs.isEmpty)
        #expect(network.postBodies.isEmpty)
    }

    @Test("Missing session cookie fails before any network request")
    func missingCookie() async {
        network.hasUserCookie = false
        await #expect {
            try await repository.submitComment(Self.request(), baselineChildIDs: [])
        } throws: { error in
            (error as? CommentSubmissionError) == CommentSubmissionError.unauthenticated
        }
        #expect(network.getRequestURLs.isEmpty)
    }

    // MARK: - Form extraction

    @Test("Top-level submission posts server fields with the draft")
    func topLevelSubmission() async throws {
        network.enqueueGet(Self.topLevelFormPage(parentID: Self.storyID))
        network.enqueuePost(Self.acceptedPage)

        let outcome = try await repository.submitComment(Self.request(), baselineChildIDs: [])

        guard case let .confirmed(submitted) = outcome else {
            Issue.record("Expected confirmed outcome")
            return
        }
        #expect(submitted.id == Self.newCommentID)
        #expect(submitted.parentID == Self.storyID)
        #expect(submitted.author == "alice")
        #expect(submitted.htmlText.contains("First paragraph."))
        #expect(submitted.htmlText.contains("Second paragraph."))
        #expect(submitted.upvoted)
        #expect(submitted.voteLinks?.upvote?.absoluteString == "vote?id=9001&how=up")
        #expect(submitted.voteLinks?.unvote?.absoluteString == "vote?id=9001&how=un")

        #expect(network.postURLs == [Self.commentURL])
        let body = try #require(network.postBodies.first)
        #expect(body.contains("parent=100"))
        #expect(body.contains("goto=item%3Fid%3D100"))
        #expect(body.contains("hmac=a1b2c3"))
        #expect(body.contains("text=First+paragraph.%0A%0ASecond+paragraph."))
    }

    @Test("Reply submission uses the reply page form")
    func replySubmission() async throws {
        network.enqueueGet(Self.replyFormPage(parentID: Self.existingCommentID))
        let acceptedReply = CommentNetworkMock.Stub(
            body: Self.itemPage(rows: [
                Self.commentRow(id: Self.existingCommentID, author: "bob", indent: 0, html: "parent"),
                Self.commentRow(id: Self.newCommentID, author: "alice", indent: 1, html: "First paragraph.<p>Second paragraph."),
            ]),
            statusCode: 200,
            finalURL: Self.itemURL
        )
        network.enqueuePost(acceptedReply)

        let outcome = try await repository.submitComment(
            Self.request(parentID: Self.existingCommentID),
            baselineChildIDs: []
        )

        #expect(network.getRequestURLs == [Self.replyURL])
        guard case .confirmed = outcome else {
            Issue.record("Expected confirmed outcome")
            return
        }
        let body = try #require(network.postBodies.first)
        #expect(body.contains("parent=9000"))
        #expect(body.contains("hmac=d4e5f6"))
    }

    @Test("Forms with the wrong parent, missing hmac, or bad origin are unavailable")
    func invalidForms() async {
        network.enqueueGet(Self.topLevelFormPage(parentID: 999))
        await #expect {
            try await repository.submitComment(Self.request(), baselineChildIDs: [])
        } throws: { error in
            (error as? CommentSubmissionError) == CommentSubmissionError.commentingUnavailable
        }

        network.reset()
        var noHMAC = Self.topLevelFormPage(parentID: Self.storyID)
        noHMAC = noHMAC.replacingOccurrences(of: "<input type=\"hidden\" name=\"hmac\" value=\"a1b2c3\">", with: "")
        network.enqueueGet(noHMAC)
        await #expect {
            try await repository.submitComment(Self.request(), baselineChildIDs: [])
        } throws: { error in
            (error as? CommentSubmissionError) == CommentSubmissionError.commentingUnavailable
        }

        network.reset()
        let crossOrigin = Self.topLevelFormPage(parentID: Self.storyID)
            .replacingOccurrences(of: "action=\"comment\"", with: "action=\"http://evil.example/comment\"")
        network.enqueueGet(crossOrigin)
        await #expect {
            try await repository.submitComment(Self.request(), baselineChildIDs: [])
        } throws: { error in
            (error as? CommentSubmissionError) == CommentSubmissionError.commentingUnavailable
        }
    }

    @Test("Authenticated pages without a comment form are unavailable")
    func noFormOnPage() async {
        network.enqueueGet("<html><body>\(Self.storyTable)</body></html>")
        await #expect {
            try await repository.submitComment(Self.request(), baselineChildIDs: [])
        } throws: { error in
            (error as? CommentSubmissionError) == CommentSubmissionError.commentingUnavailable
        }
    }

    // MARK: - Session state

    @Test("Login pages during form fetch are unauthenticated")
    func loginPageIsUnauthenticated() async {
        network.enqueueGet("<html><body><form action=\"/login\"><input name=\"acct\"></form></body></html>")
        await #expect {
            try await repository.submitComment(Self.request(), baselineChildIDs: [])
        } throws: { error in
            (error as? CommentSubmissionError) == CommentSubmissionError.unauthenticated
        }
    }

    @Test("Unauthenticated POST responses throw unauthenticated")
    func unauthenticatedPost() async {
        network.enqueueGet(Self.topLevelFormPage(parentID: Self.storyID))
        network.enqueuePost(.init(
            body: "You have to be logged in to comment. <form action=\"/login\"><input name=\"acct\"></form>",
            statusCode: 200,
            finalURL: Self.commentURL
        ))
        await #expect {
            try await repository.submitComment(Self.request(), baselineChildIDs: [])
        } throws: { error in
            (error as? CommentSubmissionError) == CommentSubmissionError.unauthenticated
        }
    }

    // MARK: - Confirmation

    @Test("commconfirm re-submits the corrected form exactly once")
    func confirmationRound() async throws {
        network.enqueueGet(Self.topLevelFormPage(parentID: Self.storyID))
        let confirmPage = CommentNetworkMock.Stub(
            body: Self.topLevelFormPage(parentID: Self.storyID, hmac: "corrected"),
            statusCode: 200,
            finalURL: URL(string: "https://news.ycombinator.com/x?fnid=zzz&fnop=commconfirm")!
        )
        network.enqueuePost(confirmPage)
        network.enqueuePost(Self.acceptedPage)

        let outcome = try await repository.submitComment(Self.request(), baselineChildIDs: [])

        #expect(network.postBodies.count == 2)
        #expect(network.postBodies.last?.contains("hmac=corrected") == true)
        guard case .confirmed = outcome else {
            Issue.record("Expected confirmed outcome after confirmation")
            return
        }
    }

    @Test("Repeated commconfirm is malformed")
    func repeatedConfirmationIsMalformed() async {
        network.enqueueGet(Self.topLevelFormPage(parentID: Self.storyID))
        let confirmPage = CommentNetworkMock.Stub(
            body: Self.topLevelFormPage(parentID: Self.storyID, hmac: "corrected"),
            statusCode: 200,
            finalURL: URL(string: "https://news.ycombinator.com/x?fnid=zzz&fnop=commconfirm")!
        )
        network.enqueuePost(confirmPage)
        network.enqueuePost(confirmPage)

        await #expect {
            try await repository.submitComment(Self.request(), baselineChildIDs: [])
        } throws: { error in
            (error as? CommentSubmissionError) == CommentSubmissionError.malformedResponse
        }
    }

    // MARK: - Rejection classification

    @Test("Server message pages classify as definite rejections with safe text")
    func messagePageRejections() async {
        network.enqueueGet(Self.topLevelFormPage(parentID: Self.storyID))
        network.enqueuePost(.init(
            body: "You're posting too fast. Please slow down. Thanks.",
            statusCode: 200,
            finalURL: URL(string: "https://news.ycombinator.com/x?fnid=zzz&fnop=toofast")!
        ))
        await #expect {
            try await repository.submitComment(Self.request(), baselineChildIDs: [])
        } throws: { error in
            (error as? CommentSubmissionError) == CommentSubmissionError.rejected(message: "You're posting too fast. Please slow down.")
        }
    }

    @Test("Empty-text server rejections stay definite")
    func emptyTextServerRejection() async {
        network.enqueueGet(Self.topLevelFormPage(parentID: Self.storyID))
        network.enqueuePost(.init(
            body: "Please try again.",
            statusCode: 200,
            finalURL: URL(string: "https://news.ycombinator.com/x?fnid=zzz&fnop=comment-empty")!
        ))
        await #expect {
            try await repository.submitComment(Self.request(), baselineChildIDs: [])
        } throws: { error in
            (error as? CommentSubmissionError) == CommentSubmissionError.rejected(message: "Please try again.")
        }
    }

    // MARK: - Resolution and reconciliation

    @Test("Transport failure with successful reconciliation confirms")
    func transportFailureReconciles() async throws {
        network.enqueueGet(Self.topLevelFormPage(parentID: Self.storyID))
        network.postError = URLError(.timedOut)
        // First reconciliation item-page fetch finds the comment.
        network.enqueueGet(Self.acceptedPage)

        let outcome = try await repository.submitComment(Self.request(), baselineChildIDs: [])

        guard case let .confirmed(submitted) = outcome else {
            Issue.record("Expected reconciliation to confirm the comment")
            return
        }
        #expect(submitted.id == Self.newCommentID)
        #expect(network.postBodies.count == 1, "Reconciliation must never re-POST")
    }

    @Test("Unresolvable transport failure returns unconfirmed evidence")
    func transportFailureUnconfirmed() async throws {
        network.enqueueGet(Self.topLevelFormPage(parentID: Self.storyID))
        network.postError = URLError(.timedOut)
        // Item pages never contain the comment; threads page has no match.
        network.enqueueGet(Self.itemPage(rows: []))
        network.enqueueGet(Self.itemPage(rows: []))
        network.enqueueGet(Self.itemPage(rows: []))
        network.enqueueGet("<html><body>empty threads</body></html>")

        let outcome = try await repository.submitComment(Self.request(), baselineChildIDs: [])

        guard case let .unconfirmed(attempt) = outcome else {
            Issue.record("Expected unconfirmed outcome")
            return
        }
        #expect(attempt.request.parentID == Self.storyID)
        #expect(attempt.baselineChildIDs.isEmpty)
        #expect(network.postBodies.count == 1)
    }

    @Test("Item-page diff ignores unrelated new children and matches by text")
    func baselineDisambiguation() async throws {
        let baselineRows = [
            Self.commentRow(id: 8_000, author: "alice", indent: 0, html: "older"),
        ]
        network.enqueueGet(Self.itemPage(rows: baselineRows + [
            Self.commentRow(id: 8_001, author: "bob", indent: 0, html: "unrelated"),
            Self.commentRow(id: Self.newCommentID, author: "alice", indent: 0, html: "First paragraph.<p>Second paragraph."),
            Self.commentRow(id: 9_002, author: "alice", indent: 0, html: "different text entirely"),
        ]))

        let submitted = try await repository.reconcileComment(CommentSubmissionAttempt(
            request: Self.request(),
            baselineChildIDs: [8_000],
            startedAt: Date()
        ))

        #expect(submitted?.id == Self.newCommentID)
    }

    @Test("Threads page fallback hydrates through the item page")
    func threadsFallback() async throws {
        // Item-page polling misses the comment...
        network.enqueueGet(Self.itemPage(rows: []))
        network.enqueueGet(Self.itemPage(rows: []))
        network.enqueueGet(Self.itemPage(rows: []))
        // ...threads page lists it under the story...
        let threads = """
        <html><body><table><tr class="athing" id="\(Self.newCommentID)"><td>on: \
        <a href="item?id=\(Self.storyID)">Example story</a></td></tr></table></body></html>
        """
        network.enqueueGet(threads)
        // ...and the hydrating item-page fetch now contains it.
        network.enqueueGet(Self.acceptedPage)

        let submitted = try await repository.reconcileComment(CommentSubmissionAttempt(
            request: Self.request(),
            baselineChildIDs: [],
            startedAt: Date()
        ))

        #expect(submitted?.id == Self.newCommentID)
        #expect(submitted?.htmlText.contains("Second paragraph.") == true)
    }

    @Test("Ambiguous duplicate candidates do not resolve")
    func ambiguousCandidates() async throws {
        network.enqueueGet(Self.itemPage(rows: [
            Self.commentRow(id: Self.newCommentID, author: "alice", indent: 0, html: "First paragraph.<p>Second paragraph."),
            Self.commentRow(id: 9_002, author: "alice", indent: 0, html: "First paragraph.<p>Second paragraph."),
        ]))
        network.enqueueGet(Self.itemPage(rows: []))
        network.enqueueGet(Self.itemPage(rows: []))
        network.enqueueGet(Self.itemPage(rows: []))
        network.enqueueGet("<html><body>empty threads</body></html>")

        let submitted = try await repository.reconcileComment(CommentSubmissionAttempt(
            request: Self.request(),
            baselineChildIDs: [],
            startedAt: Date()
        ))

        #expect(submitted == nil, "Two identical candidates must stay unresolved")
    }
}

// MARK: - Text normalisation

@Suite("Comment text normalisation")
struct CommentTextNormalizerTests {
    @Test("Paragraph markup and entities normalise to submitted plain text")
    func normalisationMatches() {
        let submitted = "First paragraph.\n\nSecond — café"
        let serverHTML = "First paragraph.<p>Second — caf&#233;"

        #expect(
            CommentTextNormalizer.normalizeServerHTML(serverHTML)
                == CommentTextNormalizer.normalizeSubmitted(submitted)
        )
    }

    @Test("Insignificant whitespace differences do not block matching")
    func whitespaceTolerance() {
        #expect(
            CommentTextNormalizer.normalizeServerHTML("<p>  line one  <p>line two")
                == CommentTextNormalizer.normalizeSubmitted("line one\n\nline two")
        )
    }

    @Test("Normalisation does not lowercase content")
    func casePreserved() {
        #expect(CommentTextNormalizer.normalizeSubmitted("UPPER") == "UPPER")
    }
}

// MARK: - Network mock

final class CommentNetworkMock: NetworkManagerProtocol, @unchecked Sendable {
    struct Stub {
        let body: String
        let statusCode: Int
        let finalURL: URL

        init(body: String, statusCode: Int = 200, finalURL: URL) {
            self.body = body
            self.statusCode = statusCode
            self.finalURL = finalURL
        }
    }

    private var getResponses: [Stub] = []
    private var postResponses: [Stub] = []
    private var getRequestURLLog: [URL] = []
    private var postURLLog: [URL] = []
    var postBodies: [String] = []
    var postError: Error?
    var hasUserCookie = true

    var getRequestURLs: [URL] { getRequestURLLog }
    var postURLs: [URL] { postURLLog }

    func enqueueGet(_ body: String, statusCode: Int = 200, finalURL: URL? = nil) {
        getResponses.append(Stub(body: body, statusCode: statusCode, finalURL: finalURL ?? itemFallbackURL))
    }

    func enqueueGet(_ stub: Stub) {
        getResponses.append(stub)
    }

    func enqueuePost(_ stub: Stub) {
        postResponses.append(stub)
    }

    func reset() {
        getResponses = []
        postResponses = []
        getRequestURLLog = []
        postURLLog = []
        postBodies = []
        postError = nil
    }

    private let itemFallbackURL = URL(string: "https://news.ycombinator.com/item?id=100")!

    func getResponse(url: URL) async throws -> NetworkResponse {
        getRequestURLLog.append(url)
        guard !getResponses.isEmpty else {
            return NetworkResponse(body: "", statusCode: 200, finalURL: url)
        }
        let stub = getResponses.removeFirst()
        return NetworkResponse(body: stub.body, statusCode: stub.statusCode, finalURL: stub.finalURL)
    }

    func postResponse(url: URL, body: String) async throws -> NetworkResponse {
        postURLLog.append(url)
        postBodies.append(body)
        if let postError { throw postError }
        guard !postResponses.isEmpty else {
            return NetworkResponse(body: "", statusCode: 200, finalURL: url)
        }
        let stub = postResponses.removeFirst()
        return NetworkResponse(body: stub.body, statusCode: stub.statusCode, finalURL: stub.finalURL)
    }

    func get(url: URL) async throws -> String {
        try await getResponse(url: url).body
    }

    func post(url: URL, body: String) async throws -> String {
        try await postResponse(url: url, body: body).body
    }

    func clearCookies() {
        hasUserCookie = false
    }

    func containsCookie(for _: URL) -> Bool {
        hasUserCookie
    }

    func containsCookie(named name: String, for _: URL) -> Bool {
        name == "user" && hasUserCookie
    }
}
