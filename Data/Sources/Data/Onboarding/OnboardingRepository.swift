//
//  OnboardingRepository.swift
//  Data
//
//  Copyright © 2025 Weiran Zhang. All rights reserved.
//

import Domain
import Foundation

public protocol OnboardingVersionStore: Sendable {
    func lastShownVersion() -> String?
    func save(shownVersion: String)
}

public final class UserDefaultsOnboardingVersionStore: OnboardingVersionStore, @unchecked Sendable {
    private let userDefaults: UserDefaults
    private let key = "com.weiran.hackers.onboarding.shownVersion"

    private init(storage: UserDefaults) {
        userDefaults = storage
    }

    public convenience init(userDefaults: UserDefaults) {
        self.init(storage: userDefaults)
    }

    public convenience init() {
        let suite = "com.weiran.hackers.onboarding"
        let defaults = UserDefaults(suiteName: suite) ?? .standard
        self.init(storage: defaults)
    }

    public func lastShownVersion() -> String? {
        userDefaults.string(forKey: key)
    }

    public func save(shownVersion: String) {
        userDefaults.set(shownVersion, forKey: key)
    }
}

public final class OnboardingRepository: OnboardingUseCase, @unchecked Sendable {
    private let versionStore: OnboardingVersionStore
    private let processArguments: [String]

    public init(
        versionStore: OnboardingVersionStore = UserDefaultsOnboardingVersionStore(),
        processArguments: [String] = ProcessInfo.processInfo.arguments
    ) {
        self.versionStore = versionStore
        self.processArguments = processArguments
    }

    public func shouldShowOnboarding(currentVersion: String, forceShow: Bool) -> Bool {
        if processArguments.contains("disableOnboarding"), !forceShow {
            return false
        }

        if forceShow { return true }

        return versionStore.lastShownVersion() != currentVersion
    }

    public func markOnboardingShown(for version: String) {
        versionStore.save(shownVersion: version)
    }
}
