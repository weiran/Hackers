//
//  HackersKit+Post.swift
//  Hackers
//
//  Created by Weiran Zhang on 25/05/2020.
//  Copyright © 2020 Weiran Zhang. All rights reserved.
//

import Foundation
import PromiseKit
import SwiftSoup

extension HackersKit {
    func getPost(id: Int, includeAllComments: Bool = false) -> Promise<Post> {
        firstly {
            fetchPostHtml(id: id, recursive: includeAllComments)
        }.map { html in
            let document = try SwiftSoup.parse(html)
            let post = try HtmlParser.post(from: document.select(".fatitem"), type: .news)
            let comments = try self.comments(from: html)
            post.comments = comments
            return post
        }
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
    ) -> Promise<String> {
        guard let url = hackerNewsURL(id: id, page: page) else {
            return Promise(error: Exception.Error(type: .MalformedURLException, Message: "Internal error"))
        }

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

    private func hackerNewsURL(id: Int, page: Int) -> URL? {
        var components = URLComponents()

        components.scheme = "https"
        components.host = "news.ycombinator.com"
        components.path = "/item"
        components.queryItems = [
            URLQueryItem(name: "id", value: String(id)),
            URLQueryItem(name: "p", value: String(page))
        ]

        return components.url
    }
}
