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
    public static let background = Color(.systemBackground)
    public static let secondaryBackground = Color(.secondarySystemBackground)
    public static let tertiaryBackground = Color(.tertiarySystemBackground)
    public static let groupedBackground = Color(.systemGroupedBackground)
    public static let success = Color(.systemGreen)
    public static let warning = Color(.systemOrange)
    public static let danger = Color(.systemRed)

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

    public static func separator(for colorScheme: ColorScheme) -> Color {
        Color(.separator).opacity(colorScheme == .dark ? 0.6 : 0.3)
    }
}

public enum AppGradients {
    public static func brandSymbol() -> LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [
                AppColors.appTintColor,
                AppColors.appTintColor.opacity(0.65)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing,
        )
    }

    public static func successSymbol() -> LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [
                AppColors.success,
                AppColors.success.opacity(0.65)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing,
        )
    }

    public static func screenBackground() -> LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [
                AppColors.background,
                AppColors.secondaryBackground.opacity(0.3)
            ]),
            startPoint: .top,
            endPoint: .bottom,
        )
    }

    public static func primaryButton(isEnabled: Bool) -> LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: isEnabled ?
                [AppColors.appTintColor, AppColors.appTintColor.opacity(0.8)] :
                [Color.gray.opacity(0.6), Color.gray.opacity(0.4)]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing,
        )
    }

    public static func destructiveButton() -> LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [Color.red, Color.red.opacity(0.8)]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing,
        )
    }
}

public enum AppFieldTheme {
    public static func background(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? AppColors.tertiaryBackground : AppColors.secondaryBackground
    }

    public static func borderColor(for colorScheme: ColorScheme, isFocused: Bool) -> Color {
        if isFocused { return AppColors.appTintColor }
        return AppColors.separator(for: colorScheme)
    }

    public static func borderWidth(isFocused: Bool) -> CGFloat {
        isFocused ? 2 : 1
    }
}
