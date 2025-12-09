//
//  OnboardingItemView.swift
//  Hackers
//
//  Copyright © 2025 Weiran Zhang. All rights reserved.
//

import DesignSystem
import SwiftUI

struct OnboardingItemView: View {
    let item: OnboardingItem

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            iconView
            contentView
            Spacer()
        }
        .padding(.horizontal, 4)
    }

    private var iconView: some View {
        Image(systemName: item.systemImage)
            .scaledFont(.title2)
            .foregroundStyle(AppColors.appTintColor)
            .frame(width: 32, height: 32)
            .accessibilityHidden(true)
    }

    private var contentView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(item.title)
                .scaledFont(.headline)
                .bold()

            Text(item.subtitle)
                .scaledFont(.body)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
