//
//  SimpleCommentsTests.swift
//  CommentsTests
//
//  Copyright © 2025 Weiran Zhang. All rights reserved.
//

@testable import Comments
import Foundation
import Testing

@Suite("Comments Module Tests")
struct SimpleCommentsTests {
    @Suite("Comments Link Navigator")
    struct LinkNavigatorTests {
        @Test("Extracts Hacker News item id from valid URL")
        func extractsItemId() {
            // Given
            let url = URL(string: "https://news.ycombinator.com/item?id=12345&ref=test")!

            // When
            let itemId = CommentsLinkNavigator.hackerNewsItemID(from: url)

            // Then
            #expect(itemId == 12345)
        }

        @Test("Returns nil for non-item Hacker News URLs")
        func ignoresNonItemURLs() {
            // Given
            let userURL = URL(string: "https://news.ycombinator.com/user?id=test")!
            let externalURL = URL(string: "https://example.com/item?id=12345")!

            // When
            let userItemId = CommentsLinkNavigator.hackerNewsItemID(from: userURL)
            let externalItemId = CommentsLinkNavigator.hackerNewsItemID(from: externalURL)

            // Then
            #expect(userItemId == nil)
            #expect(externalItemId == nil)
        }
    }
}
