//
//  SupportView.swift
//  Settings
//
//  Copyright © 2025 Weiran Zhang. All rights reserved.
//

import DesignSystem
import Domain
import Observation
import SwiftUI

public struct SupportView: View {
    @State private var viewModel: SupportViewModel

    public init(viewModel: SupportViewModel = SupportViewModel()) {
        _viewModel = State(initialValue: viewModel)
    }

    public var body: some View {
        List {
            introductionSection
            subscriptionSection
            tipsSection
            restoreSection
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Support the App")
        .overlay {
            if viewModel.isLoading && viewModel.subscriptionProduct == nil && viewModel.tipProducts.isEmpty {
                ProgressView()
                    .progressViewStyle(.circular)
            }
        }
        .refreshable {
            viewModel.reloadProducts()
        }
        .task {
            viewModel.loadProductsIfNeeded()
        }
        .alert(item: $viewModel.alertInfo) { info in
            Alert(
                title: Text(info.title),
                message: Text(info.message),
                dismissButton: .default(Text("OK"))
            )
        }
    }

    private var introductionSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                Text("Hi, I'm Weiran")
                    .font(.title2.weight(.semibold))
                Text(
                    "I love building open source apps and Hackers is one of my proudest projects - the app that thousands reach for every day to catch up with Hacker News."
                )
                Text(
                    "If Hackers helps you stay informed or makes keeping up with the community a little easier, becoming a supporter gives me time to keep maintaining and improving the app."
                )
                Text(
                    "Every contribution keeps the app fast, reliable, and up to date."
                )
            }
            .padding(.vertical, 4)
        }
    }

    private var subscriptionSection: some View {
        Section(header: Text("Monthly Supporter")) {
            if viewModel.isSubscribed {
                subscribedThankYouView(product: viewModel.subscriptionProduct)
            } else if let product = viewModel.subscriptionProduct {
                VStack(alignment: .leading, spacing: 12) {
                    Text(product.displayName)
                        .font(.headline)

                    Text("Become a monthly supporter to help me keep improving Hackers. You can manage or cancel the subscription anytime in your App Store settings.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Button(action: { viewModel.purchase(product: product) }) {
                        HStack {
                            Image(systemName: "heart.fill")
                            Text("Subscribe for \(product.displayPrice)/month")
                                .bold()
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.glassProminent)
                    .tint(AppColors.appTintColor)
                    .disabled(viewModel.processingProductId == product.id)
                    .overlay(alignment: .trailing) {
                        if viewModel.processingProductId == product.id {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .padding(.trailing, 16)
                        }
                    }

                    Text("The subscription renews automatically each month until you cancel. Apple handles billing securely, and you'll receive a confirmation for every renewal.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            } else if viewModel.isLoading {
                loadingStateView(title: "Loading subscription…")
            } else {
                Text("Subscription currently unavailable. Pull to refresh and try again.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var tipsSection: some View {
        Section(header: Text("Leave a Tip")) {
            if viewModel.tipProducts.isEmpty {
                if viewModel.isLoading {
                    loadingStateView(title: "Loading tips…")
                } else {
                    Text("Tips are currently unavailable. Pull to refresh and try again.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    Text("One-off tips are perfect if you prefer to chip in now and then. Choose whichever amount feels right.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    ForEach(viewModel.tipProducts, id: \.id) { product in
                        Button(action: { viewModel.purchase(product: product) }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(product.displayName)
                                        .bold()
                                    Text(tipDescription(for: product))
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(2)
                                }
                                Spacer()
                                Text(product.displayPrice)
                                    .bold()
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                        }
                        .buttonStyle(.glass)
                        .tint(AppColors.appTintColor)
                        .disabled(viewModel.processingProductId == product.id)
                        .overlay(alignment: .trailing) {
                            if viewModel.processingProductId == product.id {
                                ProgressView()
                                    .progressViewStyle(.circular)
                                    .padding(.trailing, 16)
                            }
                        }
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }

    @ViewBuilder
    private func subscribedThankYouView(product: SupportProduct?) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "heart.circle.fill")
                    .foregroundStyle(AppColors.appTintColor)
                    .imageScale(.large)
                Text("Thank you for supporting Hackers!")
                    .font(.title3.weight(.semibold))
            }

            if let product {
                Text("Your \(product.displayName) subscription keeps the app running smoothly and lets me focus on polishing new features.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                Text("Your monthly support keeps the app running smoothly and lets me focus on polishing new features.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Button {
                if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
                    UIApplication.shared.open(url)
                }
            } label: {
                HStack {
                    Image(systemName: "arrow.up.right.square")
                    Text("Manage Subscription")
                        .bold()
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.glass)
            .tint(AppColors.appTintColor)
        }
        .padding(.vertical, 4)
    }

    private func loadingStateView(title: String) -> some View {
        HStack {
            Spacer()
            ProgressView(title)
                .progressViewStyle(.circular)
            Spacer()
        }
    }

    private var restoreSection: some View {
        Section {
            Button {
                viewModel.restorePurchases()
            } label: {
                HStack {
                    Image(systemName: "arrow.uturn.down.circle")
                    Text("Restore Purchases")
                    Spacer()
                    if viewModel.isRestoring {
                        ProgressView()
                            .progressViewStyle(.circular)
                    }
                }
            }
            .disabled(viewModel.isRestoring)
        } footer: {
            Text("If you've previously subscribed or tipped using the same Apple ID, tap restore to make sure those purchases are applied.")
                .font(.footnote)
        }
    }

    private func tipDescription(for product: SupportProduct) -> String {
        let trimmed = product.description.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty == false {
            return trimmed
        }

        switch SupportProductIdentifier(rawValue: product.id) {
        case .tipSmall:
            return "A quick thank-you to keep Hackers speedy and stable."
        case .tipMedium:
            return "Covers a few cups of coffee while I build new features."
        case .tipLarge:
            return "Helps fund bigger improvements and long-term maintenance."
        default:
            return "A one-off boost that goes straight into making Hackers better."
        }
    }
}

#Preview {
    NavigationStack {
        SupportView(
            viewModel: SupportViewModel(
                supportUseCase: PreviewSupportUseCase()
            )
        )
    }
}

private struct PreviewSupportUseCase: SupportUseCase {
    func availableProducts() async throws -> [SupportProduct] {
        [
            SupportProduct(
                id: SupportProductIdentifier.supporterMonthly.rawValue,
                displayName: "Hackers Supporter",
                description: "Stay up to date by funding ongoing development.",
                displayPrice: "£1.00",
                kind: .subscription
            ),
            SupportProduct(
                id: SupportProductIdentifier.tipSmall.rawValue,
                displayName: "Quick Tip",
                description: "Show appreciation and keep the app humming.",
                displayPrice: "£1.00",
                kind: .tip
            ),
            SupportProduct(
                id: SupportProductIdentifier.tipMedium.rawValue,
                displayName: "Nice Tip",
                description: "Help cover infrastructure and API costs.",
                displayPrice: "£3.00",
                kind: .tip
            ),
            SupportProduct(
                id: SupportProductIdentifier.tipLarge.rawValue,
                displayName: "Generous Tip",
                description: "Keep Hackers evolving with new features.",
                displayPrice: "£7.00",
                kind: .tip
            )
        ]
    }

    func purchase(productId: String) async throws -> SupportPurchaseResult {
        .success
    }

    func restorePurchases() async throws -> SupportPurchaseResult {
        .success
    }

    func hasActiveSubscription(productId: String) async -> Bool {
        false
    }
}
