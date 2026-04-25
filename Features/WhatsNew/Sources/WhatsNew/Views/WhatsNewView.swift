//
//  WhatsNewView.swift
//  Hackers
//
//  Copyright © 2025 Weiran Zhang. All rights reserved.
//

import DesignSystem
import Domain
import Shared
import SwiftUI

public struct WhatsNewView: View {
    private let whatsNewData: WhatsNewData
    private let onDismiss: () -> Void
    private let settingsUseCase: any SettingsUseCase
    @State private var embeddedBrowserEnabled: Bool

    public init(
        whatsNewData: WhatsNewData,
        onDismiss: @escaping () -> Void,
        settingsUseCase: any SettingsUseCase = DependencyContainer.shared.getSettingsUseCase()
    ) {
        self.whatsNewData = whatsNewData
        self.onDismiss = onDismiss
        self.settingsUseCase = settingsUseCase
        _embeddedBrowserEnabled = State(initialValue: settingsUseCase.linkBrowserMode == .customBrowser)
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
                        Image(systemName: "xmark")
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
            if LinkBrowserMode.isCustomBrowserAvailable {
                enableEmbeddedBrowserButton
            }
            continueButton
        }
    }

    private var enableEmbeddedBrowserButton: some View {
        actionButton(
            title: embeddedBrowserEnabled ? "Embedded Browser Enabled" : "Enable Embedded Browser",
            isEnabled: !embeddedBrowserEnabled,
            style: .primary
        ) {
            enableEmbeddedBrowser()
        }
    }

    private var continueButton: some View {
        actionButton(title: "Continue", style: .secondary) {
            onDismiss()
        }
    }

    private func enableEmbeddedBrowser() {
        guard !embeddedBrowserEnabled else { return }
        settingsUseCase.linkBrowserMode = .customBrowser
        embeddedBrowserEnabled = true
        onDismiss()
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
            .foregroundStyle(isPrimary ? .white : .primary)
            .frame(maxWidth: .infinity)
            .frame(height: 50)

        if isPrimary {
            Button(action: action) {
                label
            }
            .buttonStyle(.glassProminent)
            .tint(AppColors.appTintColor)
            .disabled(!isEnabled)
            .opacity(isEnabled ? 1 : 0.7)
        } else {
            Button(action: action) {
                label
            }
            .buttonStyle(.glass)
            .tint(.secondary)
            .disabled(!isEnabled)
            .opacity(isEnabled ? 1 : 0.7)
        }
    }
}
