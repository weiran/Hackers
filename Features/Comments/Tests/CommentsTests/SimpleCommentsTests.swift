//
//  SimpleCommentsTests.swift
//  CommentsTests
//
//  Copyright © 2025 Weiran Zhang. All rights reserved.
//

@testable import Comments
import Foundation
import SwiftUI
import Testing

@Suite("Comments Module Tests")
struct SimpleCommentsTests {
    @Suite("Scroll drag start eligibility")
    struct ScrollDragStartEligibilityTests {
        @Test("Allows a new drag from an idle scroll settled at the top")
        func allowsSettledTopDrag() {
            let isEligible = CommentsScrollDragStartEligibility.updatedValue(
                currentValue: false,
                oldPhase: .idle,
                newPhase: .tracking,
                isAtTop: true
            )

            #expect(isEligible)
        }

        @Test("Rejects a new drag while away from the top")
        func rejectsDragAwayFromTop() {
            let isEligible = CommentsScrollDragStartEligibility.updatedValue(
                currentValue: false,
                oldPhase: .idle,
                newPhase: .tracking,
                isAtTop: false
            )

            #expect(!isEligible)
        }

        @Test("Rejects a drag that interrupts deceleration at the top")
        func rejectsDragDuringDeceleration() {
            let isEligible = CommentsScrollDragStartEligibility.updatedValue(
                currentValue: false,
                oldPhase: .decelerating,
                newPhase: .tracking,
                isAtTop: true
            )

            #expect(!isEligible)
        }

        @Test("Keeps an eligible drag latched while the scroll is interacting")
        func keepsEligibilityDuringInteraction() {
            let isEligible = CommentsScrollDragStartEligibility.updatedValue(
                currentValue: true,
                oldPhase: .tracking,
                newPhase: .interacting,
                isAtTop: true
            )

            #expect(isEligible)
        }

        @Test("Clears eligibility when scrolling settles")
        func clearsEligibilityWhenIdle() {
            let isEligible = CommentsScrollDragStartEligibility.updatedValue(
                currentValue: true,
                oldPhase: .interacting,
                newPhase: .idle,
                isAtTop: true
            )

            #expect(!isEligible)
        }
    }

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
