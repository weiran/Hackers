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
        let compactFeed = OnboardingItem(
            title: "Compact Feed Design",
            subtitle: "Choose a streamlined feed layout with inline upvote and comment counts for a cleaner reading experience.",
            systemImage: "rectangle.compress.vertical",
        )

        let unvoteFeature = OnboardingItem(
            title: "Unvote Your Upvotes",
            subtitle: "Changed your mind? Remove upvotes from posts and comments within Hacker News's 1-hour window.",
            systemImage: "arrow.uturn.down.circle",
        )

        return OnboardingData(
            title: "What's New in Hackers 5.2.1",
            items: [compactFeed, unvoteFeature],
        )
    }
}
