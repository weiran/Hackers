//
//  OnboardingCoordinator.swift
//  Hackers
//
//  Copyright © 2025 Weiran Zhang. All rights reserved.
//

import Domain
import Onboarding
import SwiftUI

@MainActor
final class OnboardingCoordinator {
    private let onboardingUseCase: any OnboardingUseCase

    init(onboardingUseCase: any OnboardingUseCase) {
        self.onboardingUseCase = onboardingUseCase
    }

    func shouldShowOnboarding(forceShow: Bool = false) -> Bool {
        onboardingUseCase.shouldShowOnboarding(forceShow: forceShow)
    }

    func markOnboardingShown() {
        onboardingUseCase.markOnboardingShown()
    }

    func makeOnboardingView(onDismiss: @escaping () -> Void) -> some View {
        Onboarding.OnboardingService.createOnboardingView {
            self.markOnboardingShown()
            onDismiss()
        }
    }
}
