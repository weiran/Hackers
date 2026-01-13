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

    public init(whatsNewData: WhatsNewData, onDismiss: @escaping () -> Void) {
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

                continueButton
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

    @ViewBuilder
    private var continueButton: some View {
        if #available(iOS 26.0, *) {
            Button(action: onDismiss) {
                Text("Continue")
                    .scaledFont(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
            }
            .glassEffect(.regular.tint(AppColors.appTintColor))
        } else {
            Button(action: onDismiss) {
                Text("Continue")
                    .scaledFont(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(AppColors.appTintColor)
            }
            .clipShape(.rect(cornerRadius: 12))
            .buttonStyle(.plain)
        }
    }
}
