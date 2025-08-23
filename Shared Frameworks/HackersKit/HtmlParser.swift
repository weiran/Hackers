//
//  HtmlParser.swift
//  Hackers
//
//  Created by Weiran Zhang on 02/06/2020.
//  Copyright © 2020 Weiran Zhang. All rights reserved.
//

import Foundation
import SwiftSoup

enum HtmlParser {
    static func posts(from tableElement: Element, type: PostType) throws -> [Post] {
        if tableElement.hasClass("fatitem") {
            // single post
            let postElements = try tableElement.select("tr")
            let post = try self.post(from: postElements, type: type)
            post.text = self.postText(from: tableElement)
            return [post]
        } else {
            // post list
            let titleElements = try tableElement.select("tr.athing")
            let posts = try titleElements.compactMap { titleElement -> Post? in
                guard let metadataElement = try titleElement.nextElementSibling() else {
                    throw Exception.Error(type: .SelectorParseException, Message: "Couldn't find post elements")
                }
                let postElements = Elements([titleElement, metadataElement])
                return try? self.post(from: postElements, type: type)
            }
            return posts
        }
    }

    static func voteLinks(from elements: Elements) throws -> (upvote: URL?, unvote: URL?, upvoted: Bool) {
        let voteLinkElements = try elements.select("a")
        let upvoteLink = try voteLinkElements.first { try $0.attr("id").starts(with: "up_") }
        
        // Look for unvote link by ID first, then by text content
        var unvoteLink = try voteLinkElements.first { try $0.attr("id").starts(with: "un_") }
        if unvoteLink == nil {
            unvoteLink = try voteLinkElements.first { try $0.text().lowercased() == "unvote" }
        }

        let upvoteURL = try upvoteLink.map { try URL(string: $0.attr("href")) } ?? nil
        let unvoteURL = try unvoteLink.map { try URL(string: $0.attr("href")) } ?? nil

        // Determine if the item is upvoted based on:
        // 1. Presence of unvote link (by ID or text)
        // 2. Presence of upvote link with "nosee" class
        var upvoted = false
        
        // Check for unvote link (indicates already upvoted)
        let hasUnvote = unvoteLink != nil
        
        // Check for upvote link with "nosee" class (also indicates already upvoted)
        var hasUpvoteWithNosee = false
        if let upvoteElement = upvoteLink {
            let hasNosee = (try? upvoteElement.classNames().contains("nosee")) ?? false
            hasUpvoteWithNosee = hasNosee
        }
        
        upvoted = hasUnvote || hasUpvoteWithNosee

        return (upvote: upvoteURL, unvote: unvoteURL, upvoted: upvoted)
    }

    static func post(from elements: Elements, type: PostType) throws -> Post {
        let rows = try elements.select("tr")
        guard
            let postElement: Element = safeGet(rows, index: 0),
            let metadataElement: Element = safeGet(rows, index: 1) else {
                throw Exception.Error(type: .SelectorParseException, Message: "Coldn't find post elements")
        }
        guard let id = Int(try postElement.attr("id")) else {
            throw Exception.Error(type: .SelectorParseException, Message: "Couldn't parse post ID")
        }
        let urlString = try postElement.select(".titleline").select("a").attr("href")
        guard let titleElement = try postElement.select(".titleline").select("a").first() else {
            throw Exception.Error(type: .SelectorParseException, Message: "Couldn't find title element")
        }
        let title = try titleElement.text()
        guard let url = URL(string: urlString) else {
            throw Exception.Error(type: .SelectorParseException, Message: "Couldn't parse post URL")
        }
        let by = try metadataElement.select(".hnuser").text()
        let score = try self.score(from: metadataElement)
        let age = try metadataElement.select(".age").text()
        let commentsCount = try self.commentsCount(from: metadataElement)

        let voteLinksResult = try self.voteLinks(from: postElement.select(".votelinks"))
        let voteLinks = (upvote: voteLinksResult.upvote, unvote: voteLinksResult.unvote)
        let upvoted = voteLinksResult.upvoted

        let post = Post(
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
        post.voteLinks = voteLinks
        return post
    }

    static func postsTableElement(from html: String) throws -> Element {
        let document = try SwiftSoup.parse(html)

        guard let parentTable = try document
            .select("table#hnmain tr:nth-of-type(3) table, table#hnmain tr:nth-of-type(4) table")
            .first() else {
                throw Exception.Error(type: .SelectorParseException, Message: "Couldn't find post element")
        }

        return parentTable
    }

    static func commentElements(from html: String) throws -> Elements {
        let document = try SwiftSoup.parse(html)
        return try document.select(".comtr")
    }

    static func comment(from element: Element) throws -> Comment {
        let text = try commentText(from: element.select(".commtext"))

        // Skip empty comments (deleted comments, etc.)
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw Exception.Error(type: .SelectorParseException, Message: "Comment text is empty")
        }

        let age = try element.select(".age").text()
        let user = try element.select(".hnuser").text()
        guard let id = try Int(element.select(".comtr").attr("id")) else {
            throw Exception.Error(type: .SelectorParseException, Message: "Couldn't parse comment id")
        }
        guard let indentWidth = try Int(element.select(".ind img").attr("width")) else {
            throw Exception.Error(type: .SelectorParseException, Message: "Couldn't parse comment indent width")
        }
        let level = indentWidth / 40
        let voteLinksResult = try self.voteLinks(from: element.getAllElements())
        let voteLinks = (upvote: voteLinksResult.upvote, unvote: voteLinksResult.unvote)
        let upvoted = voteLinksResult.upvoted

        let comment = Comment(id: id, age: age, text: text, by: user, level: level, upvoted: upvoted)
        comment.voteLinks = voteLinks
        return comment
    }

    private static func commentsCount(from metadataElement: Element) throws -> Int {
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

    private static func score(from metadataElement: Element) throws -> Int {
        let scoreString = try metadataElement.select(".score").text()
        guard
            let scoreNumberString = scoreString.components(separatedBy: .whitespaces).first,
            let score = Int(String(scoreNumberString)) else {
                return 0
        }
        return score
    }

    private static func commentText(from elements: Elements) throws -> String {
        // clear reply link from text
        if let replyElement = try? elements.select(".reply") {
            try replyElement.html("")
        }

        // parse links from href attribute rather than truncated text
        if let links = try? elements.select("a") {
            try links.forEach { link in
                if let url = try? link.attr("href") {
                    try link.html(url)
                }
            }
        }

        return try elements.html()
    }

    static func postComment(from html: String) throws -> Comment? {
        let document = try SwiftSoup.parse(html)
        let toptextElements = try document.select(".toptext")
        let toptextContent = try toptextElements.text().trimmingCharacters(in: .whitespacesAndNewlines)

        guard !toptextContent.isEmpty else {
            return nil
        }

        let postTableElement = try postsTableElement(from: html)
        guard let post = try posts(from: postTableElement, type: .news).first else {
            return nil
        }

        if let text = post.text,
           !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return Comment(
                id: post.id,
                age: post.age,
                text: text,
                by: post.by,
                level: 0,
                upvoted: post.upvoted
            )
        }

        return nil
    }

    /// Returns any text content in the post, or otherwise nil
    private static func postText(from element: Element) -> String? {
        do {
            guard element.hasClass("fatitem") else {
                return nil
            }

            // go from the bottow row up to find the text
            guard let rowElements = try? element.select("tr"),
                var rowElement = rowElements.last() else {
                return nil
            }

            // if it contains a row, then check 2 rows up for text row
            // this happens because the user is logged in
            if try !rowElement.select("form").isEmpty() {
                let newIndex = rowElements.count - 3
                guard let backThreeElement = safeGet(rowElements, index: newIndex) else {
                    return nil
                }
                rowElement = backThreeElement
            }

            // if the row has a subtext column, that means there isn't
            // any post text
            guard try rowElement.select("td.subtext").isEmpty() else {
                return nil
            }

            // if we trim empty chars and the text is still empty then
            // return nil
            guard let text = try? rowElement.html(),
                !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                return nil
            }

            return text
        } catch {
            return nil
        }
    }

    private static func safeGet(_ elements: Elements, index: Int) -> Element? {
        return elements.indices.contains(index) ? elements.get(index) : nil
    }

    static func user(from html: String) throws -> User {
        let document = try SwiftSoup.parse(html)
        guard let karmaElement = try document.select("#karma").first(),
              let karmaString = try? karmaElement.text(),
              let karma = Int(karmaString),
              let usernameElement = try document.select("#me").first(),
              let username = try? usernameElement.text(),
              let createdElement = try document.select("td:contains(created)").first()?.nextElementSibling(),
              let createdString = try? createdElement.text(),
              let createdDate = ISO8601DateFormatter().date(from: createdString) else {
            throw HackersKitError.scraperError
        }

        return User(username: username, karma: karma, joined: createdDate)
    }

    static func string(for query: String, from html: String) throws -> String? {
        let document = try SwiftSoup.parse(html)
        return try document.select(query).val()
    }
}
