//
//  HackersKit+Post.swift
//  Hackers
//
//  Created by Weiran Zhang on 25/05/2020.
//  Copyright © 2020 Weiran Zhang. All rights reserved.
//

import Foundation
import SwiftSoup

extension HackersKit {
    func getPost(id: Int, includeAllComments: Bool = false) async throws -> Post {
        let html = try await fetchPostHtml(id: id, recursive: includeAllComments)
        let document = try SwiftSoup.parse(html)
        let post = try HtmlParser.post(from: document.select(".fatitem"), type: .news)
        let comments = try self.comments(from: html)
        post.comments = comments
        return post
    }

    private func comments(from html: String) throws -> [Comment] {
        let commentElements = try HtmlParser.commentElements(from: html)
        var comments = commentElements.compactMap { element in
            try? HtmlParser.comment(from: element)
        }

        // get the post text for AskHN
        if let postComment = try? HtmlParser.postComment(from: html) {
            comments.insert(postComment, at: 0)
        }

        return comments
    }

    /// Optionally recursively fetch post comments over pages
    private func fetchPostHtml(
        id: Int,
        page: Int = 1,
        recursive: Bool = true,
        workingHtml: String = ""
    ) async throws -> String {
        let url = URLs.post(id: id, page: page)

        let html = try await fetchHtml(url: url)
        let document = try SwiftSoup.parse(html)
        let moreLinkExists = try !document.select("a.morelink").isEmpty()

        if moreLinkExists && recursive {
            return try await fetchPostHtml(id: id, page: page + 1, recursive: recursive, workingHtml: html)
        } else {
            return workingHtml + html
        }
    }

    func upvote(post: Post) async throws {
        guard
            let upvoteURL = post.voteLinks?.upvote,
            let realURL = URLs.fullURL(from: upvoteURL.absoluteString)
        else {
            throw HackersKitError.scraperError
        }
        _ = try await networkManager.get(url: realURL)
    }

    func unvote(post: Post) async throws {
        guard
            let unvoteURL = post.voteLinks?.unvote,
            let realURL = URLs.fullURL(from: unvoteURL.absoluteString)
        else {
            throw HackersKitError.scraperError
        }
        _ = try await networkManager.get(url: realURL)
    }
}
