//
//  TextScaling.swift
//  DesignSystem
//
//  Copyright © 2025 Weiran Zhang. All rights reserved.
//

import Domain
import SwiftUI

struct TextScalingEnvironmentKey: EnvironmentKey {
    static let defaultValue: CGFloat = 1.0
}

public extension EnvironmentValues {
    var textScaling: CGFloat {
        get { self[TextScalingEnvironmentKey.self] }
        set { self[TextScalingEnvironmentKey.self] = newValue }
    }
}

public extension View {
    func textScaling(_ scaleFactor: CGFloat) -> some View {
        environment(\.textScaling, scaleFactor)
    }

    func textScaling(for textSize: TextSize) -> some View {
        environment(\.textScaling, textSize.scaleFactor)
    }
}

public extension Font {
    func scaled(with factor: CGFloat) -> Font {
        if let titleFont = scaledTitleFont(with: factor) { return titleFont }
        if let textFont = scaledTextFont(with: factor) { return textFont }
        return self
    }

    // MARK: - Helpers split to reduce complexity

    private func scaledTitleFont(with factor: CGFloat) -> Font? {
        switch self {
        case .largeTitle:
            .system(size: 34 * factor, weight: .regular, design: .default)
        case .title:
            .system(size: 28 * factor, weight: .regular, design: .default)
        case .title2:
            .system(size: 22 * factor, weight: .regular, design: .default)
        case .title3:
            .system(size: 20 * factor, weight: .regular, design: .default)
        default:
            nil
        }
    }

    private func scaledTextFont(with factor: CGFloat) -> Font? {
        switch self {
        case .headline:
            .system(size: 17 * factor, weight: .semibold, design: .default)
        case .body:
            .system(size: 17 * factor, weight: .regular, design: .default)
        case .callout:
            .system(size: 16 * factor, weight: .regular, design: .default)
        case .subheadline:
            .system(size: 15 * factor, weight: .regular, design: .default)
        case .footnote:
            .system(size: 13 * factor, weight: .regular, design: .default)
        case .caption:
            .system(size: 12 * factor, weight: .regular, design: .default)
        case .caption2:
            .system(size: 11 * factor, weight: .regular, design: .default)
        default:
            nil
        }
    }
}

struct ScaledFont: ViewModifier {
    @Environment(\.textScaling) private var textScaling
    let font: Font

    func body(content: Content) -> some View {
        content
            .font(font.scaled(with: textScaling))
    }
}

public extension View {
    func scaledFont(_ font: Font) -> some View {
        modifier(ScaledFont(font: font))
    }
}
