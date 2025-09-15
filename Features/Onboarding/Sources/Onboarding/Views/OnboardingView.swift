//
//  OnboardingView.swift
//  Hackers
//
//  Copyright © 2025 Weiran Zhang. All rights reserved.
//

import DesignSystem
import SwiftUI

public struct OnboardingView: View {
    private let onboardingData: OnboardingData
    private let onDismiss: () -> Void

    public init(onboardingData: OnboardingData, onDismiss: @escaping () -> Void) {
        self.onboardingData = onboardingData
        self.onDismiss = onDismiss
    }

    public var body: some View {
        NavigationView {
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
                            .font(.system(size: 16, weight: .medium))
                    }
                    .foregroundStyle(AppColors.appTintColor)
                    .accessibilityLabel("Close")
                }
            }
        }
    }

    private var headerView: some View {
        VStack(spacing: 12) {
            Text(onboardingData.title)
                .scaledFont(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
        }
    }

    private var itemsList: some View {
        LazyVStack(spacing: 24) {
            ForEach(onboardingData.items) { item in
                OnboardingItemView(item: item)
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
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .buttonStyle(.plain)
        }
    }
}
