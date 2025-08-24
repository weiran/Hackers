//
//  OnboardingData.swift
//  Hackers
//
//  Copyright © 2025 Weiran Zhang. All rights reserved.
//

import Foundation

public struct OnboardingData: Sendable {
    public let title: String
    public let items: [OnboardingItem]
    
    public init(title: String, items: [OnboardingItem]) {
        self.title = title
        self.items = items
    }
    
    public static func currentOnboarding() -> OnboardingData {
        let activeCategory = OnboardingItem(
            title: "Active Category Added",
            subtitle: "Browse the most actively discussed stories with the new Active feed category.",
            systemImage: "flame"
        )
        let stabilityFixes = OnboardingItem(
            title: "Stability Improvements", 
            subtitle: "Fixed crashes when tapping comment permalinks and improved feed pagination.",
            systemImage: "checkmark.shield"
        )
        
        return OnboardingData(
            title: "What's New in Hackers",
            items: [activeCategory, stabilityFixes]
        )
    }
}