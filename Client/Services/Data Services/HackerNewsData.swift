//
//  HackerNewsData.swift
//  Hackers
//
//  Created by Weiran Zhang on 11/05/2020.
//  Copyright © 2020 Weiran Zhang. All rights reserved.
//

import Foundation
import PromiseKit
import SwiftSoup

protocol HackerNewsDataProtocol {

}

enum HackerNewsPostType: String {
    case news
    case ask
    case jobs
    case new
}

class HackerNewsData {
    public static let shared = HackerNewsData()

    let session = URLSession(configuration: .default)

    init() { }
}

extension HackerNewsData { // posts
    public func getPosts(type: HackerNewsPostType, page: Int = 1) -> Promise<[HackerNewsPost]> {
        firstly {
            fetchPostsHtml(type: type, page: page)
        }.map { html in
            try self.postElements(from: html)
        }.map { groupedElements in
            groupedElements.compactMap { elements in
                try? self.post(from: elements, type: type)
            }
        }
    }

    private func postElements(from data: String) throws -> [Elements] {
        let document = try SwiftSoup.parse(data)

        let postElements = try document.select(".athing").compactMap { postElement -> Elements? in
            guard let metadataElement = try postElement.nextElementSibling() else {
                return nil
            }
            return Elements([postElement, metadataElement])
        }

        return postElements
    }

    private func post(from elements: Elements, type: HackerNewsPostType) throws -> HackerNewsPost {
        guard let metadataElement = try elements.select("tr:not(.athing)").first() else {
            throw Exception.Error(type: .SelectorParseException, Message: "Couldn't find metadata element")
        }
        guard let postElement = try elements.select(".athing").first() else {
            throw Exception.Error(type: .SelectorParseException, Message: "Couldn't find post element")
        }
        guard let id = Int(try postElement.attr("id")) else {
            throw Exception.Error(type: .SelectorParseException, Message: "Couldn't parse post ID")
        }
        let title = try postElement.select(".storylink").text()
        let urlString = try postElement.select(".storylink").attr("href")
        guard let url = URL(string: urlString) else {
            throw Exception.Error(type: .SelectorParseException, Message: "Couldn't parse post URL")
        }
        let by = try metadataElement.select("hnuser").text()
        let score = try self.score(from: metadataElement)
        let age = try metadataElement.select("age").text()
        let commentsCount = try self.commentsCount(from: metadataElement)

        return HackerNewsPost(
            id: id,
            url: url,
            title: title,
            age: age,
            commentsCount: commentsCount,
            by: by,
            score: score,
            postType: type // todo parse this
        )
    }

    private func commentsCount(from metadataElement: Element) throws -> Int {
        let linkElements = try metadataElement.select("a")
        let commentLinkElement = try linkElements.first { try $0.text().contains("comment") }
        guard
            let commentLinkText = try commentLinkElement?.text(),
            let commentsCountString = commentLinkText.components(separatedBy: " ").first,
            let commentsCount = Int(String(commentsCountString)) else {
            return 0
        }
        return commentsCount
    }

    private func score(from metadataElement: Element) throws -> Int {
        let scoreString = try metadataElement.select(".score").text()
        guard
            let scoreNumberString = scoreString.components(separatedBy: " ").first,
            let score = Int(String(scoreNumberString)) else {
                return 0
        }
        return score
    }

    private func fetchPostsHtml(type: HackerNewsPostType, page: Int) -> Promise<String> {
        let url = URL(string: "https://news.ycombinator.com/\(type.rawValue)?p=\(page)")!
        return fetchHtml(url: url)
    }
}

extension HackerNewsData { // comments
    public func getComments(postId: Int) -> Promise<[HackerNewsComment]> {
        firstly {
            fetchCommentsHtml(id: postId)
        }.map { html in
            try self.commentElements(from: html)
        }.map { elements in
            elements.compactMap { element in
                try? self.comment(from: element)
            }
        }
    }

    private func commentElements(from data: String) throws -> Elements {
        let document = try SwiftSoup.parse(data)
        return try document.select(".comtr")
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

        let comment = HackerNewsComment(id: id, age: age, text: text, by: user, level: level)
        comment.upvoteLink = upvoteLink
        return comment
    }

    private func commentText(from elements: Elements) throws -> String {
        if let replyElement = try? elements.select(".reply") {
            try replyElement.html("")
        }
        return try elements.html()
    }

    private func fetchCommentsHtml(id: Int) -> Promise<String> {
        let url = URL(string: "https://news.ycombinator.com/item?id=\(id)")!
        return fetchHtml(url: url)
    }
}

extension HackerNewsData { // shared
    private func fetchHtml(url: URL) -> Promise<String> {
        let (promise, seal) = Promise<String>.pending()

        session.dataTask(with: url) { data, _, error in
            if let data = data, let html = String(bytes: data, encoding: .utf8) {
                seal.fulfill(html)
            } else if let error = error {
                seal.reject(error)
            } else {
                seal.reject(HackerNewsError.typeError)
            }
        }.resume()

        return promise
    }
}

enum HackerNewsError: Error {
    case typeError
}

class HackerNewsPost {
    let id: Int
    let url: URL
    let title: String
    let age: String
    let commentsCount: Int
    let by: String
    var score: Int
    let postType: HackerNewsPostType

    // UI properties
    var upvoted = false

    init(
        id: Int,
        url: URL,
        title: String,
        age: String,
        commentsCount: Int,
        by: String,
        score: Int,
        postType: HackerNewsPostType
    ) {
        self.id = id
        self.url = url
        self.title = title
        self.age = age
        self.commentsCount = commentsCount
        self.by = by
        self.score = score
        self.postType = postType
    }
}

class HackerNewsComment {
    let id: Int
    let age: String
    let text: String
    let by: String
    var level: Int
    var upvoteLink: String?

    // UI properties
    var visibility = CommentVisibilityType.visible
    var upvoted = false

    init(
        id: Int,
        age: String,
        text: String,
        by: String,
        level: Int
    ) {
        self.id = id
        self.age = age
        self.text = text
        self.by = by
        self.level = level
    }
}
