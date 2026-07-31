//
//  PostRepository+Parsing.swift
//  Data
//
//  Split parsing helpers from PostRepository to reduce file length
//

import Domain
import Foundation
import os
import SwiftSoup

private enum PostParsingLog {
    static let logger = Logger(
        subsystem: "com.weiranzhang.Hackers",
        category: "PostRepository.Parsing"
    )
}

extension PostRepository {
    private enum ParseConstants {
        static let commentIndentWidth = 40
    }

    // MARK: - CommentUseCase

    public func getComments(for post: Post) async throws -> [Domain.Comment] {
        let html = try await fetchPostHtml(id: post.id)
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
            return titleElements.compactMap { titleElement -> Post? in
                do {
                    guard let metadataElement = try titleElement.nextElementSibling() else {
                        throw HackersKitError.scraperError
                    }
                    let postElements = Elements([titleElement, metadataElement])
                    return try self.post(from: postElements, type: type)
                } catch {
                    let id = (try? titleElement.attr("id")) ?? "unknown"
                    let errorDescription = String(describing: error)
                    PostParsingLog.logger.error(
                        "Post \(id, privacy: .public) skipped: \(errorDescription, privacy: .private)"
                    )
                    return nil
                }
            }
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
        let scoreInt = leadingInt(from: try scoreElement.first()?.text())

        let ageElement = try metadataElement.select("span.age")
        let age = try ageElement.first()?.attr("title") ?? ""

        let byElement = try metadataElement.select("a.hnuser")
        let by = try byElement.first()?.text() ?? ""

        let linkElements = try metadataElement.select("a")
        let commentLinkElement = linkElements.first { element in
            let text = try? element.text()
            return text?.contains("comment") == true
        }

        let commentLinkText = try commentLinkElement?.text()
        let commentsCount = leadingInt(from: commentLinkText)

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
        return try comments(from: document)
    }

    func comments(from document: Document) throws -> [Domain.Comment] {
        let commentElements = try document.select(".comtr")

        // Multi-page comment HTML is concatenated before parsing, and HN's page boundary can
        // overlap (a comment appearing on two adjacent pages). De-dup by id, keeping the
        // first occurrence so order and content stay stable.
        var seen = Set<Int>()
        return commentElements.compactMap { element in
            do {
                let comment = try parseComment(from: element)
                guard seen.insert(comment.id).inserted else { return nil }
                return comment
            } catch {
                let id = (try? element.attr("id")) ?? "unknown"
                let errorDescription = String(describing: error)
                PostParsingLog.logger.error(
                    "Comment \(id, privacy: .public) skipped: \(errorDescription, privacy: .private)"
                )
                return nil
            }
        }
    }

    func parseComment(from element: Element) throws -> Domain.Comment {
        let parsedComment = try parsedCommentContent(from: element)
        guard !parsedComment.text.isEmpty else {
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

        let parsedText = CommentHTMLParser.parseHTMLText(parsedComment.text)

        return Domain.Comment(
            id: id,
            age: age,
            text: parsedComment.text,
            by: user,
            isFlagged: parsedComment.isFlagged,
            level: level,
            upvoted: upvoted,
            voteLinks: VoteLinks(upvote: voteLinksResult.upvote, unvote: voteLinksResult.unvote),
            visibility: parsedComment.isFlagged ? .compact : .visible,
            parsedText: parsedText,
        )
    }

    func parsedCommentContent(from element: Element) throws -> (text: String, isFlagged: Bool) {
        let text = try commentText(from: element.select(".commtext"))
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if !text.isEmpty {
            return (text, false)
        }

        let placeholder = try element.select(".comment").text()
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard placeholder == "[flagged]" else {
            throw HackersKitError.scraperError
        }
        return (placeholder, true)
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

// MARK: - Number Parsing

extension PostRepository {
    /// Parses the leading integer from HN metadata text such as score or comment counts.
    ///
    /// Hacker News renders counts with a trailing noun (`"10 points"`, `"1 point"`,
    /// `"5 comments"`, `"Discuss"` when there are none) and uses U+00A0 (no-break space)
    /// as a thousands separator for larger numbers (`"1\u{00A0}234\u{00A0}points"`).
    /// SwiftSoup's `text()` may collapse that into an ordinary space. Naive `Int(text)`
    /// parsing therefore fails on the singular form and on space/NBSP-separated values,
    /// silently yielding 0. This helper extracts the leading digit run — collapsing
    /// whitespace separators that sit between digits — and falls back to 0 when no digits
    /// are present.
    func leadingInt(from text: String?) -> Int {
        guard let text else { return 0 }
        let separators: Set<Unicode.Scalar> = [" ", "\u{00A0}", "\u{202F}", "\u{2009}"]
        var digits = ""
        var sawDigit = false
        for scalar in text.unicodeScalars {
            if CharacterSet.decimalDigits.contains(scalar) {
                digits.append(Character(scalar))
                sawDigit = true
            } else if sawDigit {
                // HN inserts NBSP (sometimes collapsed to a space) between digit groups as
                // a thousands separator; keep collecting only while inside the number.
                if separators.contains(scalar) { continue }
                break
            }
        }
        return sawDigit ? (Int(digits) ?? 0) : 0
    }
}
