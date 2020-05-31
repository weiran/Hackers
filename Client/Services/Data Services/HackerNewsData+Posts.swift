//
//  HackerNewsData+Posts.swift
//  Hackers
//
//  Created by Weiran Zhang on 25/05/2020.
//  Copyright © 2020 Weiran Zhang. All rights reserved.
//

import Foundation
import PromiseKit
import SwiftSoup

extension HackerNewsData {
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

    public func getPost(id: Int) -> Promise<HackerNewsPost> {
        firstly {
            fetchCommentsHtml(id: id, recursive: false)
        }.map { html in
            let document = try SwiftSoup.parse(html)
            return try self.post(from: document.select(".fatitem"), type: .news)
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
        let rows = try elements.select("tr")
        let postElement = rows[0]
        let metadataElement = rows[1]
        guard let id = Int(try postElement.attr("id")) else {
            throw Exception.Error(type: .SelectorParseException, Message: "Couldn't parse post ID")
        }
        let title = try postElement.select(".storylink").text()
        let urlString = try postElement.select(".storylink").attr("href")
        guard let url = URL(string: urlString) else {
            throw Exception.Error(type: .SelectorParseException, Message: "Couldn't parse post URL")
        }
        let by = try metadataElement.select(".hnuser").text()
        let score = try self.score(from: metadataElement)
        let age = try metadataElement.select(".age").text()
        let commentsCount = try self.commentsCount(from: metadataElement)

        var upvoted = false
        let voteLink = try? postElement.select(".votelinks a").first { $0.hasAttr("id") }
        if let voteLink = voteLink {
            let hasUnvote = try voteLink.attr("id").starts(with: "un_")
            let hasUpvote = try voteLink.attr("id").starts(with: "up_")
            let hasNosee = try voteLink.classNames().contains("nosee")

            upvoted = hasUnvote || (hasUpvote && hasNosee)
        }

        return HackerNewsPost(
            id: id,
            url: url,
            title: title,
            age: age,
            commentsCount: commentsCount,
            by: by,
            score: score,
            postType: type,
            upvoted: upvoted
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
