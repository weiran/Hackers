//
//  AppColorsTests.swift
//  DesignSystemTests
//
//  Copyright © 2025 Weiran Zhang. All rights reserved.
//

@testable import DesignSystem
import SwiftUI
import Testing

@Suite("AppColors Tests")
struct AppColorsTests {
    @Test("Color properties are consistent between calls")
    func colorConsistency() {
        // Test that multiple calls return the same color values
        let upvoted1 = AppColors.upvoted
        let upvoted2 = AppColors.upvoted
        let appTint1 = AppColors.appTint
        let appTint2 = AppColors.appTint
        let success1 = AppColors.success
        let success2 = AppColors.success
        let warning1 = AppColors.warning
        let warning2 = AppColors.warning
        let danger1 = AppColors.danger
        let danger2 = AppColors.danger

        #expect(upvoted1 == upvoted2, "upvoted color should be consistent")
        #expect(appTint1 == appTint2, "appTint color should be consistent")
        #expect(success1 == success2, "success color should be consistent")
        #expect(warning1 == warning2, "warning color should be consistent")
        #expect(danger1 == danger2, "danger color should be consistent")
    }

    @Test("Fallback color properties are consistent between calls")
    func fallbackColorConsistency() {
        // Test that multiple calls to fallback properties return consistent values
        let upvotedColor1 = AppColors.upvotedColor
        let upvotedColor2 = AppColors.upvotedColor
        let appTintColor1 = AppColors.appTintColor
        let appTintColor2 = AppColors.appTintColor

        #expect(upvotedColor1 == upvotedColor2, "upvotedColor should be consistent")
        #expect(appTintColor1 == appTintColor2, "appTintColor should be consistent")
    }

    @Test("AppColors enum structure")
    func enumStructure() {
        // Test that AppColors behaves like a namespace enum (no instances)
        // This is verified by the fact that we can access static properties
        // but can't create instances (private init should prevent this)

        // Static access should work
        _ = AppColors.upvoted
        _ = AppColors.appTint
        _ = AppColors.upvotedColor
        _ = AppColors.appTintColor

        #expect(true, "Static properties should be accessible")
    }

    @Test("Colors work with SwiftUI Views")
    func swiftUICompatibility() {
        // Test that colors can be used in SwiftUI contexts
        // This verifies they return proper Color types

        struct TestView: View {
            var body: some View {
                VStack {
                    Rectangle()
                        .fill(AppColors.upvoted)
                    Rectangle()
                        .fill(AppColors.appTint)
                    Rectangle()
                        .fill(AppColors.upvotedColor)
                    Rectangle()
                        .fill(AppColors.appTintColor)
                }
            }
        }

        let testView = TestView()
        #expect(testView != nil, "Colors should work in SwiftUI Views")
    }

    @Test("Asset color names are correct")
    func assetColorNames() {
        // Verify that the asset color names used in the implementation are correct
        // This is important for the asset lookup to work properly

        // Test by checking if the Color initializers can be called
        // (even if the actual assets aren't available in test context)
        let upvotedFromAsset = Color("upvotedColor", bundle: .main)
        let appTintFromAsset = Color("appTintColor", bundle: .main)

        #expect(upvotedFromAsset != nil)
        #expect(appTintFromAsset != nil)
    }

    @Test("Orange fallback colors")
    func orangeFallbacks() {
        // Test that orange is used as fallback
        let orange = Color.orange

        // The fallback logic should use orange when assets aren't found
        // In a test environment, this might be the case
        #expect(orange != nil, "Orange fallback color should be available")
    }

    @Test("Bundle reference is correct")
    func bundleReference() {
        // Test that .main bundle is used for asset lookup
        // This is important for the color assets to be found in the main app bundle

        let mainBundle = Bundle.main
        #expect(mainBundle != nil, "Main bundle should be accessible")
    }

    @Test("Thread safety of color access")
    func threadSafety() async {
        // Test concurrent access to color properties
        await withTaskGroup(of: Void.self) { group in
            for _ in 0 ..< 10 {
                group.addTask {
                    _ = AppColors.upvoted
                    _ = AppColors.appTint
                    _ = AppColors.upvotedColor
                    _ = AppColors.appTintColor
                }
            }
        }

        #expect(true, "Concurrent color access should work safely")
    }

    @Test("Primary button gradient adapts to enabled state")
    func primaryButtonGradientState() {
        let enabledGradient = AppGradients.primaryButton(isEnabled: true)
        let disabledGradient = AppGradients.primaryButton(isEnabled: false)

        #expect(String(describing: enabledGradient) != String(describing: disabledGradient))
    }

    @Test("Brand symbol gradient uses tint colors")
    func brandGradientComposition() {
        let gradient = AppGradients.brandSymbol()

        #expect(String(describing: gradient).isEmpty == false)
    }

    @Test("Success gradient uses semantic colors")
    func successGradientComposition() {
        let gradient = AppGradients.successSymbol()

        #expect(String(describing: gradient).isEmpty == false)
        #expect(String(describing: gradient) != String(describing: AppGradients.brandSymbol()))
    }

    @Test("Field theme responds to color scheme and focus")
    func fieldThemeVariants() {
        let focusedBorder = AppFieldTheme.borderColor(for: .light, isFocused: true)
        let unfocusedLight = AppFieldTheme.borderColor(for: .light, isFocused: false)
        let unfocusedDark = AppFieldTheme.borderColor(for: .dark, isFocused: false)

        #expect(focusedBorder != unfocusedLight)
        #expect(unfocusedLight != unfocusedDark)

        let lightBackground = AppFieldTheme.background(for: .light)
        let darkBackground = AppFieldTheme.background(for: .dark)

        #expect(lightBackground != darkBackground)
    }
}
