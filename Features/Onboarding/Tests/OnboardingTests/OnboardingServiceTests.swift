//
//  OnboardingServiceTests.swift
//  OnboardingTests
//
//  Copyright © 2025 Weiran Zhang. All rights reserved.
//

import Testing
@testable import Onboarding

@MainActor
struct OnboardingServiceTests {
    @Test("Should show onboarding when forced")
    func shouldShowOnboardingWhenForced() {
        let mockStore = MockOnboardingVersionStore(hasShown: true)
        #expect(OnboardingService.shouldShowOnboarding(versionStore: mockStore, forceShow: true))
    }
    
    @Test("Should not show onboarding when already shown")
    func shouldNotShowOnboardingWhenAlreadyShown() {
        let mockStore = MockOnboardingVersionStore(hasShown: true)
        #expect(!OnboardingService.shouldShowOnboarding(versionStore: mockStore, forceShow: false))
    }
    
    @Test("Should show onboarding when not yet shown")
    func shouldShowOnboardingWhenNotYetShown() {
        let mockStore = MockOnboardingVersionStore(hasShown: false)
        #expect(OnboardingService.shouldShowOnboarding(versionStore: mockStore, forceShow: false))
    }
    
    @Test("Mark onboarding as shown")
    func markOnboardingAsShown() {
        let mockStore = MockOnboardingVersionStore(hasShown: false)
        OnboardingService.markOnboardingShown(versionStore: mockStore)
        #expect(mockStore.hasShownOnboarding())
    }
}

final class MockOnboardingVersionStore: OnboardingVersionStore {
    private var hasShown: Bool
    
    init(hasShown: Bool) {
        self.hasShown = hasShown
    }
    
    func hasShownOnboarding() -> Bool {
        hasShown
    }
    
    func markOnboardingShown() {
        hasShown = true
    }
}