//
//  NetworkManagerTests.swift
//  NetworkingTests
//
//  Copyright © 2025 Weiran Zhang. All rights reserved.
//

import Foundation
@testable import Networking
import Testing

// Serialise the suite so concurrent runs don't fight over HTTPCookieStorage.shared
@Suite("NetworkManager Tests", .serialized)
struct NetworkManagerTests {
    // MARK: - Mock URLProtocol

    final class MockURLProtocol: URLProtocol {
        // Handler returns: HTTPURLResponse, Data, optional artificial delay (seconds)
        nonisolated(unsafe) static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data, TimeInterval?))?

        // Default handler used across tests to avoid shared-state races
        nonisolated static func defaultHandler(_ request: URLRequest) throws -> (HTTPURLResponse, Data, TimeInterval?) {
            let url = request.url ?? URL(string: "https://example.com")!
            let method = request.httpMethod ?? "GET"

            // Helper to read body string from httpBody or httpBodyStream
            func bodyString(from request: URLRequest) -> String {
                if let body = request.httpBody, let s = String(data: body, encoding: .utf8) { return s }
                if let stream = request.httpBodyStream {
                    stream.open()
                    defer { stream.close() }
                    var data = Data()
                    let bufSize = 1024
                    let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufSize)
                    defer { buffer.deallocate() }
                    while stream.hasBytesAvailable {
                        let read = stream.read(buffer, maxLength: bufSize)
                        if read > 0 { data.append(buffer, count: read) } else { break }
                    }
                    if let s = String(data: data, encoding: .utf8) { return s }
                }
                return ""
            }

            // Simulate failures for certain hosts/paths
            if url.host?.contains("invalid-url") == true || url.path.contains("/unreachable") {
                throw URLError(.cannotFindHost)
            }

            // Simulate concurrency delay endpoints
            if url.path.contains("/delay/short") {
                let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!
                return (response, Data("ok".utf8), 0.1)
            }

            if method == "POST" {
                let contentType = request.value(forHTTPHeaderField: "Content-Type") ?? ""
                let body = bodyString(from: request)
                let parts = [
                    "received=ok",
                    "method=POST",
                    "url=\(url.absoluteString)",
                    "content-type=\(contentType)",
                    "body=\(body)",
                ]
                let data = parts.joined(separator: "&").data(using: .utf8)!
                let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!
                return (response, data, nil)
            } else {
                // GET endpoints
                if url.path.contains("/encoding/utf8") {
                    let sample = "Unicode ✓ — café — 😀"
                    let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!
                    return (response, Data(sample.utf8), nil)
                }
                let data = "{\"status\":\"ok\",\"source\":\"mock\"}".data(using: .utf8)!
                let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!
                return (response, data, nil)
            }
        }

        override class func canInit(with _: URLRequest) -> Bool { true }
        override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
        override func startLoading() {
            guard let handler = Self.requestHandler else {
                client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
                return
            }
            do {
                let (response, data, delay) = try handler(request)
                let execute = {
                    self.client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
                    self.client?.urlProtocol(self, didLoad: data)
                    self.client?.urlProtocolDidFinishLoading(self)
                }
                if let delay, delay > 0 {
                    DispatchQueue.global().asyncAfter(deadline: .now() + delay, execute: execute)
                } else {
                    execute()
                }
            } catch {
                client?.urlProtocol(self, didFailWithError: error)
            }
        }

        override func stopLoading() { /* no-op */ }
    }

    private func makeManager() -> NetworkManager {
        if MockURLProtocol.requestHandler == nil {
            MockURLProtocol.requestHandler = MockURLProtocol.defaultHandler(_:)
        }
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        config.timeoutIntervalForRequest = 5
        config.timeoutIntervalForResource = 5
        let session = URLSession(configuration: config)
        return NetworkManager(session: session)
    }

    // MARK: - GET Request Tests

    @Test("GET request with non-2xx status throws")
    func getRequestWithServerErrorStatus() async {
        // Temporarily override handler to return 500 for this test
        let original = MockURLProtocol.requestHandler
        defer { MockURLProtocol.requestHandler = original }

        MockURLProtocol.requestHandler = { request in
            if let url = request.url, url.path.contains("/status/500") {
                let response = HTTPURLResponse(url: url, statusCode: 500, httpVersion: nil, headerFields: nil)!
                return (response, Data("error".utf8), nil)
            }
            return try MockURLProtocol.defaultHandler(request)
        }

        let manager = makeManager()
        let url = URL(string: "https://example.com/status/500")!
        do {
            _ = try await manager.get(url: url)
            Issue.record("Expected badServerResponse error for non-2xx status")
        } catch {
            #expect((error as? URLError)?.code == .badServerResponse, "Should throw badServerResponse on non-2xx status")
        }
    }

    // MARK: - Cookie Management Tests

    @Test("Clear cookies scoped to Hacker News domain")
    func clearCookies() {
        let manager = NetworkManager()

        // Store initial cookies state to restore later
        let initialCookies = HTTPCookieStorage.shared.cookies ?? []

        // Cleanup after test completes
        defer {
            // Clear all cookies and restore initial state
            HTTPCookieStorage.shared.removeCookies(since: Date.distantPast)
            for cookie in initialCookies {
                HTTPCookieStorage.shared.setCookie(cookie)
            }
        }

        // clearCookies must complete without errors and be idempotent
        manager.clearCookies()
        manager.clearCookies()

        // Seed both an HN session cookie and an unrelated third-party cookie.
        let hackerNewsCookie = HTTPCookie(properties: [
            .domain: "news.ycombinator.com",
            .path: "/",
            .name: "user",
            .value: "hn-session",
        ])!
        let otherCookie = HTTPCookie(properties: [
            .domain: "other-site.example",
            .path: "/",
            .name: "prefs",
            .value: "keep-me",
        ])!

        HTTPCookieStorage.shared.setCookie(hackerNewsCookie)
        HTTPCookieStorage.shared.setCookie(otherCookie)

        let cookiesAfterSet = HTTPCookieStorage.shared.cookies ?? []
        #expect(cookiesAfterSet.contains { $0.name == "user" && $0.domain.contains("news.ycombinator.com") },
                "HN cookie should be set")
        #expect(cookiesAfterSet.contains { $0.name == "prefs" }, "Other cookie should be set")

        manager.clearCookies()

        let remainingCookies = HTTPCookieStorage.shared.cookies ?? []
        let hackerNewsCookieRemains = remainingCookies.contains { cookie in
            cookie.name == "user" && cookie.domain.contains("news.ycombinator.com")
        }
        let otherCookieRemains = remainingCookies.contains { cookie in
            cookie.name == "prefs" && cookie.domain == "other-site.example"
        }
        #expect(!hackerNewsCookieRemains, "HN cookie should be cleared")
        #expect(otherCookieRemains, "Non-HN cookie should be preserved")
    }

    @Test("Response string encoding")
    func responseStringEncoding() async throws {
        // Test that responses are properly decoded as UTF-8 strings
        let url = URL(string: "https://example.com/encoding/utf8")!
        let manager = makeManager()

        let response = try await manager.get(url: url)

        #expect(response == "Unicode ✓ — café — 😀")
    }

    // MARK: - Structured Response Tests

    @Test("Structured GET returns body, status code, and final URL")
    func structuredGetResponse() async throws {
        let url = URL(string: "https://example.com/get")!
        let manager = makeManager()

        let response = try await manager.getResponse(url: url)

        #expect(response.statusCode == 200)
        #expect(response.finalURL == url)
        #expect(response.body.contains("ok"))
    }

    @Test("Structured POST sends the form body and exposes response metadata")
    func structuredPostResponse() async throws {
        let url = URL(string: "https://example.com/post")!
        let manager = makeManager()
        let response = try await manager.postResponse(url: url, body: "a%26b=c")

        #expect(response.statusCode == 200)
        #expect(response.finalURL == url)
        #expect(response.body.contains("method=POST"))
        #expect(response.body.contains("content-type=application/x-www-form-urlencoded"))
        #expect(response.body.contains("body=a%26b=c"))
    }

    @Test("Structured responses surface non-2xx bodies instead of throwing")
    func structuredNon2xxResponses() async throws {
        let original = MockURLProtocol.requestHandler
        defer { MockURLProtocol.requestHandler = original }

        MockURLProtocol.requestHandler = { request in
            if let url = request.url, url.path.contains("/status/500") {
                let response = HTTPURLResponse(url: url, statusCode: 500, httpVersion: nil, headerFields: nil)!
                return (response, Data("server error".utf8), nil)
            }
            return try MockURLProtocol.defaultHandler(request)
        }

        let manager = makeManager()

        let getResponse = try await manager.getResponse(url: URL(string: "https://example.com/status/500")!)
        #expect(getResponse.statusCode == 500)
        #expect(getResponse.body == "server error")

        let postResponse = try await manager.postResponse(
            url: URL(string: "https://example.com/status/500")!,
            body: "x"
        )
        #expect(postResponse.statusCode == 500)
        #expect(postResponse.body == "server error")
    }

    // Redirect following cannot be simulated through a custom URLProtocol
    // (URLSession treats protocol-provided 302 responses as terminal), so the
    // "finalURL is the post-redirect URL" guarantee is not unit-testable here.
    // It comes from URLSession's default redirect following plus the final
    // HTTPURLResponse's url, and was verified against live Hacker News
    // redirect responses during the commenting contract research.

    @Test("Named cookie lookup is exact and host scoped")
    func namedCookieLookup() {
        let manager = NetworkManager()
        let hackerNewsURL = URL(string: "https://news.ycombinator.com")!
        let otherURL = URL(string: "https://other-site.example")!

        let initialCookies = HTTPCookieStorage.shared.cookies ?? []
        defer {
            HTTPCookieStorage.shared.removeCookies(since: Date.distantPast)
            for cookie in initialCookies {
                HTTPCookieStorage.shared.setCookie(cookie)
            }
        }
        HTTPCookieStorage.shared.removeCookies(since: Date.distantPast)

        let userCookie = HTTPCookie(properties: [
            .domain: "news.ycombinator.com",
            .path: "/",
            .name: "user",
            .value: "hn-session",
        ])!
        let prefsCookie = HTTPCookie(properties: [
            .domain: "news.ycombinator.com",
            .path: "/",
            .name: "prefs",
            .value: "list",
        ])!
        HTTPCookieStorage.shared.setCookie(userCookie)
        HTTPCookieStorage.shared.setCookie(prefsCookie)

        #expect(manager.containsCookie(named: "user", for: hackerNewsURL))
        #expect(manager.containsCookie(named: "prefs", for: hackerNewsURL))
        #expect(!manager.containsCookie(named: "session", for: hackerNewsURL), "Unknown cookie names must not match")
        #expect(!manager.containsCookie(named: "user", for: otherURL), "Named lookup must stay scoped to the HN host")
    }
}
