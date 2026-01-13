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

        #expect(data.title == "What's New in Hackers 5.3")
        #expect(data.items.count == 2)
        #expect(data.items.contains { $0.title == "Embedded Browser" })
        #expect(data.items.contains { $0.title == "Comments Drawer" })
        #expect(data.items.contains {
            $0.subtitle == "Swipe up to read comments while the article stays loaded, with quick back, forward, reload, and share controls."
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
