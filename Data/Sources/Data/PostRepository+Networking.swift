//
//  PostRepository+Networking.swift
//  Data
//
//  Split networking helpers from PostRepository to reduce file length
//

import Domain
import Foundation
import SwiftSoup

extension PostRepository {
    // MARK: - Networking helpers

    /// Upper bound on how many comment pages to fetch for a single thread. Hacker News
    /// paginates comments roughly 30 per page behind a `<a class="morelink">` link; without
    /// following it we only ever see the first page. The bound keeps a pathological or
    /// transient response chain from triggering unbounded requests.
    private static let maxPostPages = 10

    func fetchPostsHtml(type: PostType, page: Int, nextId: Int) async throws -> String {
        let url: URL
        if type == .newest || type == .jobs {
            guard let constructedURL = URL(
                string: "https://news.ycombinator.com/\(type.rawValue)?next=\(nextId)",
            ) else {
                throw HackersKitError.requestFailure
            }
            url = constructedURL
        } else if type == .active {
            guard let constructedURL = URL(
                string: "https://news.ycombinator.com/active?p=\(page)",
            ) else {
                throw HackersKitError.requestFailure
            }
            url = constructedURL
        } else {
            guard let constructedURL = URL(
                string: "https://news.ycombinator.com/\(type.rawValue)?p=\(page)",
            ) else {
                throw HackersKitError.requestFailure
            }
            url = constructedURL
        }
        return try await networkManager.get(url: url)
    }

    /// Fetches the full HTML for an item page, following Hacker News' comment pagination.
    ///
    /// HN serves comments roughly 30 per page behind a `<a class="morelink" href="...&p=N">`
    /// link. We fetch pages iteratively and concatenate the HTML so the comment parser sees
    /// the whole thread. Iteration is bounded by `maxPostPages` so a transient or
    /// pathological response chain cannot trigger unbounded requests.
    ///
    /// Failure mode is all-or-nothing: if a later page's request throws, the already-fetched
    /// earlier pages are discarded and the error propagates. This keeps callers (getPost) from
    /// rendering a partial thread and is acceptable because the caller surfaces the error.
    func fetchPostHtml(id: Int) async throws -> String {
        var combined = ""
        var page = 1
        var hasMore = true

        while hasMore, page <= Self.maxPostPages {
            guard let url = hackerNewsURL(id: id, page: page) else {
                throw HackersKitError.requestFailure
            }
            let html = try await networkManager.get(url: url)
            combined += html
            hasMore = try hasMoreComments(in: html)
            page += 1
        }

        return combined
    }

    /// Returns true when `html` contains a `morelink`, indicating another comment page.
    private func hasMoreComments(in html: String) throws -> Bool {
        let document = try SwiftSoup.parse(html)
        return try !document.select("a.morelink").isEmpty()
    }

    func hackerNewsURL(id: Int, page: Int = 1) -> URL? {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "news.ycombinator.com"
        components.path = "/item"
        var queryItems = [URLQueryItem(name: "id", value: String(id))]
        if page > 1 {
            queryItems.append(URLQueryItem(name: "p", value: String(page)))
        }
        components.queryItems = queryItems
        return components.url
    }
}
