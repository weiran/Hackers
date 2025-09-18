//
//  OnboardingUseCase.swift
//  Domain
//
//  Copyright © 2025 Weiran Zhang. All rights reserved.
//

import Foundation

public protocol OnboardingUseCase: Sendable {
    func shouldShowOnboarding(currentVersion: String, forceShow: Bool) -> Bool
    func markOnboardingShown(for version: String)
}
