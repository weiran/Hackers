//
//  AppColors.swift
//  DesignSystem
//
//  Copyright © 2025 Weiran Zhang. All rights reserved.
//

import SwiftUI

public enum AppColors {
    public static let upvoted = Color("upvotedColor", bundle: .main)
    public static let appTint = Color("appTintColor", bundle: .main)

    // Add fallback colors if asset colors are not found
    public static var upvotedColor: Color {
        if UIColor(named: "upvotedColor") != nil {
            Color("upvotedColor")
        } else {
            Color.orange
        }
    }

    public static var appTintColor: Color {
        if UIColor(named: "appTintColor") != nil {
            Color("appTintColor")
        } else {
            Color.orange
        }
    }
}
