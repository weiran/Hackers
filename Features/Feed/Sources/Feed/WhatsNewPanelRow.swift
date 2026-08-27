//
//  WhatsNewPanelRow.swift
//  Feed
//
//  Copyright © 2025 Weiran Zhang. All rights reserved.
//

import DesignSystem
import Shared
import SwiftUI

/// What's New call to action shown at the top of the feed, composed by the
/// app target so Feed stays decoupled from the WhatsNew module.
public struct WhatsNewPanel {
    public let title: String
    public let action: () -> Void
    public let dismissAction: () -> Void

    public init(
        title: String,
        action: @escaping () -> Void,
        dismissAction: @escaping () -> Void
    ) {
        self.title = title
        self.action = action
        self.dismissAction = dismissAction
    }
}

struct WhatsNewPanelRow: View {
    let panel: WhatsNewPanel

    var body: some View {
        Button(action: panel.action) {
            HStack(spacing: 14) {
                icon

                VStack(alignment: .leading, spacing: 2) {
                    Text(panel.title)
                        .scaledFont(.subheadline)
                        .bold()
                        .multilineTextAlignment(.leading)
                        .foregroundStyle(.white)

                    Text("See what changed")
                        .scaledFont(.footnote)
                        .foregroundStyle(.white.opacity(0.85))
                }

                Spacer(minLength: 8)

                dismissButton
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .contentShape(.rect(cornerRadius: 20, style: .continuous))
        }
        .buttonStyle(PressableDimButtonStyle())
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(AppColors.appTintColor)
        )
        .accessibilityIdentifier(AccessibilityIdentifier.Feed.whatsNewPanel)
    }

    private var icon: some View {
        Image(systemName: "sparkles")
            .scaledFont(.headline)
            .foregroundStyle(.white)
            .frame(width: 34, height: 34)
            .background(Circle().fill(.white.opacity(0.22)))
            .accessibilityHidden(true)
    }

    private var dismissButton: some View {
        Button(action: panel.dismissAction) {
            Image(systemName: "xmark.circle.fill")
                .scaledFont(.title3)
                .foregroundStyle(.white.opacity(0.9))
                .contentShape(Rectangle())
        }
        .buttonStyle(PressableDimButtonStyle())
        .accessibilityLabel("Dismiss What's New")
        .accessibilityIdentifier(AccessibilityIdentifier.Feed.whatsNewPanelDismiss)
    }
}

/// Dim-on-press feedback matching AppDefaultButtonStyle, without overriding
/// the per-element foreground styles used inside the filled panel.
private struct PressableDimButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.65 : 1)
    }
}
