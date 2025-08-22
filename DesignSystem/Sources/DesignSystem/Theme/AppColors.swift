//
//  AppColors.swift
//  DesignSystem
//
//  App color theme
//

import SwiftUI

public struct AppColors {
    public static let upvoted = Color("upvotedColor", bundle: .main)
    public static let appTint = Color("appTintColor", bundle: .main)
    
    // Add fallback colors if asset colors are not found
    public static var upvotedColor: Color {
        if let _ = UIColor(named: "upvotedColor") {
            return Color("upvotedColor")
        } else {
            return Color.orange
        }
    }
    
    public static var appTintColor: Color {
        if let _ = UIColor(named: "appTintColor") {
            return Color("appTintColor")
        } else {
            return Color.orange
        }
    }
}