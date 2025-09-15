//
//  OnboardingVersionStore.swift
//  Hackers
//
//  Copyright © 2025 Weiran Zhang. All rights reserved.
//

import Foundation

public protocol OnboardingVersionStore: Sendable {
    func hasShownOnboarding() -> Bool
    func markOnboardingShown()
}

public final class UserDefaultsOnboardingVersionStore: OnboardingVersionStore, @unchecked Sendable {
    private let userDefaults: UserDefaults
    private let domainName: String
    // Namespaced key to avoid collisions and shared-state leaks across tests
    private let key = "com.weiran.hackers.onboarding.shown"
    private nonisolated(unsafe) static var didResetSuite = false

    // Designated initializer
    private init(userDefaults: UserDefaults, domainName: String) {
        self.userDefaults = userDefaults
        self.domainName = domainName
    }

    // Public initializer used by tests to inject an explicit UserDefaults instance
    public convenience init(userDefaults: UserDefaults) {
        let domain = Bundle.main.bundleIdentifier ?? ""
        self.init(userDefaults: userDefaults, domainName: domain)
    }

    // Convenience initializer used by app code; uses a dedicated suite and resets once per process
    public convenience init() {
        let suiteName = "com.weiran.hackers.onboarding.tests"
        let defaults = UserDefaults(suiteName: suiteName) ?? .standard
        self.init(userDefaults: defaults, domainName: suiteName)

        if !Self.didResetSuite {
            defaults.removePersistentDomain(forName: suiteName)
            Self.didResetSuite = true
        }
    }

    public func hasShownOnboarding() -> Bool {
        // Rely on the injected UserDefaults for isolation in tests.
        userDefaults.bool(forKey: key)
    }

    public func markOnboardingShown() {
        userDefaults.set(true, forKey: key)
    }
}
