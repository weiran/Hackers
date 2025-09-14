//
//  PostRepository+Voting.swift
//  Data
//
//  Split voting-related methods from PostRepository to reduce file length
//

import Foundation
import Domain
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

    // Unvote functionality removed

    public func upvote(comment: Domain.Comment, for post: Post) async throws {
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

    // Unvote functionality removed

    // MARK: - Vote link extraction

    func voteLinks(
        from titleElement: Element,
        metadata metadataElement: Element? = nil
    ) throws -> VoteLinkInfo {
        let voteLinkElements = try titleElement.select("td.votelinks a")
        var upvoteLink = try voteLinkElements.first { try $0.attr("id").starts(with: "up_") }

        var unvoteLink = try voteLinkElements.first { try $0.attr("id").starts(with: "un_") }
        if unvoteLink == nil {
            unvoteLink = try voteLinkElements.first { try $0.text().lowercased() == "unvote" }
        }

        if unvoteLink == nil, let metadataElement = metadataElement {
            let metadataUnvoteLinks = try metadataElement.select("a")
            unvoteLink = try metadataUnvoteLinks.first { try $0.attr("id").starts(with: "un_") }
            if unvoteLink == nil {
                unvoteLink = try metadataUnvoteLinks.first { try $0.text().lowercased() == "unvote" }
            }
        }

        if upvoteLink == nil {
            let anyLinks = try titleElement.select("a")
            upvoteLink = try anyLinks.first { try $0.attr("id").starts(with: "up_") }
        }
        if unvoteLink == nil {
            let anyLinks = try titleElement.select("a")
            unvoteLink = try anyLinks.first { try $0.attr("id").starts(with: "un_") }
                ?? (try anyLinks.first { try $0.text().lowercased() == "unvote" })
        }

        let upvoteURL = try upvoteLink.map { try URL(string: $0.attr("href")) } ?? nil
        var derivedUnvoteURL = try unvoteLink.map { try URL(string: $0.attr("href")) } ?? nil

        let upvoteHidden: Bool = {
            guard let upElement = upvoteLink else { return false }
            return (try? upElement.hasClass("nosee")) ?? false
        }()

        if derivedUnvoteURL == nil, upvoteHidden, let upvoteURL = upvoteURL {
            let unvoteURLString = upvoteURL.absoluteString.replacingOccurrences(of: "how=up", with: "how=un")
            derivedUnvoteURL = URL(string: unvoteURLString)
        }

        let upvoted = (derivedUnvoteURL != nil) || upvoteHidden
        return VoteLinkInfo(upvote: upvoteURL, unvote: derivedUnvoteURL, upvoted: upvoted)
    }
}
