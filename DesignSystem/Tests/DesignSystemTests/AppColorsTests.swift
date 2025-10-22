//
//  AppColorsTests.swift
//  DesignSystemTests
//
//  Copyright © 2025 Weiran Zhang. All rights reserved.
//

@testable import DesignSystem
import SwiftUI
import Testing
import UIKit

@Suite("App Color Semantics")
struct AppColorsTests {
    @Test("Asset-backed colors resolve from main bundle")
    func assetBackedColorsResolve() {
        let upvotedAsset = UIColor(named: "upvotedColor", in: .main, compatibleWith: nil)
        let tintAsset = UIColor(named: "appTintColor", in: .main, compatibleWith: nil)

        let upvoted = resolvedColor(AppColors.upvoted, style: .light)
        let fallbackUpvoted = resolvedColor(AppColors.upvotedColor, style: .light)
        let tint = resolvedColor(AppColors.appTint, style: .light)
        let fallbackTint = resolvedColor(AppColors.appTintColor, style: .light)

        if let upvotedAsset {
            #expect(upvoted.approximatelyEquals(upvotedAsset))
            #expect(fallbackUpvoted.approximatelyEquals(upvotedAsset))
        } else {
            #expect(upvoted.approximatelyEquals(fallbackUpvoted))
        }

        if let tintAsset {
            #expect(tint.approximatelyEquals(tintAsset))
            #expect(fallbackTint.approximatelyEquals(tintAsset))
        } else {
            #expect(tint.approximatelyEquals(fallbackTint))
        }
    }

    @Test("Fallback helpers mirror asset colours when available")
    func fallbackHelpersMatchAsset() {
        let upvoted = resolvedColor(AppColors.upvoted, style: .light)
        let fallbackUpvoted = resolvedColor(AppColors.upvotedColor, style: .light)
        let tint = resolvedColor(AppColors.appTint, style: .light)
        let fallbackTint = resolvedColor(AppColors.appTintColor, style: .light)

        #expect(fallbackUpvoted.approximatelyEquals(upvoted))
        #expect(fallbackTint.approximatelyEquals(tint))
    }

    @Test("Semantic system colours retain expected RGB values")
    func semanticSystemColours() {
        let trait = UITraitCollection(userInterfaceStyle: .light)
        let success = resolvedColor(AppColors.success, style: .light)
        let warning = resolvedColor(AppColors.warning, style: .light)
        let danger = resolvedColor(AppColors.danger, style: .light)

        let systemSuccess = UIColor.systemGreen.resolvedColor(with: trait)
        let systemWarning = UIColor.systemOrange.resolvedColor(with: trait)
        let systemDanger = UIColor.systemRed.resolvedColor(with: trait)

        #expect(success.approximatelyEquals(systemSuccess))
        #expect(warning.approximatelyEquals(systemWarning))
        #expect(danger.approximatelyEquals(systemDanger))
    }

    @Test("Separator opacity adjusts with colour scheme")
    func separatorOpacityAdjusts() {
        let light = resolvedColor(AppColors.separator(for: .light), style: .light)
        let dark = resolvedColor(AppColors.separator(for: .dark), style: .dark)

        let baseLight = UIColor.separator.resolvedColor(with: UITraitCollection(userInterfaceStyle: .light))
        let baseDark = UIColor.separator.resolvedColor(with: UITraitCollection(userInterfaceStyle: .dark))
        let expectedLightAlpha = baseLight.cgColor.alpha * 0.3
        let expectedDarkAlpha = baseDark.cgColor.alpha * 0.6

        #expect(light.alpha.isApproximatelyEqual(to: expectedLightAlpha, tolerance: 0.01))
        #expect(dark.alpha.isApproximatelyEqual(to: expectedDarkAlpha, tolerance: 0.01))
        #expect(dark.alpha > light.alpha)
    }

    @Test("Primary button gradient uses tint colours when enabled")
    func primaryButtonGradientEnabled() {
        let gradient = AppGradients.primaryButton(isEnabled: true)
        let colors = colors(from: gradient)

        #expect(colors.count == 2)
        let tint = resolvedColor(AppColors.appTintColor, style: .light)
        #expect(colors[0].approximatelyEquals(tint))
        #expect(colors[1].approximatelyEquals(tint.withAlphaComponent(0.8), tolerance: 0.05))
    }

    @Test("Disabled primary button falls back to grey palette")
    func primaryButtonGradientDisabled() {
        let gradient = AppGradients.primaryButton(isEnabled: false)
        let colors = colors(from: gradient)

        #expect(colors.count == 2)
        #expect(colors.allSatisfy { $0.isGrayscale(tolerance: 0.05) })
    }

    @Test("Field theme returns focus tint and separator defaults")
    func fieldThemeVariants() {
        let focused = resolvedColor(AppFieldTheme.borderColor(for: .light, isFocused: true), style: .light)
        let unfocusedLight = resolvedColor(AppFieldTheme.borderColor(for: .light, isFocused: false), style: .light)
        let unfocusedDark = resolvedColor(AppFieldTheme.borderColor(for: .dark, isFocused: false), style: .dark)

        let tint = resolvedColor(AppColors.appTintColor, style: .light)
        let expectedLight = resolvedColor(AppColors.separator(for: .light), style: .light)
        let expectedDark = resolvedColor(AppColors.separator(for: .dark), style: .dark)

        #expect(focused.approximatelyEquals(tint))
        #expect(unfocusedLight.approximatelyEquals(expectedLight))
        #expect(unfocusedDark.approximatelyEquals(expectedDark))
    }

    @Test("Pill colour tokens reuse accent and neutral palettes")
    func pillColourSemantics() {
        let lightAccentBackground = resolvedColor(
            AppColors.pillBackground(for: .upvote(isActive: true), colorScheme: .light),
            style: .light
        )
        let expectedAccentBackground = resolvedColor(AppColors.upvotedColor.opacity(0.2), style: .light)
        #expect(lightAccentBackground.approximatelyEquals(expectedAccentBackground, tolerance: 0.01))

        let lightNeutralBackground = resolvedColor(
            AppColors.pillBackground(for: .comments, colorScheme: .light),
            style: .light
        )
        let expectedNeutralBackground = resolvedColor(Color.secondary.opacity(0.14), style: .light)
        #expect(lightNeutralBackground.approximatelyEquals(expectedNeutralBackground, tolerance: 0.01))

        let lightAccentForeground = resolvedColor(
            AppColors.pillForeground(for: .bookmark(isSaved: true), colorScheme: .light),
            style: .light
        )
        let expectedAccentForeground = resolvedColor(AppColors.appTintColor, style: .light)
        #expect(lightAccentForeground.approximatelyEquals(expectedAccentForeground))

        let lightNeutralForeground = resolvedColor(
            AppColors.pillForeground(for: .upvote(isActive: false), colorScheme: .light),
            style: .light
        )
        let expectedNeutralForeground = resolvedColor(Color.secondary, style: .light)
        #expect(lightNeutralForeground.approximatelyEquals(expectedNeutralForeground))

        let darkNeutralBackground = resolvedColor(
            AppColors.pillBackground(for: .comments, colorScheme: .dark),
            style: .dark
        )
        let expectedDarkNeutralBackground = resolvedColor(Color.secondary.opacity(0.1), style: .dark)
        #expect(darkNeutralBackground.approximatelyEquals(expectedDarkNeutralBackground, tolerance: 0.01))
    }
}

// MARK: - Test Helpers

private extension UIColor {
    var alpha: CGFloat {
        var a: CGFloat = 0
        getRed(nil, green: nil, blue: nil, alpha: &a)
        return a
    }

    func approximatelyEquals(_ other: UIColor?, tolerance: CGFloat = 0.001) -> Bool {
        guard let other else { return false }
        var lhsComponents: (CGFloat, CGFloat, CGFloat, CGFloat) = (0, 0, 0, 0)
        var rhsComponents: (CGFloat, CGFloat, CGFloat, CGFloat) = (0, 0, 0, 0)

        guard getRed(&lhsComponents.0, green: &lhsComponents.1, blue: &lhsComponents.2, alpha: &lhsComponents.3) else {
            return false
        }
        guard other.getRed(&rhsComponents.0, green: &rhsComponents.1, blue: &rhsComponents.2, alpha: &rhsComponents.3) else {
            return false
        }

        let pairs = zip([lhsComponents.0, lhsComponents.1, lhsComponents.2, lhsComponents.3],
                         [rhsComponents.0, rhsComponents.1, rhsComponents.2, rhsComponents.3])
        for (lhsValue, rhsValue) in pairs where abs(lhsValue - rhsValue) > tolerance {
            return false
        }
        return true
    }

    func isGrayscale(tolerance: CGFloat) -> Bool {
        var white: CGFloat = 0
        var alpha: CGFloat = 0
        if getWhite(&white, alpha: &alpha) { return true }

        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        guard getRed(&r, green: &g, blue: &b, alpha: &alpha) else { return false }
        return abs(r - g) < tolerance && abs(g - b) < tolerance
    }

    func componentsDescription() -> String {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        guard getRed(&r, green: &g, blue: &b, alpha: &a) else { return "unresolved" }
        return String(format: "(%.3f, %.3f, %.3f, %.3f)", r, g, b, a)
    }
}

private extension CGFloat {
    func isApproximatelyEqual(to value: CGFloat, tolerance: CGFloat) -> Bool {
        abs(self - value) <= tolerance
    }
}

private func colors(from gradient: LinearGradient) -> [UIColor] {
    let mirror = Mirror(reflecting: gradient)
    guard let storedGradient = mirror.children.first(where: { $0.label == "gradient" })?.value as? Gradient else {
        Issue.record("Unable to introspect gradient colours")
        return []
    }
    return storedGradient.stops.map { UIColor($0.color) }
}

private func resolvedColor(_ color: Color, style: UIUserInterfaceStyle) -> UIColor {
    UIColor(color).resolvedColor(with: UITraitCollection(userInterfaceStyle: style))
}
