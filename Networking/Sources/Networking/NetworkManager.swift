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
        return String(data: data, encoding: .utf8) ?? ""
    }

    public func post(url: URL, body: String) async throws -> String {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = body.data(using: .utf8)
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let (data, response) = try await session.data(for: request)
        let html = String(data: data, encoding: .utf8) ?? ""

        return html
    }

    public func clearCookies() {
        HTTPCookieStorage.shared.cookies?.forEach(HTTPCookieStorage.shared.deleteCookie(_:))
    }

    public func containsCookie(for url: URL) -> Bool {
        guard let cookies = HTTPCookieStorage.shared.cookies(for: url) else {
            return false
        }
        return !cookies.isEmpty
    }

    // Follow redirects by default; no custom handling needed
}
