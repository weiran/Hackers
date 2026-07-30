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

        #expect(data.title == "What's New in Hackers 5.4")
        #expect(data.items.count == 2)
        #expect(data.items.contains { $0.title == "Threaded Comment Guides" })
        #expect(data.items.contains { $0.title == "Redesigned iPad Browser" })
        #expect(data.items.contains {
            $0.subtitle == "Comment replies now show clear visual guides so you can follow threads at a glance."
        })
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
