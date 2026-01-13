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
        let compactFeed = WhatsNewItem(
            title: "Compact Feed Design",
            subtitle: "Choose a streamlined feed layout with inline upvote and comment counts "
                + "for a cleaner reading experience.",
            systemImage: "rectangle.compress.vertical",
        )

        let unvoteFeature = WhatsNewItem(
            title: "Unvote Your Upvotes",
            subtitle: "Changed your mind? Remove upvotes from posts and comments within "
                + "Hacker News's 1-hour window.",
            systemImage: "arrow.uturn.down.circle",
        )

        return WhatsNewData(
            title: "What's New in Hackers 5.2.1",
            items: [compactFeed, unvoteFeature],
        )
    }
}
