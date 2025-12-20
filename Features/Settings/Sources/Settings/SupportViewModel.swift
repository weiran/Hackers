//
//  SupportViewModel.swift
//  Settings
//
//  Copyright © 2025 Weiran Zhang. All rights reserved.
//

import Domain
import Foundation
import Observation
import Shared

@MainActor
@Observable
public final class SupportViewModel: @unchecked Sendable {
    public struct AlertInfo: Identifiable, Sendable {
        public let id = UUID()
        public let title: String
        public let message: String

        public init(title: String, message: String) {
            self.title = title
            self.message = message
        }
    }

    private let supportUseCase: any SupportUseCase

    public private(set) var subscriptionProduct: SupportProduct?
    public private(set) var tipProducts: [SupportProduct] = []
    public private(set) var isLoading: Bool = false
    public private(set) var isRestoring: Bool = false
    public private(set) var processingProductId: String?
    public private(set) var isSubscribed: Bool = false
    public var alertInfo: AlertInfo?

    private var hasLoadedProducts = false

    public init(supportUseCase: any SupportUseCase = DependencyContainer.shared.getSupportUseCase()) {
        self.supportUseCase = supportUseCase
    }

    public func loadProductsIfNeeded() {
        guard hasLoadedProducts == false else { return }
        hasLoadedProducts = true
        Task { @MainActor [weak self] in
            guard let self else { return }
            await self.loadProducts()
        }
    }

    public func reloadProducts() {
        Task { @MainActor [weak self] in
            guard let self else { return }
            await self.loadProducts()
        }
    }

    private func loadProducts() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let products = try await supportUseCase.availableProducts()
            subscriptionProduct = products.first { $0.kind == .subscription }
            tipProducts = products.filter { $0.kind == .tip }
        } catch {
            alertInfo = AlertInfo(
                title: "Unable to Load Products",
                message: error.localizedDescription
            )
        }

        await updateSubscriptionStatus()
    }

    public func purchase(product: SupportProduct) {
        processingProductId = product.id
        Task { @MainActor [weak self] in
            guard let self else { return }
            defer { self.processingProductId = nil }
            do {
                let result = try await self.supportUseCase.purchase(productId: product.id)
                self.handle(result: result, for: product)
                if result == .success, product.kind == .subscription {
                    self.isSubscribed = true
                }
            } catch {
                self.alertInfo = AlertInfo(
                    title: "Purchase Failed",
                    message: error.localizedDescription
                )
            }
        }
    }

    public func restorePurchases() {
        isRestoring = true
        Task { @MainActor [weak self] in
            guard let self else { return }
            defer { self.isRestoring = false }
            do {
                let result = try await self.supportUseCase.restorePurchases()
                await self.updateSubscriptionStatus()
                self.handleRestore(result: result)
            } catch {
                self.alertInfo = AlertInfo(
                    title: "Restore Failed",
                    message: error.localizedDescription
                )
            }
        }
    }

    private func handle(result: SupportPurchaseResult, for product: SupportProduct) {
        switch result {
        case .success:
            switch product.kind {
            case .subscription:
                alertInfo = AlertInfo(
                    title: "Thank You!",
                    message: "You're now a Hackers Supporter. Your contribution keeps the app running smoothly."
                )
            case .tip:
                alertInfo = AlertInfo(
                    title: "Thank You!",
                    message: "Your tip helps keep Hackers fast, polished, "
                        + "and ready for the next big Hacker News discussion."
                )
            }
        case .pending:
            alertInfo = AlertInfo(
                title: "Purchase Pending",
                message: "Your purchase is pending approval from Apple. It will complete automatically once confirmed."
            )
        case .userCancelled:
            break
        }
    }

    private func handleRestore(result: SupportPurchaseResult) {
        switch result {
        case .success:
            alertInfo = AlertInfo(
                title: "Purchases Restored",
                message: "Any existing supporter subscriptions or tips linked to your Apple ID are now active again."
            )
        case .pending:
            alertInfo = AlertInfo(
                title: "Restore Pending",
                message: "Apple is still processing your restore request. Please check back shortly."
            )
        case .userCancelled:
            break
        }
    }

    private func updateSubscriptionStatus() async {
        let subscribed = await supportUseCase.hasActiveSubscription(
            productId: SupportProductIdentifier.supporterMonthly.rawValue
        )
        isSubscribed = subscribed
    }
}
