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
    public func getComments(for post: HackerNewsPost) -> Promise<[HackerNewsComment]> {
        firstly {
            fetchCommentsHtml(id: post.id)
        }.map { html in
            try self.commentElements(from: html)
        }.map { (commentElements, postElement) in
            var comments = commentElements.compactMap { element in
                try? self.comment(from: element)
            }
            if let postTextComment = try? self.postTextComment(from: postElement, with: post) {
                // post text for AskHN
                comments.insert(postTextComment, at: 0)
            }
            return comments
        }
    }

    private func commentElements(from data: String) throws -> (Elements, Element) {
        let document = try SwiftSoup.parse(data)
        let commentElements = try document.select(".comtr")
        let postElements = try document.select("table.fatitem td")[6]
        commentElements.add(postElements)
        return (commentElements, postElements)
    }

    private func comment(from element: Element) throws -> HackerNewsComment {
        let text = try commentText(from: element.select(".commtext"))
        let age = try element.select(".age").text()
        let user = try element.select(".hnuser").text()
        guard let id = try Int(element.select(".comtr").attr("id")) else {
            throw Exception.Error(type: .SelectorParseException, Message: "Couldn't parse comment id")
        }
        guard let indentWidth = try Int(element.select(".ind img").attr("width")) else {
            throw Exception.Error(type: .SelectorParseException, Message: "Couldn't parse comment indent width")
        }
        let level = indentWidth / 40
        let upvoteLink = try element.select(".votelinks a").attr("href")
        var upvoted = false
        let voteLinks = try? element.select("a").filter { $0.hasAttr("id") }
        if let voteLinks = voteLinks {
            let hasUnvote = try voteLinks.first { try $0.attr("id").starts(with: "un_") } != nil
            upvoted = hasUnvote
        }

        let comment = HackerNewsComment(id: id, age: age, text: text, by: user, level: level, upvoted: upvoted)
        comment.upvoteLink = upvoteLink
        return comment
    }

    private func postTextComment(from element: Element, with post: HackerNewsPost) throws -> HackerNewsComment {
        guard let text = try postText(from: element) else {
            throw Exception.Error(type: .SelectorParseException, Message: "No post text found")
        }
        return HackerNewsComment(
            id: post.id,
            age: post.age,
            text: text,
            by: post.by,
            level: 0,
            upvoted: post.upvoted
        )
    }

    private func commentText(from elements: Elements) throws -> String {
        // clear reply link from text
        if let replyElement = try? elements.select(".reply") {
            try replyElement.html("")
        }
        return try elements.html()
    }

    private func postText(from element: Element) throws -> String? {
        if let text = try? element.html() {
            return text
        }
        return nil
    }

    private func fetchCommentsHtml(id: Int) -> Promise<String> {
        let url = URL(string: "https://news.ycombinator.com/item?id=\(id)")!
        return fetchHtml(url: url)
    }
}
