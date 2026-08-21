//
//  NetworkManager.swift
//  Networking
//
//  Copyright © 2025 Weiran Zhang. All rights reserved.
//

import Foundation

public struct NetworkResponse: Sendable, Equatable {
    public let body: String
    public let statusCode: Int
    public let finalURL: URL

    public init(body: String, statusCode: Int, finalURL: URL) {
        self.body = body
        self.statusCode = statusCode
        self.finalURL = finalURL
    }
}

public protocol NetworkManagerProtocol: Sendable {
    func getResponse(url: URL) async throws -> NetworkResponse
    func postResponse(url: URL, body: String) async throws -> NetworkResponse

    func get(url: URL) async throws -> String
    func post(url: URL, body: String) async throws -> String

    func clearCookies()
    func containsCookie(for url: URL) -> Bool
    func containsCookie(named name: String, for url: URL) -> Bool
}

public final class NetworkManager: NSObject, URLSessionDelegate, URLSessionTaskDelegate,
    NetworkManagerProtocol, Sendable {
    private let session: URLSession

    override public init() {
        // Use a configuration that avoids writing responses to disk to minimize storage.
        let config = URLSessionConfiguration.default
        config.urlCache = nil // disable URL caching for this session
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        config.httpCookieStorage = HTTPCookieStorage.shared // preserve existing cookie behavior
        session = URLSession(configuration: config, delegate: nil, delegateQueue: nil)
        super.init()
    }

    // Testability: allow injecting a custom URLSession (e.g. with a mock URLProtocol)
    public init(session: URLSession) {
        self.session = session
        super.init()
    }

    public func getResponse(url: URL) async throws -> NetworkResponse {
        try await perform(URLRequest(url: url))
    }

    public func postResponse(url: URL, body: String) async throws -> NetworkResponse {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = body.data(using: .utf8)
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        return try await perform(request)
    }

    public func get(url: URL) async throws -> String {
        let response = try await getResponse(url: url)
        guard (200 ... 299).contains(response.statusCode) else {
            throw URLError(.badServerResponse)
        }
        return response.body
    }

    public func post(url: URL, body: String) async throws -> String {
        let response = try await postResponse(url: url, body: body)
        guard (200 ... 299).contains(response.statusCode) else {
            throw URLError(.badServerResponse)
        }
        return response.body
    }

    private func perform(_ request: URLRequest) async throws -> NetworkResponse {
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        guard let body = String(data: data, encoding: .utf8) else {
            throw URLError(.cannotDecodeContentData)
        }
        // URLSession follows redirects by default, so the final response's URL
        // is the URL the request ultimately landed on.
        guard let finalURL = http.url ?? request.url else {
            throw URLError(.badServerResponse)
        }
        return NetworkResponse(
            body: body,
            statusCode: http.statusCode,
            finalURL: finalURL
        )
    }

    public func clearCookies() {
        // Only clear Hacker News session cookies. The session uses the shared cookie
        // storage, so deleting every cookie would also wipe cookies belonging to other
        // domains (e.g. the in-app browser's web content). Scope deletion to HN.
        let hackerNewsHost = "news.ycombinator.com"
        for cookie in HTTPCookieStorage.shared.cookies ?? [] where cookie.domain.contains(hackerNewsHost) {
            HTTPCookieStorage.shared.deleteCookie(cookie)
        }
    }

    public func containsCookie(for url: URL) -> Bool {
        if let scopedCookies = HTTPCookieStorage.shared.cookies(for: url), !scopedCookies.isEmpty {
            return true
        }

        guard let host = url.host else { return false }

        let allCookies = HTTPCookieStorage.shared.cookies ?? []
        return allCookies.contains { cookie in
            let domain = cookie.domain.trimmingCharacters(in: CharacterSet(charactersIn: "."))
            return host == cookie.domain
                || host == domain
                || host.hasSuffix(domain)
        }
    }

    public func containsCookie(named name: String, for url: URL) -> Bool {
        if let scopedCookies = HTTPCookieStorage.shared.cookies(for: url),
           scopedCookies.contains(where: { $0.name == name }) {
            return true
        }

        guard let host = url.host else { return false }

        let allCookies = HTTPCookieStorage.shared.cookies ?? []
        return allCookies.contains { cookie in
            guard cookie.name == name else { return false }
            let domain = cookie.domain.trimmingCharacters(in: CharacterSet(charactersIn: "."))
            return host == cookie.domain
                || host == domain
                || host.hasSuffix(domain)
        }
    }

    // Follow redirects by default; no custom handling needed
}
