//
//  TextScaling.swift
//  DesignSystem
//
//  Copyright © 2025 Weiran Zhang. All rights reserved.
//

import SwiftUI
import Domain

struct TextScalingEnvironmentKey: EnvironmentKey {
    static let defaultValue: CGFloat = 1.0
}

extension EnvironmentValues {
    public var textScaling: CGFloat {
        get { self[TextScalingEnvironmentKey.self] }
        set { self[TextScalingEnvironmentKey.self] = newValue }
    }
}

public extension View {
    func textScaling(_ scaleFactor: CGFloat) -> some View {
        self.environment(\.textScaling, scaleFactor)
    }

    func textScaling(for textSize: TextSize) -> some View {
        self.environment(\.textScaling, textSize.scaleFactor)
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
            return .system(size: 34 * factor, weight: .regular, design: .default)
        case .title:
            return .system(size: 28 * factor, weight: .regular, design: .default)
        case .title2:
            return .system(size: 22 * factor, weight: .regular, design: .default)
        case .title3:
            return .system(size: 20 * factor, weight: .regular, design: .default)
        default:
            return nil
        }
    }

    private func scaledTextFont(with factor: CGFloat) -> Font? {
        switch self {
        case .headline:
            return .system(size: 17 * factor, weight: .semibold, design: .default)
        case .body:
            return .system(size: 17 * factor, weight: .regular, design: .default)
        case .callout:
            return .system(size: 16 * factor, weight: .regular, design: .default)
        case .subheadline:
            return .system(size: 15 * factor, weight: .regular, design: .default)
        case .footnote:
            return .system(size: 13 * factor, weight: .regular, design: .default)
        case .caption:
            return .system(size: 12 * factor, weight: .regular, design: .default)
        case .caption2:
            return .system(size: 11 * factor, weight: .regular, design: .default)
        default:
            return nil
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
        self.modifier(ScaledFont(font: font))
    }
}
