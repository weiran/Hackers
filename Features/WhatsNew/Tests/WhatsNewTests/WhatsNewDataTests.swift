//
//  WhatsNewDataTests.swift
//  WhatsNewTests
//
//  Copyright © 2025 Weiran Zhang. All rights reserved.
//

@testable import WhatsNew
import Testing

struct WhatsNewDataTests {
    @Test("Current whats new data contains expected items")
    func currentWhatsNewData() {
        let data = WhatsNewData.currentWhatsNew()

        let expectedItems: [(title: String, subtitle: String, systemImage: String)] = [
            (
                "Join the Conversation",
                "Share your take on any story with the new comment composer, right where you read.",
                "text.bubble.fill"
            ),
            (
                "Reply to Comments",
                "Dive into threads and reply to any comment to keep the discussion going.",
                "arrowshape.turn.up.left.fill"
            ),
            (
                "Swipe to Collapse Threads",
                "Swipe on a comment to collapse its whole thread — a favorite gesture is back.",
                "chevron.up.chevron.down"
            ),
        ]

        #expect(data.title == "What's New in Hackers 5.5")
        #expect(data.items.count == expectedItems.count)

        for expected in expectedItems {
            #expect(data.items.contains {
                $0.title == expected.title &&
                    $0.subtitle == expected.subtitle &&
                    $0.systemImage == expected.systemImage
            })
        }
    }

    @Test("WhatsNewItem has proper initialization")
    func whatsNewItemInitialization() {
        let item = WhatsNewItem(
            title: "Test Title",
            subtitle: "Test Subtitle",
            systemImage: "star",
        )

        #expect(item.title == "Test Title")
        #expect(item.subtitle == "Test Subtitle")
        #expect(item.systemImage == "star")
        #expect(!item.id.uuidString.isEmpty)
    }
}
