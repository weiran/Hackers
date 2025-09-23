//
//  AppStateViews.swift
//  DesignSystem
//
//  Copyright © 2025 Weiran Zhang. All rights reserved.
//

import Shared
import SwiftUI

public struct AppLoadingStateView: View {
    private let message: String?
    private let fillsSpace: Bool

    public init(message: String? = nil, fillsSpace: Bool = true) {
        self.message = message
        self.fillsSpace = fillsSpace
    }

    public var body: some View {
        VStack(spacing: 12) {
            ProgressView()
            if let message {
                Text(message)
                    .scaledFont(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .padding(.horizontal, 16)
        .accessibilityElement(children: .combine)
        .frame(maxHeight: fillsSpace ? .infinity : nil)
    }
}

public struct AppEmptyStateView: View {
    private let iconSystemName: String?
    private let title: String
    private let subtitle: String?
    private let fillsSpace: Bool

    public init(iconSystemName: String? = nil, title: String, subtitle: String? = nil, fillsSpace: Bool = true) {
        self.iconSystemName = iconSystemName
        self.title = title
        self.subtitle = subtitle
        self.fillsSpace = fillsSpace
    }

    public var body: some View {
        VStack(spacing: 12) {
            if let iconSystemName {
                Image(systemName: iconSystemName)
                    .scaledFont(.title2)
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
            }

            Text(title)
                .scaledFont(.headline)
                .multilineTextAlignment(.center)

            if let subtitle {
                Text(subtitle)
                    .scaledFont(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .padding(.horizontal, 16)
        .accessibilityElement(children: .combine)
        .frame(maxHeight: fillsSpace ? .infinity : nil)
    }
}

public struct ToastBanner: View {
    private let toast: ToastMessage

    public init(message: ToastMessage) {
        toast = message
    }

    public var body: some View {
        HStack(spacing: 12) {
            if let iconName {
                Image(systemName: iconName)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(iconColor)
                    .accessibilityHidden(true)
            }

            Text(toast.text)
                .scaledFont(.callout)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .glassEffect()
        .accessibilityElement(children: .combine)
    }

    private var iconName: String? {
        switch toast.kind {
        case .success: "checkmark.circle.fill"
        case .failure: "xmark.circle.fill"
        case .neutral: nil
        }
    }

    private var iconColor: Color {
        switch toast.kind {
        case .success: AppColors.success
        case .failure: AppColors.danger
        case .neutral: .secondary
        }
    }
}
