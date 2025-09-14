//
//  UserDefaultsOnboardingVersionStoreTests.swift
//  OnboardingTests
//
//  Copyright © 2025 Weiran Zhang. All rights reserved.
//

import Testing
import Foundation
@testable import Onboarding

struct UserDefaultsOnboardingVersionStoreTests {
    @Test("Initial state returns false")
    func initialStateReturnsFalse() {
        // Use a dedicated test suite to avoid interference
        let testSuiteName = "com.weiran.hackers.onboarding.tests.isolated.\(UUID().uuidString)"
        let userDefaults = UserDefaults(suiteName: testSuiteName) ?? UserDefaults()

        // Clean up any existing data
        userDefaults.removeObject(forKey: "com.weiran.hackers.onboarding.shown")

        let store = UserDefaultsOnboardingVersionStore(userDefaults: userDefaults)
        #expect(!store.hasShownOnboarding())
    }

    @Test("Marking as shown persists state")
    func markingAsShownPersistsState() {
        // Use a dedicated test suite to avoid interference
        let testSuiteName = "com.weiran.hackers.onboarding.tests.isolated.\(UUID().uuidString)"
        let userDefaults = UserDefaults(suiteName: testSuiteName) ?? UserDefaults()

        // Clean up any existing data
        userDefaults.removeObject(forKey: "com.weiran.hackers.onboarding.shown")

        let store = UserDefaultsOnboardingVersionStore(userDefaults: userDefaults)
        store.markOnboardingShown()

        #expect(store.hasShownOnboarding())

        let newStore = UserDefaultsOnboardingVersionStore(userDefaults: userDefaults)
        #expect(newStore.hasShownOnboarding())
    }
}
