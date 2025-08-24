//
//  OnboardingService.swift
//  Hackers
//
//  Copyright © 2025 Weiran Zhang. All rights reserved.
//

import SwiftUI

@MainActor
public enum OnboardingService {
    public static func shouldShowOnboarding(
        versionStore: OnboardingVersionStore = UserDefaultsOnboardingVersionStore(),
        forceShow: Bool = false
    ) -> Bool {
        if ProcessInfo.processInfo.arguments.contains("disableOnboarding"), forceShow == false {
            return false
        }
        
        return forceShow || !versionStore.hasShownOnboarding()
    }
    
    public static func createOnboardingView(
        onDismiss: @escaping () -> Void
    ) -> some View {
        let onboardingData = OnboardingData.currentOnboarding()
        return OnboardingView(onboardingData: onboardingData, onDismiss: onDismiss)
    }
    
    public static func markOnboardingShown(
        versionStore: OnboardingVersionStore = UserDefaultsOnboardingVersionStore()
    ) {
        versionStore.markOnboardingShown()
    }
}