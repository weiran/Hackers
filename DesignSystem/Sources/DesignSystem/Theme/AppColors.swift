//
//  AppColors.swift
//  DesignSystem
//
//  Copyright © 2025 Weiran Zhang. All rights reserved.
//

import SwiftUI
import UIKit

public enum AppColors {
    public static var upvoted: Color {
        Color(uiColor: ColorResolver.assetColor(named: "upvotedColor", fallback: .systemOrange))
    }

    public static var appTint: Color {
        Color(uiColor: ColorResolver.assetColor(named: "appTintColor", fallback: .systemOrange))
    }

    public static let background = Color(.systemBackground)
    public static let secondaryBackground = Color(.secondarySystemBackground)
    public static let tertiaryBackground = Color(.tertiarySystemBackground)
    public static let groupedBackground = Color(.systemGroupedBackground)
    public static let success = Color(uiColor: .systemGreen)
    public static let warning = Color(uiColor: .systemOrange)
    public static let danger = Color(uiColor: .systemRed)

    public static var upvotedColor: Color {
        Color(uiColor: ColorResolver.assetColor(named: "upvotedColor", fallback: .systemOrange))
    }

    public static var appTintColor: Color {
        Color(uiColor: ColorResolver.assetColor(named: "appTintColor", fallback: .systemOrange))
    }

    public static func separator(for colorScheme: ColorScheme) -> Color {
        Color(.separator).opacity(colorScheme == .dark ? 0.6 : 0.3)
    }

    public static func pillBackground(for style: PillStyle, colorScheme: ColorScheme) -> Color {
        switch style {
        case .upvote(isActive: true):
            return pillAccentBackground(for: upvotedColor, colorScheme: colorScheme)
        case .upvote(isActive: false):
            return pillNeutralBackground(for: colorScheme)
        case .bookmark(isSaved: true):
            return pillAccentBackground(for: appTintColor, colorScheme: colorScheme)
        case .bookmark(isSaved: false):
            return pillNeutralBackground(for: colorScheme)
        case .comments:
            return pillNeutralBackground(for: colorScheme)
        }
    }

    public static func pillForeground(for style: PillStyle, colorScheme: ColorScheme) -> Color {
        switch style {
        case .upvote(isActive: true):
            return upvotedColor
        case .upvote(isActive: false):
            return pillNeutralForeground(for: colorScheme)
        case .bookmark(isSaved: true):
            return appTintColor
        case .bookmark(isSaved: false):
            return pillNeutralForeground(for: colorScheme)
        case .comments:
            return pillNeutralForeground(for: colorScheme)
        }
    }

    public enum PillStyle: Sendable {
        case upvote(isActive: Bool)
        case bookmark(isSaved: Bool)
        case comments
    }

    private static func pillNeutralBackground(for colorScheme: ColorScheme) -> Color {
        switch colorScheme {
        case .light:
            return Color.secondary.opacity(0.14)
        case .dark:
            return Color.secondary.opacity(0.1)
        @unknown default:
            return Color.secondary.opacity(0.14)
        }
    }

    private static func pillAccentBackground(for baseColor: Color, colorScheme: ColorScheme) -> Color {
        switch colorScheme {
        case .light, .dark:
            return baseColor.opacity(0.2)
        @unknown default:
            return baseColor.opacity(0.2)
        }
    }

    private static func pillNeutralForeground(for colorScheme: ColorScheme) -> Color {
        switch colorScheme {
        case .light, .dark:
            return Color.secondary
        @unknown default:
            return Color.secondary
        }
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
        if isEnabled {
            let tint = ColorResolver.resolvedTintColor(for: .light)
            return LinearGradient(
                gradient: Gradient(colors: [
                    Color(uiColor: tint),
                    Color(uiColor: tint.withAlphaComponent(0.8))
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }

        return LinearGradient(
            gradient: Gradient(colors: [
                Color.gray.opacity(0.6),
                Color.gray.opacity(0.4)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
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

private enum ColorResolver {
    static func assetColor(named name: String, fallback: UIColor) -> UIColor {
        if let mainAsset = UIColor(named: name, in: .main, compatibleWith: nil) {
            return mainAsset
        }
        return fallback
    }

    static func resolvedTintColor(for style: UIUserInterfaceStyle) -> UIColor {
        let tint = assetColor(named: "appTintColor", fallback: .systemOrange)
        return tint.resolvedColor(with: UITraitCollection(userInterfaceStyle: style))
    }

}
