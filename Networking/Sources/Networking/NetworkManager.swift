//
//  NetworkManager.swift
//  Networking
//
//  Copyright © 2025 Weiran Zhang. All rights reserved.
//

import Foundation

public protocol NetworkManagerProtocol: Sendable {
    func get(url: URL) async throws -> String
    func post(url: URL, body: String) async throws -> String
    func clearCookies()
    func containsCookie(for url: URL) -> Bool
}

public final class NetworkManager: NSObject, URLSessionDelegate, URLSessionTaskDelegate,
    NetworkManagerProtocol, Sendable
{
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

    public func get(url: URL) async throws -> String {
        let request = URLRequest(url: url)
        let (data, response) = try await session.data(for: request)
        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            throw URLError(.badServerResponse)
        }
        return String(data: data, encoding: .utf8) ?? ""
    }

    public func post(url: URL, body: String) async throws -> String {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = body.data(using: .utf8)
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let (data, response) = try await session.data(for: request)
        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            throw URLError(.badServerResponse)
        }
        let html = String(data: data, encoding: .utf8) ?? ""

        return html
    }

    public func clearCookies() {
        HTTPCookieStorage.shared.cookies?.forEach(HTTPCookieStorage.shared.deleteCookie(_:))
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

    // Follow redirects by default; no custom handling needed
}
