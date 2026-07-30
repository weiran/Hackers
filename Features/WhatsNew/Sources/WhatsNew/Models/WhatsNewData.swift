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
        let threadedComments = WhatsNewItem(
            title: "Threaded Comment Guides",
            subtitle: "Comment replies now show clear visual guides so you can follow threads at a glance.",
            systemImage: "text.insert",
        )

        let ipadBrowser = WhatsNewItem(
            title: "Redesigned iPad Browser",
            subtitle: "The embedded browser gets a cleaner, more native toolbar that makes browsing stories on iPad feel right at home.",
            systemImage: "safari",
        )

        return WhatsNewData(
            title: "What's New in Hackers 5.4",
            items: [threadedComments, ipadBrowser],
        )
    }
}
