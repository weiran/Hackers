//
//  PostRepository+Voting.swift
//  Data
//
//  Split voting-related methods from PostRepository to reduce file length
//

import Domain
import Foundation
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

        try await submitUnvote(to: url)
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

        try await submitUnvote(to: url)
    }

    // MARK: - Unvote verification

    /// Performs an unvote and verifies Hacker News actually accepted it.
    ///
    /// An accepted vote redirects to the whence page. A refused one (e.g. an unvote
    /// outside the short window HN allows) is served in place at the /vote endpoint as
    /// a bare error page such as "Can't make that vote." — HTTP 200, so without these
    /// checks it would silently look successful.
    func submitUnvote(to url: URL) async throws {
        let response = try await networkManager.getResponse(url: url)
        let body = response.body
        let containsLoginForm =
            body.contains("<form action=\"/login") ||
            body.contains("You have to be logged in")
        if containsLoginForm { throw HackersKitError.unauthenticated }

        let loweredBody = body.lowercased()
        // HN redirects accepted votes to the whence/goto page, so any response still
        // served at /vote is a refusal — either a known error text like
        // "Can't make that vote." or an unrecognized bare error page.
        guard response.finalURL.path == "/vote" else { return }
        let recognizedRefusal =
            loweredBody.contains("make that vote") ||
            loweredBody.contains("too old to be modified")
        // Unrecognized bare pages are treated as refusals too; only structurally
        // complete pages there would be something unexpected.
        if recognizedRefusal || !loweredBody.contains("<table") {
            throw HackersKitError.voteRejected
        }
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
