//
//  SupportPurchaseRepository.swift
//  Data
//
//  Copyright © 2025 Weiran Zhang. All rights reserved.
//

import Domain
import Foundation
import os
import StoreKit
public final class SupportPurchaseRepository: SupportUseCase, @unchecked Sendable {
    private let productsLock = OSAllocatedUnfairLock<[String: Product]>(initialState: [:])

    public init() {}

    public func availableProducts() async throws -> [SupportProduct] {
        let identifiers = SupportProductIdentifier.allCases.map(\.rawValue)
        let storeProducts = try await Product.products(for: identifiers)

        var mappedProducts: [SupportProduct] = []
        mappedProducts.reserveCapacity(storeProducts.count)

        for product in storeProducts {
            guard let identifier = SupportProductIdentifier(rawValue: product.id) else { continue }
            let supportProduct = SupportProduct(
                id: product.id,
                displayName: product.displayName,
                description: product.description,
                displayPrice: product.displayPrice,
                kind: identifier.kind
            )
            mappedProducts.append(supportProduct)
        }

        productsLock.withLock { storage in
            storage.removeAll(keepingCapacity: true)
            for product in storeProducts {
                storage[product.id] = product
            }
        }

        return mappedProducts.sorted { lhs, rhs in
            let lhsOrder = SupportProductIdentifier(rawValue: lhs.id)?.sortOrder ?? Int.max
            let rhsOrder = SupportProductIdentifier(rawValue: rhs.id)?.sortOrder ?? Int.max
            return lhsOrder < rhsOrder
        }
    }

    public func purchase(productId: String) async throws -> SupportPurchaseResult {
        let product = try await product(for: productId)

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verificationResult):
                let transaction = try verifiedTransaction(from: verificationResult)
                await transaction.finish()
                return .success
            case .userCancelled:
                return .userCancelled
            case .pending:
                return .pending
            @unknown default:
                return .pending
            }
        } catch StoreKitError.userCancelled {
            return .userCancelled
        } catch {
            throw SupportPurchaseError.underlying(error)
        }
    }

    public func restorePurchases() async throws -> SupportPurchaseResult {
        do {
            try await AppStore.sync()
            return .success
        } catch StoreKitError.userCancelled {
            return .userCancelled
        } catch {
            throw SupportPurchaseError.underlying(error)
        }
    }

    public func hasActiveSubscription(productId: String) async -> Bool {
        do {
            guard let latest = try await Transaction.latest(for: productId) else {
                return false
            }

            switch latest {
            case .verified(let transaction):
                if let revocationDate = transaction.revocationDate {
                    return false
                }

                if let expirationDate = transaction.expirationDate {
                    return expirationDate > Date()
                }

                return true
            case .unverified:
                return false
            }
        } catch {
            return false
        }
    }

    private func verifiedTransaction(
        from verificationResult: VerificationResult<Transaction>
    ) throws -> Transaction {
        switch verificationResult {
        case .verified(let transaction):
            return transaction
        case .unverified(_, let verificationError):
            throw SupportPurchaseError.underlying(verificationError)
        }
    }

    private func product(for identifier: String) async throws -> Product {
        if let cached = productsLock.withLock({ $0[identifier] }) {
            return cached
        }

        let products = try await Product.products(for: [identifier])
        guard let product = products.first else {
            throw SupportPurchaseError.productUnavailable
        }
        productsLock.withLock { storage in
            storage[identifier] = product
        }
        return product
    }
}
