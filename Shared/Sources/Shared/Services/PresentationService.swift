//
//  PresentationService.swift
//  Shared
//
//  Copyright © 2025 Weiran Zhang. All rights reserved.
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
