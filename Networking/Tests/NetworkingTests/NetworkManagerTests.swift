//
//  NetworkManagerTests.swift
//  NetworkingTests
//
//  Copyright © 2025 Weiran Zhang. All rights reserved.
//

import Testing
@testable import Networking
import Foundation

@Suite("NetworkManager Tests")
struct NetworkManagerTests {

    // Default instance (no network calls made in tests that use mocks)
    let defaultManager = NetworkManager()

    // MARK: - Mock URLProtocol
    final class MockURLProtocol: URLProtocol {
        // Handler returns: HTTPURLResponse, Data, optional artificial delay (seconds)
        nonisolated(unsafe) static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data, TimeInterval?))?

        // Default handler used across tests to avoid shared-state races
        nonisolated(unsafe) static func defaultHandler(_ request: URLRequest) throws -> (HTTPURLResponse, Data, TimeInterval?) {
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
                    "body=\(body)"
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

        override class func canInit(with request: URLRequest) -> Bool { true }
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
                    DispatchQueue.global().asyncAfter(deadline: .now() + delay) { execute() }
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

    // MARK: - Initialization Tests

    @Test("NetworkManager initialization")
    func networkManagerInitialization() {
        #expect(defaultManager != nil, "NetworkManager should initialize successfully")
    }

    // MARK: - GET Request Tests

    @Test("GET request with valid URL")
    func getRequestWithValidURL() async throws {
        let url = URL(string: "https://example.com/get")!
        let manager = makeManager()

        let response = try await manager.get(url: url)

        #expect(!response.isEmpty, "Response should not be empty")
        #expect(response.contains("ok"), "Response should contain expected marker")
    }

    @Test("GET request with invalid URL")
    func getRequestWithInvalidURL() async {
        let url = URL(string: "https://invalid-url.example")!
        let manager = makeManager()

        do {
            _ = try await manager.get(url: url)
            Issue.record("Expected network error for invalid URL")
        } catch {
            #expect(error != nil, "Should throw an error for invalid URL")
        }
    }

    // MARK: - POST Request Tests

    @Test("POST request with valid URL")
    func postRequestWithValidURL() async throws {
        let url = URL(string: "https://example.com/post")!
        let body = "test=data&key=value"
        let manager = makeManager()

        let response = try await manager.post(url: url, body: body)

        #expect(!response.isEmpty, "Response should not be empty")
        #expect(response.contains("received=ok"), "Response should contain mock marker")
        #expect(response.contains("method=POST"), "Response should reflect POST method")
        #expect(response.contains(url.absoluteString), "Response should include echoed URL")
        #expect(response.contains("body=\(body)"), "Response should include echoed body")
    }

    @Test("POST request with empty body")
    func postRequestWithEmptyBody() async throws {
        let url = URL(string: "https://example.com/post")!
        let body = ""
        let manager = makeManager()

        let response = try await manager.post(url: url, body: body)

        #expect(!response.isEmpty, "Response should not be empty")
        #expect(response.contains("method=POST"), "Response should reflect POST method")
    }

    @Test("POST request with invalid URL")
    func postRequestWithInvalidURL() async {
        let url = URL(string: "https://invalid-url.example")!
        let body = "test=data"
        let manager = makeManager()

        do {
            _ = try await manager.post(url: url, body: body)
            Issue.record("Expected network error for invalid URL")
        } catch {
            #expect(error != nil, "Should throw an error for invalid URL")
        }
    }

    // MARK: - Cookie Management Tests

    @Test("Clear cookies functionality")
    func clearCookies() {
        // Store initial cookie state to restore later for test isolation
        let initialCookies = HTTPCookieStorage.shared.cookies ?? []

        // Clean up: restore initial cookies to not affect other tests
        defer {
            // Clear all cookies first
            HTTPCookieStorage.shared.cookies?.forEach(HTTPCookieStorage.shared.deleteCookie)
            // Restore original cookies
            initialCookies.forEach(HTTPCookieStorage.shared.setCookie)
        }

        // Create a test cookie that will be added and then cleared
        let testCookie = HTTPCookie(properties: [
            .domain: "example.com",
            .path: "/",
            .name: "testCookie_\(Int.random(in: 1000...9999))",
            .value: "testValue"
        ])!

        // Set the test cookie
        HTTPCookieStorage.shared.setCookie(testCookie)

        // Verify cookie was added (synchronous operation)
        let cookiesWithTest = HTTPCookieStorage.shared.cookies ?? []
        #expect(cookiesWithTest.contains(testCookie), "Test cookie should be set")

        // Create manager and clear cookies
        let manager = NetworkManager()
        manager.clearCookies()

        // Verify ALL cookies are cleared (this is synchronous)
        let cookiesAfterClear = HTTPCookieStorage.shared.cookies ?? []
        #expect(cookiesAfterClear.isEmpty, "All cookies should be cleared")
        #expect(!cookiesAfterClear.contains(testCookie), "Test cookie should be cleared")
    }

    @Test("Contains cookie for URL functionality")
    func containsCookieForURL() {
        let url = URL(string: "https://example.com")!

        // Initially should have no cookies
        #expect(!defaultManager.containsCookie(for: url), "Should have no cookies initially")

        // Add a cookie for the domain
        let cookie = HTTPCookie(properties: [
            .domain: "example.com",
            .path: "/",
            .name: "testCookie",
            .value: "testValue"
        ])!

        HTTPCookieStorage.shared.setCookie(cookie)

        // Now should detect cookie
        #expect(defaultManager.containsCookie(for: url), "Should detect cookie after setting")

        // Clean up
        HTTPCookieStorage.shared.deleteCookie(cookie)
    }

    @Test("Contains cookie for URL with no cookies")
    func containsCookieForURLWithNoCookies() {
        let url = URL(string: "https://no-cookies-example.com")!

        // Clear all cookies first
        defaultManager.clearCookies()

        // Should return false for URL with no cookies
        #expect(!defaultManager.containsCookie(for: url), "Should return false for URL with no cookies")
    }

    // MARK: - URLSessionDelegate Tests

    @Test("Redirect handling")
    func redirectHandling() {
        // This tests the urlSession:task:willPerformHTTPRedirection method
        // Since it's designed to prevent redirects, we test that it returns nil

        let response = HTTPURLResponse(
            url: URL(string: "https://example.com")!,
            statusCode: 301,
            httpVersion: "HTTP/1.1",
            headerFields: ["Location": "https://redirected.com"]
        )!

        let request = URLRequest(url: URL(string: "https://redirected.com")!)

        var completionHandlerCalled = false
        var receivedRequest: URLRequest?

        defaultManager.urlSession(
            URLSession.shared,
            task: URLSessionDataTask(),
            willPerformHTTPRedirection: response,
            newRequest: request
        ) { request in
            completionHandlerCalled = true
            receivedRequest = request
        }

        #expect(completionHandlerCalled, "Completion handler should be called")
        #expect(receivedRequest == nil, "Should prevent redirects by returning nil")
    }

    // MARK: - Concurrent Request Tests

    @Test("Concurrent requests execution")
    func concurrentRequests() async throws {
        let urls = [
            URL(string: "https://example.com/delay/short1")!,
            URL(string: "https://example.com/delay/short2")!,
            URL(string: "https://example.com/delay/short3")!
        ]

        let manager = makeManager()

        let startTime = Date()

        // Run requests concurrently
        let responses = try await withThrowingTaskGroup(of: String.self) { group in
            for url in urls {
                group.addTask {
                    try await manager.get(url: url)
                }
            }

            var results: [String] = []
            for try await response in group {
                results.append(response)
            }
            return results
        }

        let totalTime = Date().timeIntervalSince(startTime)

        #expect(responses.count == 3, "Should receive 3 responses")
        #expect(totalTime < 1.0, "Concurrent requests should execute in parallel quickly")
        for response in responses {
            #expect(!response.isEmpty, "Response should not be empty")
            #expect(response.contains("ok"), "Response should contain mock marker")
        }
    }

    // MARK: - Error Handling Tests

    @Test("Network error handling")
    func networkErrorHandling() async {
        let url = URL(string: "https://example.com/unreachable")!
        let manager = makeManager()

        do {
            _ = try await manager.get(url: url)
            Issue.record("Expected network error")
        } catch {
            #expect(error != nil, "Should receive an error for unreachable URL")
        }
    }

    // MARK: - Content Type Tests

    @Test("POST request content type")
    func postRequestContentType() async throws {
        // Verify POST requests set the correct Content-Type header
        let url = URL(string: "https://example.com/post")!
        let body = "key=value&test=data"
        let manager = makeManager()

        let response = try await manager.post(url: url, body: body)
        #expect(response.contains("content-type=application/x-www-form-urlencoded"), "Response should echo correct content type")
    }

    // MARK: - Response Encoding Tests

    @Test("Response string encoding")
    func responseStringEncoding() async throws {
        // Test that responses are properly decoded as UTF-8 strings
        let url = URL(string: "https://example.com/encoding/utf8")!
        let manager = makeManager()

        let response = try await manager.get(url: url)

        #expect(!response.isEmpty, "Response should not be empty")
        #expect(response.data(using: .utf8) != nil, "Response should contain valid UTF-8 text")
    }
}
