//
//  AppColors.swift
//  DesignSystem
//
//  App color theme
//

import SwiftUI

public enum AppColors {
    public static let upvoted = Color("upvotedColor", bundle: .main)
    public static let appTint = Color("appTintColor", bundle: .main)

    // Add fallback colors if asset colors are not found
    public static var upvotedColor: Color {
        if UIColor(named: "upvotedColor") != nil {
            return Color("upvotedColor")
        } else {
            return Color.orange
        }
    }

    public static var appTintColor: Color {
        if UIColor(named: "appTintColor") != nil {
            return Color("appTintColor")
        } else {
            return Color.orange
        }
    }
}
