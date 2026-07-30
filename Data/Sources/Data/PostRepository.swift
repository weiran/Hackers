//
//  PostRepository.swift
//  Data
//
//  Copyright © 2025 Weiran Zhang. All rights reserved.
//

import Domain
import Foundation
import Networking
import SwiftSoup

public final class PostRepository: PostUseCase, VoteUseCase, CommentUseCase, Sendable {
    let networkManager: NetworkManagerProtocol
    let urlBase = "https://news.ycombinator.com"

    public init(networkManager: NetworkManagerProtocol) {
        self.networkManager = networkManager
    }

    // MARK: - PostUseCase

    public func getPosts(type: PostType, page: Int, nextId: Int?) async throws -> [Post] {
        let html = try await fetchPostsHtml(type: type, page: page, nextId: nextId ?? 0)
        let tableElement = try postsTableElement(from: html)
        return try posts(from: tableElement, type: type)
    }

    public func getPost(id: Int) async throws -> Post {
        try await loadPostResolvingCommentIfNeeded(id: id)
    }
}

private extension PostRepository {
    /// Upper bound on how many parent hops are allowed while resolving a comment permalink
    /// back to its story. A valid HN permalink is at most a few hops from its story; this
    /// guard prevents a transient or malformed response chain from recursing without limit.
    private static let maxParentResolutionDepth = 5

    func loadPostResolvingCommentIfNeeded(id: Int) async throws -> Post {
        try await loadPostResolvingCommentIfNeeded(id: id, depth: 0)
    }

    func loadPostResolvingCommentIfNeeded(id: Int, depth: Int) async throws -> Post {
        guard depth <= Self.maxParentResolutionDepth else {
            throw HackersKitError.scraperError
        }

        let html = try await fetchPostHtml(id: id)
        let document = try SwiftSoup.parse(html)

        if let fatitemTable = try document.select("table.fatitem").first(),
           hasValidPostTitle(in: fatitemTable) {
            return try makePost(from: fatitemTable, document: document)
        }

        if let parentID = try parentPostID(from: document), parentID != id {
            return try await loadPostResolvingCommentIfNeeded(id: parentID, depth: depth + 1)
        }

        throw HackersKitError.scraperError
    }

    func hasValidPostTitle(in element: Element) -> Bool {
        (try? element.select("span.titleline > a").first()) != nil
    }

    func makePost(from fatitemTable: Element, document: Document) throws -> Post {
        let posts = try posts(from: fatitemTable, type: .news)
        guard var post = posts.first else {
            throw HackersKitError.scraperError
        }

        var comments = try comments(from: document)

        if let topTextHTML = try topTextHTML(from: fatitemTable) {
            post.text = topTextHTML
            let topTextComment = makeTopTextComment(for: post, html: topTextHTML, in: fatitemTable)
            comments.insert(topTextComment, at: 0)
        }

        post.comments = comments
        return post
    }

    func topTextHTML(from fatitemTable: Element) throws -> String? {
        guard let topTextElement = try fatitemTable.select("div.toptext").first() else {
            return nil
        }

        let html = try topTextElement.html().trimmingCharacters(in: .whitespacesAndNewlines)
        return html.isEmpty ? nil : html
    }

    func makeTopTextComment(for post: Post, html: String, in fatitemTable: Element) -> Domain.Comment {
        let parsedText = CommentHTMLParser.parseHTMLText(html)
        let ageText = (try? fatitemTable.select("span.age").first()?.text())?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            ?? post.age
        return Domain.Comment(
            id: -post.id,
            age: ageText,
            text: html,
            by: post.by,
            level: 0,
            upvoted: false,
            voteLinks: nil,
            visibility: .visible,
            parsedText: parsedText,
        )
    }

    func parentPostID(from document: Document) throws -> Int? {
        if let onStoryLink = try document.select("span.onstory a[href^=item?id=]").first() {
            return try parentID(from: onStoryLink)
        }

        if let parentLink = try document.select("span.navs a[href^=item?id=]").first() {
            return try parentID(from: parentLink)
        }

        return nil
    }

    /// Extracts the `id` query item from an HN parent/on-story link as a positive integer.
    /// Uses `URLComponents` so extra query parameters (e.g. `item?id=123&foo=bar`) do not
    /// corrupt the parsed id, which the previous `components(separatedBy: "=").last`
    /// approach mishandled.
    private func parentID(from element: Element) throws -> Int? {
        let href = try element.attr("href")
        guard
            let url = URL(string: href),
            let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
            let idValue = components.queryItems?.first(where: { $0.name == "id" })?.value,
            let id = Int(idValue), id > 0
        else {
            return nil
        }
        return id
    }
}
