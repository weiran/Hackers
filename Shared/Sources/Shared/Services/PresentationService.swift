//
//  PresentationService.swift
//  Shared
//
//  Service for presentation-related utilities
//

import UIKit

@MainActor
public final class PresentationService: @unchecked Sendable {
    public static let shared = PresentationService()

    private init() {}

    public var windowScene: UIWindowScene? {
        UIApplication.shared.connectedScenes.first as? UIWindowScene
    }

    public var rootViewController: UIViewController? {
        windowScene?.windows.first?.rootViewController
    }
}
