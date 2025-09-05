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
        let userDefaults = UserDefaults()
        userDefaults.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)

        let store = UserDefaultsOnboardingVersionStore(userDefaults: userDefaults)
        #expect(!store.hasShownOnboarding())
    }

    @Test("Marking as shown persists state")
    func markingAsShownPersistsState() {
        let userDefaults = UserDefaults()
        userDefaults.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)

        let store = UserDefaultsOnboardingVersionStore(userDefaults: userDefaults)
        store.markOnboardingShown()

        #expect(store.hasShownOnboarding())

        let newStore = UserDefaultsOnboardingVersionStore(userDefaults: userDefaults)
        #expect(newStore.hasShownOnboarding())
    }
}
