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
        let swiftUIRewrite = OnboardingItem(
            title: "Complete SwiftUI Rewrite",
            subtitle: "Entirely rebuilt from the ground up with modern SwiftUI " +
                "and clean architecture for the best experience.",
            systemImage: "hammer.fill",
        )
        let votingSystem = OnboardingItem(
            title: "Enhanced Voting System",
            subtitle: "Redesigned voting interface with improved visual feedback " +
                "and consistent behavior across the app.",
            systemImage: "arrow.up.circle",
        )
        let textSize = OnboardingItem(
            title: "Customizable Text Size",
            subtitle: "New app-wide text size control with 5 scaling options. Adjust text size in Settings.",
            systemImage: "textformat.size",
        )
        let performance = OnboardingItem(
            title: "Performance Improvements",
            subtitle: "Complete app modernization with clean architecture for faster loading and smoother navigation.",
            systemImage: "speedometer",
        )

        return OnboardingData(
            title: "What's New in Hackers 5.0",
            items: [swiftUIRewrite, votingSystem, textSize, performance],
        )
    }
}
