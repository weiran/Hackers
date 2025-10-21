//
//  OnboardingData.swift
//  Hackers
//
//  Copyright © 2025 Weiran Zhang. All rights reserved.
//

import Foundation

public struct OnboardingData: Sendable {
    public let title: String
    public let items: [OnboardingItem]

    public init(title: String, items: [OnboardingItem]) {
        self.title = title
        self.items = items
    }

    public static func currentOnboarding() -> OnboardingData {
        let smarterSearch = OnboardingItem(
            title: "Smarter Search & Feed",
            subtitle: "Find stories faster with Algolia search, remembered categories, and thumbnail controls.",
            systemImage: "magnifyingglass.circle",
        )

        let syncedBookmarks = OnboardingItem(
            title: "Synced Bookmarks",
            subtitle: "Save favourites across devices with shared bookmarks and smoother comments & feed updates.",
            systemImage: "bookmark.circle",
        )

        let supporterTips = OnboardingItem(
            title: "Support the Developer",
            subtitle: "Visit Settings to tip or subscribe, keep Hackers improving, and help the app stay free.",
            systemImage: "heart.circle",
        )

        return OnboardingData(
            title: "What's New in Hackers 5.2",
            items: [smarterSearch, syncedBookmarks, supporterTips],
        )
    }
}
