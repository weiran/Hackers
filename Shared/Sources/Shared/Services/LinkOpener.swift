//
//  LinkOpener.swift
//  Shared
//
//  Copyright © 2025 Weiran Zhang. All rights reserved.
//

import SwiftUI
import SafariServices
import Domain

public struct LinkOpener {
    @MainActor
    public static func openURL(_ url: URL, with post: Post? = nil, showCommentsButton: Bool = false) {
        // Check if URL should be opened in Safari
        if shouldOpenInSafari(url) {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootViewController = windowScene.windows.first?.rootViewController {
                let config = SFSafariViewController.Configuration()
                config.entersReaderIfAvailable = UserDefaults.standard.bool(forKey: "safariReaderMode")

                let safariVC = SFSafariViewController(url: url, configuration: config)
                safariVC.preferredControlTintColor = UIColor(named: "appTintColor")

                rootViewController.present(safariVC, animated: true)
            }
        } else {
            UIApplication.shared.open(url)
        }
    }

    private static func shouldOpenInSafari(_ url: URL) -> Bool {
        // Open HTTP/HTTPS URLs in Safari, others in their respective apps
        return url.scheme == "http" || url.scheme == "https"
    }
}
