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
        }.map { (commentElements, postElements) in
            var comments = commentElements.compactMap { element in
                try? self.comment(from: element)
            }
            if let postTextComment = try? self.postTextComment(from: postElements, with: post) {
                // get the post text for AskHN
                comments.insert(postTextComment, at: 0)
            }
            return comments
        }
    }

    private func commentElements(from data: String) throws -> (Elements, Elements) {
        let document = try SwiftSoup.parse(data)
        let commentElements = try document.select(".comtr")
        let postElements = try document.select("table.fatitem td")
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

    private func postTextComment(from elements: Elements, with post: HackerNewsPost) throws -> HackerNewsComment {
        // get last element
        // if form then get 2 further back
        // should be td with no class, no colspan

        guard var element = elements.last else {
            throw Exception.Error(type: .SelectorParseException, Message: "No post text found")
        }

        if element.child(0).tagName() == "form" {
            let elementsCount = elements.count
            element = elements[elementsCount - 3]
        }

        guard
            !element.hasClass("subtext"),
            let text = try postText(from: element) else {
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
        if let text = try? element.html(),
            !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return text
        }
        return nil
    }

    /// Optionally recursively fetch post comments over pages
    internal func fetchCommentsHtml(
        id: Int,
        page: Int = 1,
        recursive: Bool = true,
        workingHtml: String = "") -> Promise<String> {
        let url = URL(string: "https://news.ycombinator.com/item?id=\(id)&p=\(page)")!
        return fetchHtml(url: url).then { html -> Promise<String> in
            let document = try SwiftSoup.parse(html)
            let moreLinkExists = try !document.select("a.morelink").isEmpty()
            if moreLinkExists && recursive {
                return self.fetchCommentsHtml(id: id, page: page + 1, workingHtml: html)
            } else {
                return Promise.value(workingHtml + html)
            }
        }
    }
}
