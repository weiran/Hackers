//
//  PostRepository+Networking.swift
//  Data
//
//  Split networking helpers from PostRepository to reduce file length
//

import Domain
import Foundation

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
    ) async throws -> String {
        guard let url = hackerNewsURL(id: id) else {
            throw HackersKitError.requestFailure
        }

        return try await networkManager.get(url: url)
    }

    func hackerNewsURL(id: Int) -> URL? {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "news.ycombinator.com"
        components.path = "/item"
        components.queryItems = [
            URLQueryItem(name: "id", value: String(id))
        ]
        return components.url
    }
}
