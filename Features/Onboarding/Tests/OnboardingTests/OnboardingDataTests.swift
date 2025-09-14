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

        #expect(data.title == "What's New in Hackers 5.0")
        #expect(data.items.count == 4)
        #expect(data.items.contains { $0.title.contains("SwiftUI Rewrite") })
        #expect(data.items.contains { $0.title.contains("Enhanced Voting") })
        #expect(data.items.contains { $0.title.contains("Customizable Text Size") })
        #expect(data.items.contains { $0.title.contains("Performance Improvements") })
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
