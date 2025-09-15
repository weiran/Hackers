//
//  LinkOpener.swift
//  Shared
//
//  Copyright © 2025 Weiran Zhang. All rights reserved.
//

import Domain
import SafariServices
import SwiftUI

public enum LinkOpener {
    @MainActor
    public static func openURL(_ url: URL, with _: Post? = nil) {
        // Determine user preference for opening links
        let preferSystemBrowser = UserDefaults.standard.bool(forKey: "openInDefaultBrowser")

        // For http/https, either open in-app (SFSafariViewController) or system browser based on preference
        if isWebURL(url) {
            if preferSystemBrowser {
                UIApplication.shared.open(url)
            } else if let presenter = findPresenter() {
                let config = SFSafariViewController.Configuration()
                config.entersReaderIfAvailable = UserDefaults.standard.bool(forKey: "safariReaderMode")

                let safariVC = SFSafariViewController(url: url, configuration: config)
                safariVC.preferredControlTintColor = UIColor(named: "appTintColor")

                presenter.present(safariVC, animated: true)
            } else {
                // Fallback if we cannot present in-app browser
                UIApplication.shared.open(url)
            }
        } else {
            // Non-web URLs always use system handling
            UIApplication.shared.open(url)
        }
    }

    private static func isWebURL(_ url: URL) -> Bool {
        // Web URLs are HTTP/HTTPS
        url.scheme == "http" || url.scheme == "https"
    }

    // Find the top-most view controller to present from
    @MainActor
    private static func findPresenter() -> UIViewController? {
        let keyWindow = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first(where: { $0.isKeyWindow })
        let root = keyWindow?.rootViewController

        func top(from base: UIViewController?) -> UIViewController? {
            if let nav = base as? UINavigationController {
                return top(from: nav.visibleViewController)
            }
            if let tab = base as? UITabBarController, let selected = tab.selectedViewController {
                return top(from: selected)
            }
            if let presented = base?.presentedViewController {
                return top(from: presented)
            }
            return base
        }

        return top(from: root)
    }
}
