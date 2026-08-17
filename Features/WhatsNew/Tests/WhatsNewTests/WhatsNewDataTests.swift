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

        #expect(data.title == "What's New in Hackers 5.4.1")
        #expect(data.items.count == 1)
        #expect(data.items.contains { $0.title == "Embedded Browser Media Stays Quiet" })
        #expect(data.items.contains {
            $0.subtitle == "Audio and video in the embedded browser no longer start playing automatically."
        })
        #expect(data.items.contains { $0.systemImage == "pause.circle.fill" })
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
