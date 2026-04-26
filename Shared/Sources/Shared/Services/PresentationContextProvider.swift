//
//  PresentationContextProvider.swift
//  Shared
//
//  Copyright © 2025 Weiran Zhang. All rights reserved.
//

import UIKit

@MainActor
public final class PresentationContextProvider: @unchecked Sendable {
    public static let shared = PresentationContextProvider()

    private init() {}

    public var windowScene: UIWindowScene? {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        if let activeScene = scenes.first(where: { $0.activationState == .foregroundActive }) {
            return activeScene
        }
        return scenes.first
    }

    public var keyWindow: UIWindow? {
        guard let windowScene else { return nil }
        return windowScene.windows.first(where: { $0.isKeyWindow }) ?? windowScene.windows.first
    }

    public var rootViewController: UIViewController? {
        keyWindow?.rootViewController
    }
}
