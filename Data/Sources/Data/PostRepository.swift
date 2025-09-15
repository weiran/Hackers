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
        let html = try await fetchPostHtml(id: id, recursive: true)
        let document = try SwiftSoup.parse(html)

        // Get the fatitem table element
        guard let fatitemTable = try document.select("table.fatitem").first() else {
            throw HackersKitError.scraperError
        }

        // Parse the post from the fatitem table
        let posts = try posts(from: fatitemTable, type: .news)
        guard let post = posts.first else {
            throw HackersKitError.scraperError
        }

        let comments = try comments(from: html)
        var postWithComments = post
        postWithComments.comments = comments
        return postWithComments
    }
}
