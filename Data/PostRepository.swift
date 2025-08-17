import Domain
import Networking
import Foundation
import SwiftSoup

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
        let html = try await fetchPostHtml(id: id, recursive: false)
        let document = try SwiftSoup.parse(html)
        let post = try post(from: document.select(".fatitem"), type: .news)
        let comments = try self.comments(from: html)
        var postWithComments = post
        postWithComments.comments = comments
        return postWithComments
    }

    // MARK: - VoteUseCase

    public func upvote(post: Post) async throws {
        guard
            let upvoteURL = post.voteLinks?.upvote,
            let realURL = URL(string: urlBase + upvoteURL.absoluteString)
        else {
            throw HackersKitError.scraperError
        }
        _ = try await networkManager.get(url: realURL)
    }

    public func unvote(post: Post) async throws {
        guard
            let unvoteURL = post.voteLinks?.unvote,
            let realURL = URL(string: urlBase + unvoteURL.absoluteString)
        else {
            throw HackersKitError.scraperError
        }
        _ = try await networkManager.get(url: realURL)
    }

    public func upvote(comment: Domain.Comment, for post: Post) async throws {
        guard
            let upvoteURL = comment.voteLinks?.upvote,
            let realURL = URL(string: urlBase + upvoteURL.absoluteString)
        else {
            throw HackersKitError.scraperError
        }
        _ = try await networkManager.get(url: realURL)
    }

    public func unvote(comment: Domain.Comment, for post: Post) async throws {
        guard
            let unvoteURL = comment.voteLinks?.unvote,
            let realURL = URL(string: urlBase + unvoteURL.absoluteString)
        else {
            throw HackersKitError.scraperError
        }
        _ = try await networkManager.get(url: realURL)
    }

    // MARK: - CommentUseCase

    public func getComments(for post: Post) async throws -> [Domain.Comment] {
        let html = try await fetchPostHtml(id: post.id, recursive: true)
        return try comments(from: html)
    }

    // MARK: - Private Helper Methods

    private func fetchPostsHtml(type: PostType, page: Int, nextId: Int) async throws -> String {
        var url: URL
        if type == .newest || type == .jobs {
            url = URL(string: "https://news.ycombinator.com/\(type.rawValue)?next=\(nextId)")!
        } else if type == .active {
            url = URL(string: "https://news.ycombinator.com/active?p=\(page)")!
        } else {
            url = URL(string: "https://news.ycombinator.com/\(type.rawValue)?p=\(page)")!
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
        return try document.select("table.itemlist").first()!
    }

    private func posts(from tableElement: Element, type: PostType) throws -> [Post] {
        if tableElement.hasClass("fatitem") {
            let postElements = try tableElement.select("tr")
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
        let titleElement = try elements.first()!
        let metadataElement = try elements.get(1)

        let id = Int(try titleElement.attr("id")) ?? 0
        let titleLink = try titleElement.select("span.titleline > a").first()!
        let title = try titleLink.text()
        let url = URL(string: try titleLink.attr("href")) ?? URL(string: "https://news.ycombinator.com")!

        let scoreElement = try metadataElement.select("span.score")
        let score = try scoreElement.first()?.text().replacingOccurrences(of: " points", with: "")
        let scoreInt = Int(score ?? "0") ?? 0

        let ageElement = try metadataElement.select("span.age")
        let age = try ageElement.first()?.attr("title") ?? ""

        let byElement = try metadataElement.select("a.hnuser")
        let by = try byElement.first()?.text() ?? ""

        let commentsElement = try metadataElement.select("a").last()
        let commentsText = try commentsElement?.text() ?? "0 comments"
        let commentsCount = Int(commentsText.components(separatedBy: " ").first ?? "0") ?? 0

        let voteLinks = try self.voteLinks(from: metadataElement)

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
            voteLinks: VoteLinks(upvote: voteLinks.upvote, unvote: voteLinks.unvote)
        )
    }

    private func voteLinks(from element: Element) throws -> (upvote: URL?, unvote: URL?, upvoted: Bool) {
        let voteLinkElements = try element.select("a")
        let upvoteLink = try voteLinkElements.first { try $0.attr("id").starts(with: "up_") }
        var unvoteLink = try voteLinkElements.first { try $0.attr("id").starts(with: "un_") }
        if unvoteLink == nil {
            unvoteLink = try voteLinkElements.first { try $0.text().lowercased() == "unvote" }
        }

        let upvoteURL = try upvoteLink.map { try URL(string: $0.attr("href")) } ?? nil
        let unvoteURL = try unvoteLink.map { try URL(string: $0.attr("href")) } ?? nil

        let upvoted = unvoteLink != nil

        return (upvote: upvoteURL, unvote: unvoteURL, upvoted: upvoted)
    }

    private func comments(from html: String) throws -> [Domain.Comment] {
        // Simplified comment parsing - would need full implementation from CommentHTMLParser
        return []
    }
}