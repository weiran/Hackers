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
    private let key = "OnboardingShown"
    
    public init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }
    
    public func hasShownOnboarding() -> Bool {
        userDefaults.bool(forKey: key)
    }
    
    public func markOnboardingShown() {
        userDefaults.set(true, forKey: key)
    }
}