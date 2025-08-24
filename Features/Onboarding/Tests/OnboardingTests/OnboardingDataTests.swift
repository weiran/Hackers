//
//  OnboardingDataTests.swift
//  OnboardingTests
//
//  Copyright © 2025 Weiran Zhang. All rights reserved.
//

import Testing
@testable import Onboarding

struct OnboardingDataTests {
    @Test("Current onboarding data contains expected items")
    func currentOnboardingData() {
        let data = OnboardingData.currentOnboarding()

        #expect(data.title == "What's New in Hackers")
        #expect(data.items.count == 2)
        #expect(data.items.contains { $0.title.contains("Active Category") })
        #expect(data.items.contains { $0.title.contains("Stability") })
    }

    @Test("OnboardingItem has proper initialization")
    func onboardingItemInitialization() {
        let item = OnboardingItem(
            title: "Test Title",
            subtitle: "Test Subtitle",
            systemImage: "star"
        )

        #expect(item.title == "Test Title")
        #expect(item.subtitle == "Test Subtitle")
        #expect(item.systemImage == "star")
        #expect(!item.id.uuidString.isEmpty)
    }
}
