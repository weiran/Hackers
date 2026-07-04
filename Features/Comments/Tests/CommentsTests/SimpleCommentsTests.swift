//
//  SimpleCommentsTests.swift
//  CommentsTests
//
//  Copyright © 2025 Weiran Zhang. All rights reserved.
//

@testable import Comments
import CoreGraphics
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

    @Suite("Collapse Scroll Visibility")
    struct CollapseScrollVisibilityTests {
        @Test("Treats root top inside visible bounds as visible")
        func rootTopInsideVisibleBounds() {
            let frame = CGRect(x: 0, y: 140, width: 320, height: 52)
            let visibleRect = CGRect(x: 0, y: 100, width: 320, height: 500)

            #expect(CollapseScrollVisibility.isRootTopVisible(frame: frame, visibleRect: visibleRect))
        }

        @Test("Treats root top above or below visible bounds as outside")
        func rootTopOutsideVisibleBounds() {
            let visibleRect = CGRect(x: 0, y: 100, width: 320, height: 500)
            let aboveFrame = CGRect(x: 0, y: 80, width: 320, height: 52)
            let belowFrame = CGRect(x: 0, y: 600, width: 320, height: 52)

            #expect(!CollapseScrollVisibility.isRootTopVisible(frame: aboveFrame, visibleRect: visibleRect))
            #expect(!CollapseScrollVisibility.isRootTopVisible(frame: belowFrame, visibleRect: visibleRect))
        }

        @Test("Allows unresolved layout without forcing a scroll")
        func unresolvedLayoutIsVisible() {
            let frame = CGRect(x: 0, y: 120, width: 320, height: 52)

            #expect(CollapseScrollVisibility.isRootTopVisible(frame: frame, visibleRect: .zero))
        }
    }
}
