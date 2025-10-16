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
        let rememberedFeed = OnboardingItem(
            title: "Remembers Your Feed",
            subtitle: "Hackers reopens in the last section you read so you never lose your place.",
            systemImage: "list.bullet.rectangle",
        )

        let thumbnailToggle = OnboardingItem(
            title: "Feed Thumbnails Toggle",
            subtitle: "Choose whether story thumbnails appear in the feed.",
            systemImage: "photo.on.rectangle",
        )

        return OnboardingData(
            title: "What's New in Hackers 5.2",
            items: [rememberedFeed, thumbnailToggle],
        )
    }
}
