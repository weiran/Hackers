//
//  PostRepository+Parsing.swift
//  Data
//
//  Split parsing helpers from PostRepository to reduce file length
//

import Domain
import Foundation
import SwiftSoup

extension PostRepository {
    private enum ParseConstants {
        static let commentIndentWidth = 40
    }

    // MARK: - CommentUseCase

    public func getComments(for post: Post) async throws -> [Domain.Comment] {
        let html = try await fetchPostHtml(id: post.id, recursive: true)
        return try comments(from: html)
    }

    // MARK: - HTML Parsing

    func postsTableElement(from html: String) throws -> Element {
        let document = try SwiftSoup.parse(html)
        guard let tableElement = try document.select("table:has(.athing.submission)").first() else {
            throw HackersKitError.scraperError
        }
        return tableElement
    }

    func posts(from tableElement: Element, type: PostType) throws -> [Post] {
        if tableElement.hasClass("fatitem") {
            let allRows = try tableElement.select("tr")
            guard allRows.size() >= 2 else { throw HackersKitError.scraperError }
            let titleElement = try allRows.get(0)
            let metadataElement = try allRows.get(1)
            let postElements = Elements([titleElement, metadataElement])
            let post = try post(from: postElements, type: type)
            return [post]
        } else {
            let titleElements = try tableElement.select("tr.athing")
            let posts = try titleElements.compactMap { titleElement -> Post? in
                guard let metadataElement = try titleElement.nextElementSibling() else { return nil }
                let postElements = Elements([titleElement, metadataElement])
                return try? self.post(from: postElements, type: type)
            }
            return posts
        }
    }

    func post(from elements: Elements, type: PostType) throws -> Post {
        guard elements.size() >= 2 else { throw HackersKitError.scraperError }

        let titleElement = try elements.get(0)
        let metadataElement = try elements.get(1)

        let id = try Int(titleElement.attr("id")) ?? 0
        guard let titleLink = try titleElement.select("span.titleline > a").first() else {
            throw HackersKitError.scraperError
        }
        let title = try titleLink.text()
        let urlString = try titleLink.attr("href")
        guard let url = URL(string: urlString) ?? URL(string: "https://news.ycombinator.com") else {
            throw HackersKitError.scraperError
        }

        let scoreElement = try metadataElement.select("span.score")
        let score = try scoreElement.first()?.text().replacingOccurrences(of: " points", with: "")
        let scoreInt = Int(score ?? "0") ?? 0

        let ageElement = try metadataElement.select("span.age")
        let age = try ageElement.first()?.attr("title") ?? ""

        let byElement = try metadataElement.select("a.hnuser")
        let by = try byElement.first()?.text() ?? ""

        let linkElements = try metadataElement.select("a")
        let commentLinkElement = linkElements.first { element in
            let text = try? element.text()
            return text?.contains("comment") == true
        }

        let commentsCount: Int = if let commentLinkText = try commentLinkElement?.text(),
                                    let commentsCountString = commentLinkText.components(separatedBy: .whitespaces).first,
                                    let count = Int(String(commentsCountString))
        {
            count
        } else {
            0
        }

        let voteLinks = try voteLinks(from: titleElement, metadata: metadataElement)
        let hasAnyVoteLink = voteLinks.upvote != nil || voteLinks.unvote != nil
        let finalVoteLinks = hasAnyVoteLink ? VoteLinks(upvote: voteLinks.upvote, unvote: voteLinks.unvote) : nil

        return Post(
            id: id,
            url: url,
            title: title,
            age: age,
            commentsCount: commentsCount,
            by: by,
            score: scoreInt,
            postType: type,
            upvoted: voteLinks.upvoted,
            voteLinks: finalVoteLinks,
        )
    }

    func comments(from html: String) throws -> [Domain.Comment] {
        let document = try SwiftSoup.parse(html)
        let commentElements = try document.select(".comtr")

        return commentElements.compactMap { element in
            do {
                return try parseComment(from: element)
            } catch {
                return nil
            }
        }
    }

    func parseComment(from element: Element) throws -> Domain.Comment {
        let text = try commentText(from: element.select(".commtext"))
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw HackersKitError.scraperError
        }

        let age = try element.select(".age").text()
        let user = try element.select(".hnuser").text()
        let idValue = try element.attr("id")
        guard let id = Int(idValue), !idValue.isEmpty else {
            throw HackersKitError.scraperError
        }
        guard let indentWidth = try Int(element.select(".ind img").attr("width")) else {
            throw HackersKitError.scraperError
        }
        let level = indentWidth / ParseConstants.commentIndentWidth
        let voteLinksResult = try voteLinks(from: element)
        let upvoted = voteLinksResult.upvoted

        let parsedText = CommentHTMLParser.parseHTMLText(text)

        return Domain.Comment(
            id: id,
            age: age,
            text: text,
            by: user,
            level: level,
            upvoted: upvoted,
            voteLinks: VoteLinks(upvote: voteLinksResult.upvote, unvote: voteLinksResult.unvote),
            parsedText: parsedText,
        )
    }

    func commentText(from elements: Elements) throws -> String {
        if let replyElement = try? elements.select(".reply") { try replyElement.html("") }
        if let links = try? elements.select("a") {
            try links.forEach { link in
                if let url = try? link.attr("href") { try link.html(url) }
            }
        }
        return try elements.html()
    }
}
