//
//  OnboardingService.swift
//  Hackers
//
//  Copyright © 2025 Weiran Zhang. All rights reserved.
//

import SwiftUI
import Onboarding

@MainActor
enum OnboardingService {
    static func shouldShowOnboarding(forceShow: Bool = false) -> Bool {
        Onboarding.OnboardingService.shouldShowOnboarding(forceShow: forceShow)
    }

    static func markOnboardingShown() {
        Onboarding.OnboardingService.markOnboardingShown()
    }
}

struct OnboardingViewWrapper: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Onboarding.OnboardingService.createOnboardingView {
            OnboardingService.markOnboardingShown()
            dismiss()
        }
    }
}
