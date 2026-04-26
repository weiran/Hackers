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

        let fullURLString = unvoteURL.absoluteString.hasPrefix("http")
            ? unvoteURL.absoluteString
            : urlBase + "/" + unvoteURL.absoluteString
        guard let realURL = URL(string: fullURLString) else { throw HackersKitError.scraperError }

        let response = try await networkManager.get(url: realURL)
        let containsLoginForm =
            response.contains("<form action=\"/login") ||
            response.contains("You have to be logged in")
        if containsLoginForm { throw HackersKitError.unauthenticated }
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

        await MainActor.run { comment.upvoted = true }
    }

    public func unvote(comment: Domain.Comment, for _: Post) async throws {
        guard let voteLinks = comment.voteLinks else { throw HackersKitError.unauthenticated }
        guard let unvoteURL = voteLinks.unvote else {
            throw HackersKitError.scraperError
        }

        let fullURLString = unvoteURL.absoluteString.hasPrefix("http")
            ? unvoteURL.absoluteString
            : urlBase + "/" + unvoteURL.absoluteString
        guard let realURL = URL(string: fullURLString) else { throw HackersKitError.scraperError }

        let response = try await networkManager.get(url: realURL)
        let containsLoginForm = response.contains("<form action=\"/login")
        if containsLoginForm { throw HackersKitError.unauthenticated }

        await MainActor.run { comment.upvoted = false }
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
            return (try? upElement.hasClass("nosee")) ?? false
        }()

        if derivedUnvoteURL == nil, upvoteHidden, let upvoteURL {
            let unvoteURLString = upvoteURL.absoluteString.replacingOccurrences(of: "how=up", with: "how=un")
            derivedUnvoteURL = URL(string: unvoteURLString)
        }

        let upvoted = (derivedUnvoteURL != nil) || upvoteHidden
        return VoteLinkInfo(upvote: upvoteURL, unvote: derivedUnvoteURL, upvoted: upvoted)
    }
}
