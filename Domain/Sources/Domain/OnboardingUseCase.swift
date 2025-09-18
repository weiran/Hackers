//
//  OnboardingUseCase.swift
//  Domain
//
//  Copyright © 2025 Weiran Zhang. All rights reserved.
//

import Foundation

public protocol OnboardingUseCase: Sendable {
    func shouldShowOnboarding(forceShow: Bool) -> Bool
    func markOnboardingShown()
}
