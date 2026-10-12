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
        let duoSupport = WhatsNewItem(
            title: "iPhone Duo Support",
            subtitle: "Support for iPhone Duo’s distinctive design.",
            systemImage: "rectangle.split.2x1",
        )

        return WhatsNewData(
            title: "What's New in Hackers 5.6",
            items: [duoSupport],
        )
    }
}
