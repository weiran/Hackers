//
//  ProgressiveHeaderBlurBackground.swift
//  DesignSystem
//
//  Copyright © 2026 Weiran Zhang. All rights reserved.
//

import SwiftUI
import VariableBlur

public struct ProgressiveHeaderBlurBackground: View {
    private let height: CGFloat
    private let fadeExtension: CGFloat
    private let maxBlurRadius: CGFloat
    private let tintOpacityTop: Double
    private let tintOpacityMiddle: Double
    private let tintMiddleLocation: CGFloat?
    private let tint: Color?
    @Environment(\.colorScheme) private var colorScheme

    public init(
        height: CGFloat,
        fadeExtension: CGFloat = 64,
        maxBlurRadius: CGFloat = 5,
        tintOpacityTop: Double = 0.7,
        tintOpacityMiddle: Double = 0.5,
        tintMiddleLocation: CGFloat? = nil,
        tint: Color? = nil
    ) {
        self.height = height
        self.fadeExtension = fadeExtension
        self.maxBlurRadius = maxBlurRadius
        self.tintOpacityTop = tintOpacityTop
        self.tintOpacityMiddle = tintOpacityMiddle
        self.tintMiddleLocation = tintMiddleLocation
        self.tint = tint
    }

    public var body: some View {
        let totalHeight = max(height + fadeExtension, 1)
        let middleLocation = tintMiddleLocation ?? min(90 / totalHeight, 1)
        let overlayTint = tint ?? fadeTint

        VariableBlurView(
            maxBlurRadius: maxBlurRadius,
            direction: .blurredTopClearBottom
        )
        .overlay {
            LinearGradient(
                stops: [
                    .init(color: overlayTint.opacity(tintOpacityTop), location: 0),
                    .init(color: overlayTint.opacity(tintOpacityMiddle), location: middleLocation),
                    .init(color: overlayTint.opacity(0), location: 1)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .frame(height: totalHeight)
        .ignoresSafeArea(edges: .top)
        .allowsHitTesting(false)
    }

    private var fadeTint: Color {
        colorScheme == .dark ? .black : .white
    }
}
