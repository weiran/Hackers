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

    func fetchPostHtml(
        id: Int,
        page: Int = 1,
        recursive: Bool = true,
        workingHtml: String = "",
    ) async throws -> String {
        guard let url = hackerNewsURL(id: id, page: page) else {
            throw HackersKitError.requestFailure
        }

        let html = try await networkManager.get(url: url)
        let document = try SwiftSoup.parse(html)
        let moreLinkExists = try !document.select("a.morelink").isEmpty()

        if moreLinkExists, recursive {
            return try await fetchPostHtml(id: id, page: page + 1, recursive: recursive, workingHtml: html)
        } else {
            return workingHtml + html
        }
    }

    func hackerNewsURL(id: Int, page: Int) -> URL? {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "news.ycombinator.com"
        components.path = "/item"
        components.queryItems = [
            URLQueryItem(name: "id", value: String(id)),
            URLQueryItem(name: "p", value: String(page)),
        ]
        return components.url
    }
}
