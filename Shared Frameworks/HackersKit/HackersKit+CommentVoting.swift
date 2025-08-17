//
//  HackersKit+CommentVoting.swift
//  Hackers
//
//  Created by Weiran Zhang on 25/05/2020.
//  Copyright © 2020 Weiran Zhang. All rights reserved.
//

import Foundation

extension HackersKit {
    func upvote(comment: Comment, for post: Post) async throws {
        guard
            let upvoteURL = comment.voteLinks?.upvote,
            let realURL = URLs.fullURL(from: upvoteURL.absoluteString)
        else {
            throw HackersKitError.scraperError
        }
        _ = try await networkManager.get(url: realURL)
    }

    func unvote(comment: Comment, for post: Post) async throws {
        guard
            let unvoteURL = comment.voteLinks?.unvote,
            let realURL = URLs.fullURL(from: unvoteURL.absoluteString)
        else {
            throw HackersKitError.scraperError
        }
        _ = try await networkManager.get(url: realURL)
    }

    private func getComment(id: Int, for post: Post) async throws -> Comment {
        let url = URLs.post(id: post.id)
        let html = try await networkManager.get(url: url)
        let commentElements = try HtmlParser.commentElements(from: html)
        let comments = try commentElements.map { try HtmlParser.comment(from: $0) }
        guard let comment = comments.first(where: { $0.id == id }) else {
            throw HackersKitError.scraperError
        }
        return comment
    }
}
