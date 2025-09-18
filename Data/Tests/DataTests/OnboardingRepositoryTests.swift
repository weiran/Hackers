//
//  OnboardingRepositoryTests.swift
//  DataTests
//
//  Copyright © 2025 Weiran Zhang. All rights reserved.
//

@testable import Data
import Foundation
import Testing

@Suite("OnboardingRepository")
struct OnboardingRepositoryTests {
    @Test("Force show overrides stored state")
    func forceShowOverridesStoredState() {
        let store = MockStore(hasShown: true)
        let repository = OnboardingRepository(versionStore: store, processArguments: [])
        #expect(repository.shouldShowOnboarding(forceShow: true))
    }

    @Test("Disable argument prevents onboarding when not forced")
    func disableArgumentPreventsOnboarding() {
        let repository = OnboardingRepository(versionStore: MockStore(hasShown: false), processArguments: ["disableOnboarding"])
        #expect(repository.shouldShowOnboarding(forceShow: false) == false)
    }

    @Test("Shows when onboarding not yet displayed")
    func showsWhenNotDisplayed() {
        let repository = OnboardingRepository(versionStore: MockStore(hasShown: false), processArguments: [])
        #expect(repository.shouldShowOnboarding(forceShow: false))
    }

    @Test("Marks onboarding as shown")
    func marksOnboardingAsShown() {
        let store = MockStore(hasShown: false)
        let repository = OnboardingRepository(versionStore: store, processArguments: [])
        repository.markOnboardingShown()
        #expect(store.hasShownOnboarding())
    }

    @Test("UserDefaults store defaults to false")
    func userDefaultsStoreDefaultsToFalse() {
        let suiteName = "com.weiran.hackers.tests.onboarding"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        let store = UserDefaultsOnboardingVersionStore(userDefaults: defaults)
        #expect(store.hasShownOnboarding() == false)
    }

    @Test("UserDefaults store records shown state")
    func userDefaultsStoreRecordsShownState() {
        let suiteName = "com.weiran.hackers.tests.onboarding"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        let store = UserDefaultsOnboardingVersionStore(userDefaults: defaults)
        store.markOnboardingShown()
        #expect(store.hasShownOnboarding())
    }

    final class MockStore: OnboardingVersionStore, @unchecked Sendable {
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
}
