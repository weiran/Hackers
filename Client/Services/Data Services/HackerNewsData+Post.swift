//
//  HackerNewsData+Comments.swift
//  Hackers
//
//  Created by Weiran Zhang on 25/05/2020.
//  Copyright © 2020 Weiran Zhang. All rights reserved.
//

import Foundation
import PromiseKit
import SwiftSoup

extension HackerNewsData {
    public func getPost(id: Int, includeAllComments: Bool = false) -> Promise<HackerNewsPost> {
        firstly {
            fetchPostHtml(id: id, recursive: includeAllComments)
        }.map { html in
            let document = try SwiftSoup.parse(html)
            let post = try HackerNewsHtmlParser.post(from: document.select(".fatitem"), type: .news)
            let comments = try self.comments(from: html)
            post.comments = comments
            return post
        }
    }

    // TODO DEPRECATED
    public func getComments(for post: HackerNewsPost) -> Promise<[HackerNewsComment]> {
        firstly {
            fetchPostHtml(id: post.id)
        }.map { html in
            try self.comments(from: html)
        }
    }

    private func comments(from html: String) throws -> [HackerNewsComment] {
        let commentElements = try HackerNewsHtmlParser.commentElements(from: html)
        var comments = commentElements.compactMap { element in
            try? HackerNewsHtmlParser.comment(from: element)
        }

        // get the post text for AskHN
        let postTableElement = try HackerNewsHtmlParser.postsTableElement(from: html)
        if let post = try HackerNewsHtmlParser.posts(from: postTableElement, type: .news).first,
            let text = post.text {
            let postComment = HackerNewsComment(
                id: post.id,
                age: post.age,
                text: text,
                by: post.by,
                level: 0,
                upvoted: post.upvoted
            )
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
    ) -> Promise<String> {
        let url = URL(string: "https://news.ycombinator.com/item?id=\(id)&p=\(page)")!
        return fetchHtml(url: url).then { html -> Promise<String> in
            let document = try SwiftSoup.parse(html)
            let moreLinkExists = try !document.select("a.morelink").isEmpty()
            if moreLinkExists && recursive {
                return self.fetchPostHtml(id: id, page: page + 1, workingHtml: html)
            } else {
                return Promise.value(workingHtml + html)
            }
        }
    }
}
