//
//  WhatsNewView.swift
//  Hackers
//
//  Copyright © 2025 Weiran Zhang. All rights reserved.
//

import DesignSystem
import SwiftUI

public struct WhatsNewView: View {
    private let whatsNewData: WhatsNewData
    private let onDismiss: () -> Void

    public init(
        whatsNewData: WhatsNewData,
        onDismiss: @escaping () -> Void
    ) {
        self.whatsNewData = whatsNewData
        self.onDismiss = onDismiss
    }

    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 32) {
                        headerView
                        itemsList
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                }

                actionButtons
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                    .padding(.top, 16)
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: onDismiss) {
                        Label("Close", systemImage: "xmark")
                            .labelStyle(.iconOnly)
                            .font(.headline)
                    }
                    .foregroundStyle(AppColors.appTintColor)
                    .accessibilityLabel("Close")
                }
            }
        }
    }

    private var headerView: some View {
        VStack(spacing: 12) {
            Text(whatsNewData.title)
                .scaledFont(.largeTitle)
                .bold()
                .multilineTextAlignment(.center)
        }
    }

    private var itemsList: some View {
        LazyVStack(spacing: 24) {
            ForEach(whatsNewData.items) { item in
                WhatsNewItemView(item: item)
            }
        }
    }

    private var actionButtons: some View {
        VStack(spacing: 12) {
            continueButton
        }
    }

    private var continueButton: some View {
        actionButton(title: "Continue", style: .secondary) {
            onDismiss()
        }
    }

    private enum ActionButtonStyle {
        case primary
        case secondary
    }

    @ViewBuilder
    private func actionButton(
        title: String,
        isEnabled: Bool = true,
        style: ActionButtonStyle = .primary,
        action: @escaping () -> Void
    ) -> some View {
        let isPrimary = style == .primary
        let label = Text(title)
            .scaledFont(.headline)
            .foregroundStyle(labelForegroundStyle(isPrimary: isPrimary, isEnabled: isEnabled))
            .frame(maxWidth: .infinity)
            .frame(height: 50)

        if isPrimary {
            Button(action: action) {
                label
            }
            .buttonStyle(.glassProminent)
            .tint(AppColors.appTintColor)
            .disabled(!isEnabled)
        } else {
            Button(action: action) {
                label
            }
            .buttonStyle(.glass)
            .tint(.secondary)
            .disabled(!isEnabled)
        }
    }

    private func labelForegroundStyle(isPrimary: Bool, isEnabled: Bool) -> Color {
        if isPrimary {
            return isEnabled ? .white : .secondary
        }

        return .primary
    }
}
