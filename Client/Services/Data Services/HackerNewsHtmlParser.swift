//
//  HackerNewsHtmlParser.swift
//  Hackers
//
//  Created by Weiran Zhang on 02/06/2020.
//  Copyright © 2020 Weiran Zhang. All rights reserved.
//

import Foundation
import SwiftSoup

enum HackerNewsHtmlParser {
    public static func posts(from tableElement: Element, type: HackerNewsPostType) throws -> [HackerNewsPost] {
        if tableElement.hasClass("fatitem") {
            // single post
            let postElements = try tableElement.select("tr")
            let post = try self.post(from: postElements, type: type)
            post.text = self.postText(from: tableElement)
            return [post]
        } else if tableElement.hasClass("itemlist") {
            // post list
            let titleElements = try tableElement.select("tr.athing")
            let posts = try titleElements.compactMap { titleElement -> HackerNewsPost? in
                guard let metadataElement = try titleElement.nextElementSibling() else {
                    return nil
                }
                let postElements = Elements([titleElement, metadataElement])
                return try self.post(from: postElements, type: type)
            }
            return posts
        }
        throw Exception.Error(type: .SelectorParseException, Message: "Couldn't find post elements")
    }

    public static func post(from elements: Elements, type: HackerNewsPostType) throws -> HackerNewsPost {
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

    public static func postsTableElement(from html: String) throws -> Element {
        let document = try SwiftSoup.parse(html)

        guard let parentTable = try document
            .select("table.itemlist, table.fatitem")
            .first() else {
                throw Exception.Error(type: .SelectorParseException, Message: "Couldn't find post element")
        }

        return parentTable
    }

    public static func commentsCount(from metadataElement: Element) throws -> Int {
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

    public static func score(from metadataElement: Element) throws -> Int {
        let scoreString = try metadataElement.select(".score").text()
        guard
            let scoreNumberString = scoreString.components(separatedBy: " ").first,
            let score = Int(String(scoreNumberString)) else {
                return 0
        }
        return score
    }

    public static func commentElements(from html: String) throws -> Elements {
        let document = try SwiftSoup.parse(html)
        return try document.select(".comtr")
    }

    public static func comment(from element: Element) throws -> HackerNewsComment {
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

    public static func postTextComment(from elements: Elements, with post: HackerNewsPost) throws -> HackerNewsComment {
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

    /// Returns any text content in the post, or otherwise nil
    public static func postText(from element: Element) -> String? {
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
                rowElement = rowElements[rowElements.count - 3]
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
}
