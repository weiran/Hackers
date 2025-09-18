//
//  OnboardingRepository.swift
//  Data
//
//  Copyright © 2025 Weiran Zhang. All rights reserved.
//

import Domain
import Foundation

public protocol OnboardingVersionStore: Sendable {
    func hasShownOnboarding() -> Bool
    func markOnboardingShown()
}

public final class UserDefaultsOnboardingVersionStore: OnboardingVersionStore, @unchecked Sendable {
    private let userDefaults: UserDefaults
    private let key = "com.weiran.hackers.onboarding.shown"
    private nonisolated(unsafe) static var didResetSuite = false

    private init(storage: UserDefaults) {
        self.userDefaults = storage
    }

    public convenience init(userDefaults: UserDefaults) {
        self.init(storage: userDefaults)
    }

    public convenience init() {
        let suite = "com.weiran.hackers.onboarding"
        let defaults = UserDefaults(suiteName: suite) ?? .standard
        self.init(storage: defaults)

        if !Self.didResetSuite {
            defaults.removePersistentDomain(forName: suite)
            Self.didResetSuite = true
        }
    }

    public func hasShownOnboarding() -> Bool {
        userDefaults.bool(forKey: key)
    }

    public func markOnboardingShown() {
        userDefaults.set(true, forKey: key)
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

    public func shouldShowOnboarding(forceShow: Bool) -> Bool {
        if processArguments.contains("disableOnboarding"), !forceShow {
            return false
        }

        return forceShow || !versionStore.hasShownOnboarding()
    }

    public func markOnboardingShown() {
        versionStore.markOnboardingShown()
    }
}
