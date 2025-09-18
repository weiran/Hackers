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
        let store = MockStore(lastShownVersion: "5.0")
        let repository = OnboardingRepository(versionStore: store, processArguments: [])
        #expect(repository.shouldShowOnboarding(currentVersion: "5.1", forceShow: true))
    }

    @Test("Disable argument prevents onboarding when not forced")
    func disableArgumentPreventsOnboarding() {
        let repository = OnboardingRepository(versionStore: MockStore(lastShownVersion: nil), processArguments: ["disableOnboarding"])
        #expect(repository.shouldShowOnboarding(currentVersion: "5.1", forceShow: false) == false)
    }

    @Test("Shows when onboarding not yet displayed")
    func showsWhenNotDisplayed() {
        let repository = OnboardingRepository(versionStore: MockStore(lastShownVersion: nil), processArguments: [])
        #expect(repository.shouldShowOnboarding(currentVersion: "5.1", forceShow: false))
    }

    @Test("Marks onboarding as shown")
    func marksOnboardingAsShown() {
        let store = MockStore(lastShownVersion: nil)
        let repository = OnboardingRepository(versionStore: store, processArguments: [])
        repository.markOnboardingShown(for: "5.1")
        #expect(store.lastShownVersion() == "5.1")
    }

    @Test("UserDefaults store defaults to false")
    func userDefaultsStoreDefaultsToFalse() {
        let defaults = makeIsolatedDefaults()
        let store = UserDefaultsOnboardingVersionStore(userDefaults: defaults)
        #expect(store.lastShownVersion() == nil)
    }

    @Test("UserDefaults store records shown state")
    func userDefaultsStoreRecordsShownState() {
        let defaults = makeIsolatedDefaults()
        let store = UserDefaultsOnboardingVersionStore(userDefaults: defaults)
        store.save(shownVersion: "5.1")
        #expect(store.lastShownVersion() == "5.1")
    }

    final class MockStore: OnboardingVersionStore, @unchecked Sendable {
        private var storedVersion: String?
        init(lastShownVersion: String?) {
            self.storedVersion = lastShownVersion
        }

        func lastShownVersion() -> String? {
            storedVersion
        }

        func save(shownVersion: String) {
            storedVersion = shownVersion
        }
    }

    private func makeIsolatedDefaults() -> UserDefaults {
        let suiteName = "com.weiran.hackers.tests.onboarding.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            fatalError("Expected to create user defaults for suite \(suiteName)")
        }
        defaults.removePersistentDomain(forName: suiteName)
        defaults.synchronize()
        return defaults
    }
}
