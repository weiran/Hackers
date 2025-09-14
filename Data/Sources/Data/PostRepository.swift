//
//  PostRepository.swift
//  Data
//
//  Copyright © 2025 Weiran Zhang. All rights reserved.
//

import Domain
import Networking
import Foundation
import SwiftSoup

// swiftlint:disable type_body_length

public final class PostRepository: PostUseCase, VoteUseCase, CommentUseCase, Sendable {
    private let networkManager: NetworkManagerProtocol
    private let urlBase = "https://news.ycombinator.com"

    public init(networkManager: NetworkManagerProtocol) {
        self.networkManager = networkManager
    }

    // MARK: - PostUseCase

    public func getPosts(type: PostType, page: Int, nextId: Int?) async throws -> [Post] {
        let html = try await fetchPostsHtml(type: type, page: page, nextId: nextId ?? 0)
        let tableElement = try postsTableElement(from: html)
        return try posts(from: tableElement, type: type)
    }

    public func getPost(id: Int) async throws -> Post {
        let html = try await fetchPostHtml(id: id, recursive: true)
        let document = try SwiftSoup.parse(html)

        // Get the fatitem table element
        guard let fatitemTable = try document.select("table.fatitem").first() else {
            throw HackersKitError.scraperError
        }

        // Parse the post from the fatitem table
        let posts = try self.posts(from: fatitemTable, type: .news)
        guard let post = posts.first else {
            throw HackersKitError.scraperError
        }

        let comments = try self.comments(from: html)
        var postWithComments = post
        postWithComments.comments = comments
        return postWithComments
    }

    // MARK: - VoteUseCase

    public func upvote(post: Post) async throws {
        // Check if the post has no vote links at all (user not authenticated)
        guard let voteLinks = post.voteLinks else {
            throw HackersKitError.unauthenticated
        }
        
        guard let upvoteURL = voteLinks.upvote else {
            // If we have vote links but no upvote URL, could be:
            // 1. User not authenticated (both upvote and unvote URLs are nil)
            // 2. Already upvoted (only unvote link available, shouldn't call upvote)
            
            if voteLinks.unvote == nil {
                // Neither upvote nor unvote URL exists - user not authenticated
                throw HackersKitError.unauthenticated
            } else {
                // Has unvote link but no upvote link - already upvoted, shouldn't upvote again
                throw HackersKitError.scraperError
            }
        }
        
        // Construct the full URL - upvoteURL is relative, so prepend urlBase with /
        let fullURLString = upvoteURL.absoluteString.hasPrefix("http") ? upvoteURL.absoluteString : urlBase + "/" + upvoteURL.absoluteString
        guard let realURL = URL(string: fullURLString) else {
            throw HackersKitError.scraperError
        }
        
        let response = try await networkManager.get(url: realURL)
        
        // Check if the response contains a login form, indicating user needs to authenticate
        let containsLoginForm = response.contains("<form action=\"/login") || response.contains("name=\"acct\"") || response.contains("You have to be logged in")
        if containsLoginForm {
            throw HackersKitError.unauthenticated
        }
    }

    public func unvote(post: Post) async throws {
        // Check if the post has no vote links at all (user not authenticated)
        guard let voteLinks = post.voteLinks else {
            throw HackersKitError.unauthenticated
        }
        
        // Determine unvote URL. If missing but post is marked upvoted and upvote URL exists,
        // derive the unvote URL by swapping how=up -> how=un.
        let resolvedUnvoteURL: URL? = {
            if let explicit = voteLinks.unvote { return explicit }
            if post.upvoted, let upvoteURL = voteLinks.upvote {
                let unvoteURLString = upvoteURL.absoluteString.replacingOccurrences(of: "how=up", with: "how=un")
                return URL(string: unvoteURLString)
            }
            return nil
        }()

        guard let unvoteURL = resolvedUnvoteURL else {
            // If we have vote links but no usable unvote URL, could be:
            // 1. User not authenticated (both upvote and unvote URLs are nil)
            // 2. Not upvoted yet (only upvote link available and post not marked upvoted)
            if voteLinks.upvote == nil {
                throw HackersKitError.unauthenticated
            } else {
                throw HackersKitError.scraperError
            }
        }
        
        // Construct the full URL - unvoteURL may be relative, so prepend urlBase with /
        let fullURLString = unvoteURL.absoluteString.hasPrefix("http") ? unvoteURL.absoluteString : urlBase + "/" + unvoteURL.absoluteString
        guard let realURL = URL(string: fullURLString) else {
            throw HackersKitError.scraperError
        }
        
        let response = try await networkManager.get(url: realURL)
        
        // Check if the response contains a login form, indicating user needs to authenticate
        let containsLoginForm = response.contains("<form action=\"/login") || response.contains("name=\"acct\"")
        if containsLoginForm {
            throw HackersKitError.unauthenticated
        }
    }

    public func upvote(comment: Domain.Comment, for post: Post) async throws {
        // Check if the comment has no vote links at all (user not authenticated)
        guard let voteLinks = comment.voteLinks else {
            throw HackersKitError.unauthenticated
        }
        
        guard let upvoteURL = voteLinks.upvote else {
            // If we have vote links but no upvote URL, could be:
            // 1. User not authenticated (both upvote and unvote URLs are nil)
            // 2. Already upvoted (only unvote link available, shouldn't call upvote)
            
            if voteLinks.unvote == nil {
                // Neither upvote nor unvote URL exists - user not authenticated
                throw HackersKitError.unauthenticated
            } else {
                // Has unvote link but no upvote link - already upvoted, shouldn't upvote again
                throw HackersKitError.scraperError
            }
        }
        
        // Construct the full URL - upvoteURL is relative, so prepend urlBase with /
        let fullURLString = upvoteURL.absoluteString.hasPrefix("http") ? upvoteURL.absoluteString : urlBase + "/" + upvoteURL.absoluteString
        guard let realURL = URL(string: fullURLString) else {
            throw HackersKitError.scraperError
        }
        
        let response = try await networkManager.get(url: realURL)
        
        // Check if the response contains a login form, indicating user needs to authenticate
        let containsLoginForm = response.contains("<form action=\"/login") || response.contains("name=\"acct\"")
        if containsLoginForm {
            throw HackersKitError.unauthenticated
        }
        
        // Update comment state after successful upvote
        await MainActor.run {
            comment.upvoted = true
        }
    }

    public func unvote(comment: Domain.Comment, for post: Post) async throws {
        // Check if the comment has no vote links at all (user not authenticated)
        guard let voteLinks = comment.voteLinks else {
            throw HackersKitError.unauthenticated
        }
        
        guard let unvoteURL = voteLinks.unvote else {
            // If we have vote links but no unvote URL, could be:
            // 1. User not authenticated (both upvote and unvote URLs are nil)
            // 2. Not upvoted yet (only upvote link available, shouldn't call unvote)
            
            if voteLinks.upvote == nil {
                // Neither upvote nor unvote URL exists - user not authenticated
                throw HackersKitError.unauthenticated
            } else {
                // Has upvote link but no unvote link - not upvoted yet, shouldn't unvote
                throw HackersKitError.scraperError
            }
        }
        
        // Construct the full URL - unvoteURL is relative, so prepend urlBase with /
        let fullURLString = unvoteURL.absoluteString.hasPrefix("http") ? unvoteURL.absoluteString : urlBase + "/" + unvoteURL.absoluteString
        guard let realURL = URL(string: fullURLString) else {
            throw HackersKitError.scraperError
        }
        
        let response = try await networkManager.get(url: realURL)
        
        // Check if the response contains a login form, indicating user needs to authenticate
        let containsLoginForm = response.contains("<form action=\"/login") || response.contains("name=\"acct\"")
        if containsLoginForm {
            throw HackersKitError.unauthenticated
        }
        
        // Update comment state after successful unvote
        await MainActor.run {
            comment.upvoted = false
        }
    }

    // MARK: - CommentUseCase

    public func getComments(for post: Post) async throws -> [Domain.Comment] {
        let html = try await fetchPostHtml(id: post.id, recursive: true)
        return try comments(from: html)
    }

    // MARK: - Private Helper Methods

    private func fetchPostsHtml(type: PostType, page: Int, nextId: Int) async throws -> String {
        let url: URL
        if type == .newest || type == .jobs {
            guard let constructedURL = URL(string: "https://news.ycombinator.com/\(type.rawValue)?next=\(nextId)") else {
                throw HackersKitError.requestFailure
            }
            url = constructedURL
        } else if type == .active {
            guard let constructedURL = URL(string: "https://news.ycombinator.com/active?p=\(page)") else {
                throw HackersKitError.requestFailure
            }
            url = constructedURL
        } else {
            guard let constructedURL = URL(string: "https://news.ycombinator.com/\(type.rawValue)?p=\(page)") else {
                throw HackersKitError.requestFailure
            }
            url = constructedURL
        }
        return try await networkManager.get(url: url)
    }

    private func fetchPostHtml(
        id: Int,
        page: Int = 1,
        recursive: Bool = true,
        workingHtml: String = ""
    ) async throws -> String {
        guard let url = hackerNewsURL(id: id, page: page) else {
            throw HackersKitError.requestFailure
        }

        let html = try await networkManager.get(url: url)
        let document = try SwiftSoup.parse(html)
        let moreLinkExists = try !document.select("a.morelink").isEmpty()

        if moreLinkExists && recursive {
            return try await fetchPostHtml(id: id, page: page + 1, recursive: recursive, workingHtml: html)
        } else {
            return workingHtml + html
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

    // MARK: - HTML Parsing (simplified version from HtmlParser)

    private func postsTableElement(from html: String) throws -> Element {
        let document = try SwiftSoup.parse(html)
        guard let tableElement = try document.select("table:has(.athing.submission)").first() else {
            throw HackersKitError.scraperError
        }
        return tableElement
    }

    private func posts(from tableElement: Element, type: PostType) throws -> [Post] {
        if tableElement.hasClass("fatitem") {
            // For single post pages, we need to get only the first two tr elements
            let allRows = try tableElement.select("tr")
            guard allRows.size() >= 2 else {
                throw HackersKitError.scraperError
            }
            let titleElement = try allRows.get(0)
            let metadataElement = try allRows.get(1)
            let postElements = Elements([titleElement, metadataElement])
            let post = try self.post(from: postElements, type: type)
            return [post]
        } else {
            let titleElements = try tableElement.select("tr.athing")
            let posts = try titleElements.compactMap { titleElement -> Post? in
                guard let metadataElement = try titleElement.nextElementSibling() else {
                    return nil
                }
                let postElements = Elements([titleElement, metadataElement])
                return try? self.post(from: postElements, type: type)
            }
            return posts
        }
    }

    private func post(from elements: Elements, type: PostType) throws -> Post {
        guard elements.size() >= 2 else {
            throw HackersKitError.scraperError
        }

        let titleElement = try elements.get(0)
        let metadataElement = try elements.get(1)

        let id = Int(try titleElement.attr("id")) ?? 0
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

        // Find comments link specifically (like original HtmlParser)
        let linkElements = try metadataElement.select("a")
        let commentLinkElement = linkElements.first { element in
            let text = try? element.text()
            return text?.contains("comment") == true
        }

        let commentsCount: Int
        if let commentLinkText = try commentLinkElement?.text(),
           let commentsCountString = commentLinkText.components(separatedBy: .whitespaces).first,
           let count = Int(String(commentsCountString)) {
            commentsCount = count
        } else {
            commentsCount = 0
        }

        let voteLinks = try self.voteLinks(from: titleElement, metadata: metadataElement)
        
        // Preserve vote links if either upvote or unvote is present.
        // Previously we dropped links when upvote was nil, which broke unvoting.
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
            voteLinks: finalVoteLinks
        )
    }

    private func voteLinks(from titleElement: Element, metadata metadataElement: Element? = nil) throws -> (upvote: URL?, unvote: URL?, upvoted: Bool) {
        // Look for upvote link in the votelinks column of the title row
        let voteLinkElements = try titleElement.select("td.votelinks a")
        let upvoteLink = try voteLinkElements.first { try $0.attr("id").starts(with: "up_") }

        // Look for unvote link - first try title element (for individual posts), then metadata element (for feed)
        var unvoteLink = try voteLinkElements.first { try $0.attr("id").starts(with: "un_") }
        if unvoteLink == nil {
            unvoteLink = try voteLinkElements.first { try $0.text().lowercased() == "unvote" }
        }

        // If not found in title element and we have metadata element, look there
        if unvoteLink == nil, let metadataElement = metadataElement {
            let metadataUnvoteLinks = try metadataElement.select("a")
            unvoteLink = try metadataUnvoteLinks.first { try $0.attr("id").starts(with: "un_") }
            if unvoteLink == nil {
                unvoteLink = try metadataUnvoteLinks.first { try $0.text().lowercased() == "unvote" }
            }
        }

        let upvoteURL = try upvoteLink.map { try URL(string: $0.attr("href")) } ?? nil
        var derivedUnvoteURL = try unvoteLink.map { try URL(string: $0.attr("href")) } ?? nil

        // Determine upvoted state more robustly:
        // - If an explicit unvote link exists, it's upvoted
        // - Some HN pages hide the upvote arrow via 'nosee' class when already upvoted
        let upvoteHidden: Bool = {
            guard let up = upvoteLink else { return false }
            return (try? up.hasClass("nosee")) ?? false
        }()

        // If we're upvoted but no explicit unvote link is present, derive it from the upvote URL
        if derivedUnvoteURL == nil, upvoteHidden, let upvoteURL = upvoteURL {
            let unvoteURLString = upvoteURL.absoluteString.replacingOccurrences(of: "how=up", with: "how=un")
            derivedUnvoteURL = URL(string: unvoteURLString)
        }

        let upvoted = (derivedUnvoteURL != nil) || upvoteHidden

        return (upvote: upvoteURL, unvote: derivedUnvoteURL, upvoted: upvoted)
    }

    private func comments(from html: String) throws -> [Domain.Comment] {
        let document = try SwiftSoup.parse(html)
        let commentElements = try document.select(".comtr")

        return commentElements.compactMap { element in
            do {
                return try parseComment(from: element)
            } catch {
                // Skip comments that can't be parsed (deleted, etc.)
                return nil
            }
        }
    }

    private func parseComment(from element: Element) throws -> Domain.Comment {
        let text = try commentText(from: element.select(".commtext"))

        // Skip empty comments (deleted comments, etc.)
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw HackersKitError.scraperError
        }

        let age = try element.select(".age").text()
        let user = try element.select(".hnuser").text()
        guard let id = try Int(element.select(".comtr").attr("id")) else {
            throw HackersKitError.scraperError
        }
        guard let indentWidth = try Int(element.select(".ind img").attr("width")) else {
            throw HackersKitError.scraperError
        }
        let level = indentWidth / 40
        let voteLinksResult = try self.voteLinks(from: element)
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
            parsedText: parsedText
        )
    }

    private func commentText(from elements: Elements) throws -> String {
        // Clear reply link from text
        if let replyElement = try? elements.select(".reply") {
            try replyElement.html("")
        }

        // Parse links from href attribute rather than truncated text
        if let links = try? elements.select("a") {
            try links.forEach { link in
                if let url = try? link.attr("href") {
                    try link.html(url)
                }
            }
        }

        return try elements.html()
    }
}
// swiftlint:enable type_body_length
