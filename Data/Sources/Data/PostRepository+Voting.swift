//
//  PostRepository+Voting.swift
//  Data
//
//  Split voting-related methods from PostRepository to reduce file length
//

import Domain
import Foundation
import Networking
import SwiftSoup

extension PostRepository {
    struct VoteLinkInfo {
        let upvote: URL?
        let unvote: URL?
        let upvoted: Bool
    }

    // MARK: - VoteUseCase

    public func upvote(post: Post) async throws {
        guard let voteLinks = post.voteLinks else { throw HackersKitError.unauthenticated }
        guard let upvoteURL = voteLinks.upvote else {
            if voteLinks.unvote == nil { throw HackersKitError.unauthenticated }
            throw HackersKitError.scraperError
        }

        let fullURLString = upvoteURL.absoluteString.hasPrefix("http")
            ? upvoteURL.absoluteString
            : urlBase + "/" + upvoteURL.absoluteString
        guard let realURL = URL(string: fullURLString) else { throw HackersKitError.scraperError }

        let response = try await networkManager.get(url: realURL)
        let containsLoginForm =
            response.contains("<form action=\"/login") ||
            response.contains("You have to be logged in")
        if containsLoginForm { throw HackersKitError.unauthenticated }
    }

    public func unvote(post: Post) async throws {
        guard let voteLinks = post.voteLinks else { throw HackersKitError.unauthenticated }
        guard let unvoteURL = voteLinks.unvote else {
            throw HackersKitError.scraperError
        }

        try await submitUnvote(itemID: post.id, unvoteURL: unvoteURL)
    }

    public func upvote(comment: Domain.Comment, for _: Post) async throws {
        guard let voteLinks = comment.voteLinks else { throw HackersKitError.unauthenticated }
        guard let upvoteURL = voteLinks.upvote else {
            if voteLinks.unvote == nil { throw HackersKitError.unauthenticated }
            throw HackersKitError.scraperError
        }

        let fullURLString = upvoteURL.absoluteString.hasPrefix("http")
            ? upvoteURL.absoluteString
            : urlBase + "/" + upvoteURL.absoluteString
        guard let realURL = URL(string: fullURLString) else { throw HackersKitError.scraperError }

        let response = try await networkManager.get(url: realURL)
        let containsLoginForm = response.contains("<form action=\"/login")
        if containsLoginForm { throw HackersKitError.unauthenticated }
    }

    public func unvote(comment: Domain.Comment, for _: Post) async throws {
        guard let voteLinks = comment.voteLinks else { throw HackersKitError.unauthenticated }
        guard let unvoteURL = voteLinks.unvote else {
            throw HackersKitError.scraperError
        }

        try await submitUnvote(itemID: comment.id, unvoteURL: unvoteURL)
    }

    // MARK: - Unvote verification

    /// Performs an unvote and checks whether Hacker News actually applied it.
    ///
    /// Verified against production HN: an applied vote 302-redirects to the link's
    /// `goto` target, while a refused unvote (nothing to remove, or a vote outside
    /// the unvote window) is silently ignored and returns the very same redirect —
    /// there is no error response to detect. The only truthful signal is the vote
    /// state the response page shows: an item we are still upvoted on keeps its
    /// `un_<id>` link or a hidden (`nosee`) upvote arrow. The `goto` parameter is
    /// therefore rewritten to the item's own page so the redirect response always
    /// carries that state, keeping the whole check to this single request. Bare
    /// error pages served at /vote ("Can't make that vote.") remain immediate
    /// refusals.
    func submitUnvote(itemID: Int, unvoteURL: URL) async throws {
        guard let url = resolvedUnvoteURL(unvoteURL, itemID: itemID) else {
            throw HackersKitError.scraperError
        }

        let response = try await networkManager.getResponse(url: url)
        let body = response.body
        try throwIfLoginRequired(body)

        if isRefusalServedInPlace(response, body: body) {
            throw HackersKitError.voteRejected
        }

        if try voteState(from: body, itemID: itemID) == .upvoted {
            // The page HN returned still shows our vote standing.
            throw HackersKitError.voteRejected
        }
    }

    private enum ItemVoteState {
        case upvoted
        case unupvoted
        case inconclusive
    }

    private func voteState(from html: String, itemID: Int) throws -> ItemVoteState {
        guard let document = try? SwiftSoup.parse(html),
              let upvoteLink = try document.select("a#up_\(itemID)").first()
        else { return .inconclusive }

        let unvoteLink = try document.select("a#un_\(itemID)").first()
        if unvoteLink != nil || upvoteLink.hasClass("nosee") {
            return .upvoted
        }
        return .unupvoted
    }

    /// Some refusals are unmistakable: HN serves bare error pages ("Can't make that
    /// vote.") at the /vote endpoint instead of redirecting to the goto target.
    private func isRefusalServedInPlace(_ response: NetworkResponse, body: String) -> Bool {
        let lowered = body.lowercased()
        guard response.finalURL.path == "/vote" else { return false }
        return lowered.contains("make that vote")
            || lowered.contains("too old to be modified")
            || !lowered.contains("<table")
    }

    private func throwIfLoginRequired(_ body: String) throws {
        let containsLoginForm =
            body.contains("<form action=\"/login") ||
            body.contains("You have to be logged in")
        if containsLoginForm { throw HackersKitError.unauthenticated }
    }

    /// Resolves the unvote link to an absolute URL and rewrites its `goto` target to
    /// the item's own page, so HN's redirect response contains the item's vote state.
    private func resolvedUnvoteURL(_ voteURL: URL, itemID: Int) -> URL? {
        guard var urlString = resolvedVoteURL(voteURL)?.absoluteString else { return nil }

        let itemTarget = "goto=item%3Fid%3D\(itemID)"
        if let range = urlString.range(of: "goto=[^&]*", options: .regularExpression) {
            urlString.replaceSubrange(range, with: itemTarget)
        } else {
            urlString += "&" + itemTarget
        }
        return URL(string: urlString)
    }

    private func resolvedVoteURL(_ voteURL: URL) -> URL? {
        let reference = voteURL.absoluteString
        guard !reference.hasPrefix("http") else { return URL(string: reference) }

        // Leading-slash references would otherwise join into a "//vote" double-slash
        // path; normalize so every resolved vote URL lives directly under /vote.
        var path = Substring(reference)
        while path.first == "/" { path = path.dropFirst() }
        return URL(string: urlBase + "/" + path)
    }

    // MARK: - Vote link extraction

    func voteLinks(
        from titleElement: Element,
        metadata metadataElement: Element? = nil,
    ) throws -> VoteLinkInfo {
        let voteLinkElements = try titleElement.select("td.votelinks a").array()
        let titleLinks = try titleElement.select("a").array()
        let metadataLinks = try metadataElement?.select("a").array() ?? []

        func linkWithIDPrefix(_ prefix: String, in links: [Element]) throws -> Element? {
            for link in links where try link.attr("id").starts(with: prefix) {
                return link
            }
            return nil
        }

        func linkWithExactText(_ text: String, in links: [Element]) throws -> Element? {
            for link in links where try link.text().localizedCaseInsensitiveCompare(text) == .orderedSame {
                return link
            }
            return nil
        }

        let upvoteLink = try linkWithIDPrefix("up_", in: voteLinkElements)
            ?? linkWithIDPrefix("up_", in: titleLinks)

        let unvoteCandidates = voteLinkElements + metadataLinks + titleLinks
        let unvoteLink = try linkWithIDPrefix("un_", in: unvoteCandidates)
            ?? linkWithExactText("unvote", in: unvoteCandidates)

        let upvoteURL = try upvoteLink.map { try URL(string: $0.attr("href")) } ?? nil
        var derivedUnvoteURL = try unvoteLink.map { try URL(string: $0.attr("href")) } ?? nil

        let upvoteHidden: Bool = {
            guard let upElement = upvoteLink else { return false }
            return upElement.hasClass("nosee")
        }()

        if derivedUnvoteURL == nil, upvoteHidden, let upvoteURL {
            let unvoteURLString = upvoteURL.absoluteString.replacingOccurrences(of: "how=up", with: "how=un")
            derivedUnvoteURL = URL(string: unvoteURLString)
        }

        let upvoted = (derivedUnvoteURL != nil) || upvoteHidden
        return VoteLinkInfo(upvote: upvoteURL, unvote: derivedUnvoteURL, upvoted: upvoted)
    }
}
