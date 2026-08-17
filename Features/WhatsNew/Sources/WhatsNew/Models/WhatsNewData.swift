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
        let embeddedBrowserMedia = WhatsNewItem(
            title: "Embedded Browser Media Stays Quiet",
            subtitle: "Audio and video in the embedded browser no longer start playing automatically.",
            systemImage: "pause.circle.fill",
        )

        return WhatsNewData(
            title: "What's New in Hackers 5.4.1",
            items: [embeddedBrowserMedia],
        )
    }
}
