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
            subtitle: "Open stories inside Hackers with a built-in browser so you stay in the flow.",
            systemImage: "safari",
        )

        let commentsDrawer = WhatsNewItem(
            title: "Comments Drawer",
            subtitle: "Swipe up to read comments while the article stays loaded, with quick "
                + "back, forward, reload, and share controls.",
            systemImage: "bubble.left.and.bubble.right",
        )

        return WhatsNewData(
            title: "What's New in Hackers 5.3",
            items: [embeddedBrowser, commentsDrawer],
        )
    }
}
