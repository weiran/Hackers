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
                "iPhone Duo Support",
                "Support for iPhone Duo’s distinctive design.",
                "rectangle.split.2x1"
            ),
        ]

        #expect(data.title == "What's New in Hackers 5.6")
        #expect(data.items.count == expectedItems.count)

        for expected in expectedItems {
            #expect(data.items.contains {
                $0.title == expected.title &&
                    $0.subtitle == expected.subtitle &&
                    $0.systemImage == expected.systemImage
            })
        }
    }
}
