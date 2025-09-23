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
    func loadPostResolvingCommentIfNeeded(id: Int) async throws -> Post {
        let html = try await fetchPostHtml(id: id, recursive: true)
        let document = try SwiftSoup.parse(html)

        if let fatitemTable = try document.select("table.fatitem").first(),
           hasValidPostTitle(in: fatitemTable)
        {
            return try makePost(from: fatitemTable, html: html)
        }

        if let parentID = try parentPostID(from: document), parentID != id {
            return try await loadPostResolvingCommentIfNeeded(id: parentID)
        }

        throw HackersKitError.scraperError
    }

    func hasValidPostTitle(in element: Element) -> Bool {
        (try? element.select("span.titleline > a").first()) != nil
    }

    func makePost(from fatitemTable: Element, html: String) throws -> Post {
        let posts = try posts(from: fatitemTable, type: .news)
        guard var post = posts.first else {
            throw HackersKitError.scraperError
        }

        var comments = try comments(from: html)

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
            let href = try onStoryLink.attr("href")
            return Int(href.components(separatedBy: "=").last ?? "")
        }

        if let parentLink = try document.select("span.navs a[href^=item?id=]").first() {
            let href = try parentLink.attr("href")
            return Int(href.components(separatedBy: "=").last ?? "")
        }

        return nil
    }
}
