//
//  WhatsNewData.swift
//  Hackers
//
//  Copyright © 2025 Weiran Zhang. All rights reserved.
//

import Foundation

public struct WhatsNewData: Sendable {
    public let title: String
    public let items: [WhatsNewItem]

    public init(title: String, items: [WhatsNewItem]) {
        self.title = title
        self.items = items
    }

    public static func currentWhatsNew() -> WhatsNewData {
        let embeddedBrowser = WhatsNewItem(
            title: "Embedded Browser",
            subtitle: "Open stories inside Hackers and switch back to comments without losing your place.",
            systemImage: "safari",
        )

        let feedShortcuts = WhatsNewItem(
            title: "Feed Shortcuts",
            subtitle: "Tap a story's thumbnail to open the link, or tap the row to jump straight to comments.",
            systemImage: "hand.tap",
        )

        return WhatsNewData(
            title: "What's New in Hackers 5.3",
            items: [embeddedBrowser, feedShortcuts],
        )
    }
}
