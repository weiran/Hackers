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
        guard let url = resolvedVoteURL(unvoteURL) else { throw HackersKitError.scraperError }

        let voteResponse = try await networkManager.getResponse(url: url)
        try await confirmUnvoteAccepted(itemID: post.id, voteResponse: voteResponse)
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
        guard let url = resolvedVoteURL(unvoteURL) else { throw HackersKitError.scraperError }

        let voteResponse = try await networkManager.getResponse(url: url)
        try await confirmUnvoteAccepted(itemID: comment.id, voteResponse: voteResponse)
    }

    // MARK: - Unvote verification

    /// Verifies an unvote took effect before letting the caller report success.
    ///
    /// HN's response shape does not reliably reveal refusals: a vote outside its
    /// unvote window can come back looking exactly like an accepted one (HTTP 200,
    /// redirected to whence) while the server keeps the vote. Refusals are therefore
    /// decided from actual page state: an item we are still upvoted on keeps its
    /// `un_<id>` link or a hidden (`nosee`) upvote arrow. The vote response is checked
    /// first — HN usually redirects to a page containing the item — and only when it
    /// doesn't show the item is the item page fetched for ground truth.
    func confirmUnvoteAccepted(itemID: Int, voteResponse: NetworkResponse) async throws {
        let body = voteResponse.body
        try throwIfLoginRequired(body)

        if isRefusalServedInPlace(voteResponse, body: body) {
            throw HackersKitError.voteRejected
        }

        switch try voteState(from: body, itemID: itemID) {
        case .upvoted:
            // The page HN returned still shows our vote standing.
            throw HackersKitError.voteRejected
        case .unupvoted:
            return
        case .inconclusive:
            break
        }

        guard let itemPageURL = hackerNewsURL(id: itemID) else {
            throw HackersKitError.requestFailure
        }
        let itemHTML = try await networkManager.get(url: itemPageURL)
        if try voteState(from: itemHTML, itemID: itemID) == .upvoted {
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

    /// Some refusals are unmistakable without a refetch: HN serves bare error pages
    /// ("Can't make that vote.") at the /vote endpoint instead of redirecting.
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
