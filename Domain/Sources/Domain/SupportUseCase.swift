//
//  SupportUseCase.swift
//  Domain
//
//  Copyright © 2025 Weiran Zhang. All rights reserved.
//

import Foundation

public enum SupportProductKind: Sendable {
    case subscription
    case tip
}

public enum SupportPurchaseResult: Sendable {
    case success
    case userCancelled
    case pending
}

public struct SupportProduct: Identifiable, Hashable, Sendable {
    public let id: String
    public let displayName: String
    public let description: String
    public let displayPrice: String
    public let kind: SupportProductKind

    public init(
        id: String,
        displayName: String,
        description: String,
        displayPrice: String,
        kind: SupportProductKind
    ) {
        self.id = id
        self.displayName = displayName
        self.description = description
        self.displayPrice = displayPrice
        self.kind = kind
    }
}

public enum SupportProductIdentifier: String, CaseIterable, Sendable {
    case supporterMonthly = "com.weiran.hackers.supporter.monthly"
    case tipSmall = "com.weiran.hackers.tip.small"
    case tipMedium = "com.weiran.hackers.tip.medium"
    case tipLarge = "com.weiran.hackers.tip.large"

    public var kind: SupportProductKind {
        switch self {
        case .supporterMonthly:
            return .subscription
        case .tipSmall, .tipMedium, .tipLarge:
            return .tip
        }
    }

    public var sortOrder: Int {
        switch self {
        case .supporterMonthly:
            return 0
        case .tipSmall:
            return 1
        case .tipMedium:
            return 2
        case .tipLarge:
            return 3
        }
    }
}

public enum SupportPurchaseError: Error, LocalizedError, Sendable {
    case productUnavailable
    case failedVerification
    case underlying(Error)

    public var errorDescription: String? {
        switch self {
        case .productUnavailable:
            return "The selected product is not currently available."
        case .failedVerification:
            return "We could not verify this purchase. Please try again."
        case .underlying(let error):
            return error.localizedDescription
        }
    }
}

public protocol SupportUseCase: Sendable {
    func availableProducts() async throws -> [SupportProduct]
    func purchase(productId: String) async throws -> SupportPurchaseResult
    func restorePurchases() async throws -> SupportPurchaseResult
    func hasActiveSubscription(productId: String) async -> Bool
}
