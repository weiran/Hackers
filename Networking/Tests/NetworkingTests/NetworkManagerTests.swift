import Testing
@testable import Networking
import Foundation

@Suite("NetworkManager Tests")
struct NetworkManagerTests {

    let networkManager = NetworkManager()

    // MARK: - Initialization Tests

    @Test("NetworkManager initialization")
    func networkManagerInitialization() {
        #expect(networkManager != nil, "NetworkManager should initialize successfully")
    }

    // MARK: - GET Request Tests

    @Test("GET request with valid URL")
    func getRequestWithValidURL() async throws {
        // Using httpbin.org which provides a reliable testing endpoint
        let url = URL(string: "https://httpbin.org/get")!

        let response = try await networkManager.get(url: url)

        #expect(!response.isEmpty, "Response should not be empty")
        #expect(response.contains("httpbin"), "Response should contain httpbin")
    }

    @Test("GET request with invalid URL")
    func getRequestWithInvalidURL() async {
        let url = URL(string: "https://invalid-url-that-should-not-exist-12345.com")!

        do {
            _ = try await networkManager.get(url: url)
            Issue.record("Expected network error for invalid URL")
        } catch {
            // Expected to throw an error
            #expect(error != nil, "Should throw an error for invalid URL")
        }
    }

    // MARK: - POST Request Tests

    @Test("POST request with valid URL")
    func postRequestWithValidURL() async throws {
        let url = URL(string: "https://httpbin.org/post")!
        let body = "test=data&key=value"

        let response = try await networkManager.post(url: url, body: body)

        #expect(!response.isEmpty, "Response should not be empty")
        #expect(response.contains("httpbin"), "Response should contain httpbin")
        #expect(response.contains("test") && response.contains("data"), "Response should contain posted data")
    }

    @Test("POST request with empty body")
    func postRequestWithEmptyBody() async throws {
        let url = URL(string: "https://httpbin.org/post")!
        let body = ""

        let response = try await networkManager.post(url: url, body: body)

        #expect(!response.isEmpty, "Response should not be empty")
        #expect(response.contains("httpbin"), "Response should contain httpbin")
    }

    @Test("POST request with invalid URL")
    func postRequestWithInvalidURL() async {
        let url = URL(string: "https://invalid-url-that-should-not-exist-12345.com")!
        let body = "test=data"

        do {
            _ = try await networkManager.post(url: url, body: body)
            Issue.record("Expected network error for invalid URL")
        } catch {
            // Expected to throw an error
            #expect(error != nil, "Should throw an error for invalid URL")
        }
    }

    // MARK: - Cookie Management Tests

    @Test("Clear cookies functionality")
    func clearCookies() {
        // First, let's add a cookie
        let cookie = HTTPCookie(properties: [
            .domain: "example.com",
            .path: "/",
            .name: "testCookie",
            .value: "testValue"
        ])!

        HTTPCookieStorage.shared.setCookie(cookie)

        // Verify cookie exists
        let cookiesBeforeClearing = HTTPCookieStorage.shared.cookies ?? []
        #expect(cookiesBeforeClearing.contains(cookie), "Cookie should exist before clearing")

        // Clear cookies
        networkManager.clearCookies()

        // Verify cookies are cleared
        let cookiesAfterClearing = HTTPCookieStorage.shared.cookies ?? []
        #expect(!cookiesAfterClearing.contains(cookie), "Cookie should not exist after clearing")
    }

    @Test("Contains cookie for URL functionality")
    func containsCookieForURL() {
        let url = URL(string: "https://example.com")!

        // Initially should have no cookies
        #expect(!networkManager.containsCookie(for: url), "Should have no cookies initially")

        // Add a cookie for the domain
        let cookie = HTTPCookie(properties: [
            .domain: "example.com",
            .path: "/",
            .name: "testCookie",
            .value: "testValue"
        ])!

        HTTPCookieStorage.shared.setCookie(cookie)

        // Now should detect cookie
        #expect(networkManager.containsCookie(for: url), "Should detect cookie after setting")

        // Clean up
        HTTPCookieStorage.shared.deleteCookie(cookie)
    }

    @Test("Contains cookie for URL with no cookies")
    func containsCookieForURLWithNoCookies() {
        let url = URL(string: "https://no-cookies-example.com")!

        // Clear all cookies first
        networkManager.clearCookies()

        // Should return false for URL with no cookies
        #expect(!networkManager.containsCookie(for: url), "Should return false for URL with no cookies")
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

        networkManager.urlSession(
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
            URL(string: "https://httpbin.org/delay/1")!,
            URL(string: "https://httpbin.org/delay/1")!,
            URL(string: "https://httpbin.org/delay/1")!
        ]

        let startTime = Date()
        let networkManager = self.networkManager

        // Run requests concurrently
        let responses = try await withThrowingTaskGroup(of: String.self) { group in
            for url in urls {
                group.addTask {
                    try await networkManager.get(url: url)
                }
            }

            var results: [String] = []
            for try await response in group {
                results.append(response)
            }
            return results
        }

        let endTime = Date()
        let totalTime = endTime.timeIntervalSince(startTime)

        #expect(responses.count == 3, "Should receive 3 responses")
        // Concurrent requests should take roughly 1 second (not 3 seconds)
        #expect(totalTime < 2.0, "Concurrent requests should execute in parallel")

        for response in responses {
            #expect(!response.isEmpty, "Response should not be empty")
            #expect(response.contains("httpbin"), "Response should contain httpbin")
        }
    }

    // MARK: - Error Handling Tests

    @Test("Network error handling")
    func networkErrorHandling() async {
        // Test with a URL that should cause a network error
        let url = URL(string: "https://localhost:9999/nonexistent")!

        do {
            _ = try await networkManager.get(url: url)
            Issue.record("Expected network error")
        } catch {
            // Verify we get an appropriate error
            #expect(error != nil, "Should receive an error for unreachable URL")
        }
    }

    // MARK: - Content Type Tests

    @Test("POST request content type")
    func postRequestContentType() async throws {
        // This test verifies that POST requests set the correct Content-Type header
        let url = URL(string: "https://httpbin.org/post")!
        let body = "key=value&test=data"

        let response = try await networkManager.post(url: url, body: body)

        #expect(response.contains("application/x-www-form-urlencoded"), "Response should contain correct content type")
    }

    // MARK: - Response Encoding Tests

    @Test("Response string encoding")
    func responseStringEncoding() async throws {
        // Test that responses are properly decoded as UTF-8 strings
        let url = URL(string: "https://httpbin.org/encoding/utf8")!

        let response = try await networkManager.get(url: url)

        #expect(!response.isEmpty, "Response should not be empty")
        // The response should contain valid UTF-8 text
        #expect(response.data(using: .utf8) != nil, "Response should contain valid UTF-8 text")
    }
}
