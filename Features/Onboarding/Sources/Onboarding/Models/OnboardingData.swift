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
        let embeddedBrowser = OnboardingItem(
            title: "Embedded iPad Browser",
            subtitle: "Browse articles right beside the feed with the new split-view web experience for faster reading.",
            systemImage: "safari.fill",
        )

        return OnboardingData(
            title: "What's New in Hackers 5.1",
            items: [embeddedBrowser],
        )
    }
}
