//
//  OnboardingDataTests.swift
//  OnboardingTests
//
//  Copyright © 2025 Weiran Zhang. All rights reserved.
//

@testable import Onboarding
import Testing

struct OnboardingDataTests {
    @Test("Current onboarding data contains expected items")
    func currentOnboardingData() {
        let data = OnboardingData.currentOnboarding()

        #expect(data.title == "What's New in Hackers 5.2.1")
        #expect(data.items.count == 2)
        #expect(data.items.contains { $0.title == "Compact Feed Design" })
        #expect(data.items.contains { $0.title == "Unvote Your Upvotes" })
        #expect(data.items.contains {
            $0.subtitle == "Choose a streamlined feed layout with inline upvote and comment counts for a cleaner reading experience."
        })
    }

    @Test("OnboardingItem has proper initialization")
    func onboardingItemInitialization() {
        let item = OnboardingItem(
            title: "Test Title",
            subtitle: "Test Subtitle",
            systemImage: "star",
        )

        #expect(item.title == "Test Title")
        #expect(item.subtitle == "Test Subtitle")
        #expect(item.systemImage == "star")
        #expect(!item.id.uuidString.isEmpty)
    }
}
