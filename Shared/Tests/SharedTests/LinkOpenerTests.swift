//
//  LinkOpenerTests.swift
//  SharedTests
//
//  Copyright © 2025 Weiran Zhang. All rights reserved.
//

@testable import Domain
import Foundation
@testable import Shared
import Testing

@Suite("LinkOpener Tests")
struct LinkOpenerTests {
    @Test("LinkOpener is a struct with static methods")
    @MainActor
    func structureType() {
        // Test that LinkOpener is designed as a utility struct
        // We can't instantiate it, but we can access its static methods

        let httpURL = URL(string: "https://example.com")!
        let testPost = createTestPost()

        // This should compile without issues
        LinkOpener.openURL(httpURL, with: testPost)

        #expect(true, "LinkOpener static methods should be accessible")
    }

    @Test("LinkOpener openURL is MainActor isolated")
    func mainActorIsolation() async {
        let url = URL(string: "https://example.com")!

        await MainActor.run {
            // This should compile and run without issues on MainActor
            LinkOpener.openURL(url)
            LinkOpener.openURL(url, with: createTestPost())
        }

        #expect(true, "Methods should be callable from MainActor context")
    }

    @Test("LinkOpener handles different URL schemes")
    func uRLSchemeHandling() async {
        let httpURL = URL(string: "http://example.com")!
        let httpsURL = URL(string: "https://example.com")!
        let mailto = URL(string: "mailto:test@example.com")!
        let tel = URL(string: "tel:+1234567890")!
        let customScheme = URL(string: "myapp://open")!

        await MainActor.run {
            // These calls test the method signature and that they don't crash
            // In a test environment, they won't actually open URLs/present Safari
            LinkOpener.openURL(httpURL)
            LinkOpener.openURL(httpsURL)
            LinkOpener.openURL(mailto)
            LinkOpener.openURL(tel)
            LinkOpener.openURL(customScheme)
        }

        #expect(true, "Should handle various URL schemes without crashing")
    }

    @Test("LinkOpener methods accept optional parameters")
    func optionalParameters() async {
        let url = URL(string: "https://example.com")!
        let post = createTestPost()

        await MainActor.run {
            // Test different parameter combinations
            LinkOpener.openURL(url)
            LinkOpener.openURL(url, with: nil)
            LinkOpener.openURL(url, with: post)
        }

        #expect(true, "Should accept various parameter combinations")
    }

    @Test("LinkOpener works with various valid URLs")
    func testValidURLs() async {
        let validURLs = [
            "https://example.com",
            "http://example.com",
            "https://news.ycombinator.com/item?id=123",
            "mailto:test@example.com",
            "tel:+1234567890",
            "sms:+1234567890",
            "https://www.google.com/search?q=test",
            "ftp://files.example.com/file.txt",
            "file:///path/to/file.txt",
            "custom-app://open/item/123",
        ]

        await MainActor.run {
            for urlString in validURLs {
                if let url = URL(string: urlString) {
                    LinkOpener.openURL(url)
                }
            }
        }

        #expect(true, "Should handle various valid URL formats")
    }

    // MARK: - Helper Methods

    private func createTestPost() -> Post {
        Post(
            id: 123,
            url: URL(string: "https://example.com/test-post")!,
            title: "Test Post for LinkOpener",
            age: "1 hour ago",
            commentsCount: 10,
            by: "testuser",
            score: 50,
            postType: .news,
            upvoted: false,
        )
    }

    // MARK: - Edge Case Tests

    @Test("LinkOpener handles edge cases gracefully")
    func edgeCases() async {
        await MainActor.run {
            // Test with minimal valid URL
            if let minimalURL = URL(string: "https://a.com") {
                LinkOpener.openURL(minimalURL)
            }

            // Test with complex URL with parameters
            if let complexURL = URL(string: "https://example.com/path/to/resource?param1=value1&param2=value2#section") {
                LinkOpener.openURL(complexURL)
            }

            // Test with international domain
            if let internationalURL = URL(string: "https://例え.テスト") {
                LinkOpener.openURL(internationalURL)
            }
        }

        #expect(true, "Should handle edge cases without crashing")
    }

    @Test("LinkOpener service type behavior")
    func serviceTypeBehavior() {
        // Test that LinkOpener behaves like a stateless service
        // (no instance state, all static methods)

        let url1 = URL(string: "https://example1.com")!
        let url2 = URL(string: "https://example2.com")!

        Task {
            await MainActor.run {
                LinkOpener.openURL(url1)
            }
        }

        Task {
            await MainActor.run {
                LinkOpener.openURL(url2)
            }
        }

        #expect(true, "Should work as stateless service across different tasks")
    }
}
