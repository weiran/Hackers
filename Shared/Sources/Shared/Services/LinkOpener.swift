//
//  LinkOpener.swift
//  Shared
//
//  Copyright © 2025 Weiran Zhang. All rights reserved.
//

import Domain
import SafariServices
import SwiftUI

@MainActor
public enum LinkOpener {
    private static var settingsProvider: () -> any SettingsUseCase = {
        DependencyContainer.shared.getSettingsUseCase()
    }

    private static var systemOpener: (URL) -> Void = { url in
        UIApplication.shared.open(url)
    }

    private static var presenterProvider: () -> UIViewController? = {
        findPresenter()
    }

    private static var safariPresenter: (UIViewController, SFSafariViewController) -> Void = { presenter, safariVC in
        presenter.present(safariVC, animated: true)
    }

    private static var safariControllerFactory:
        (URL, SFSafariViewController.Configuration) -> SFSafariViewController = { url, configuration in
        SFSafariViewController(url: url, configuration: configuration)
    }

    public static func openURL(_ url: URL, with _: Post? = nil) {
        // Determine user preference for opening links via injected settings use case
        let settings = settingsProvider()
        let preferSystemBrowser = settings.linkBrowserMode == .systemBrowser

        // For http/https, either open in-app (SFSafariViewController) or system browser based on preference
        if isWebURL(url) {
            if preferSystemBrowser {
                systemOpener(url)
            } else if let presenter = presenterProvider() {
                let config = SFSafariViewController.Configuration()
                config.entersReaderIfAvailable = settings.safariReaderMode

                let safariVC = safariControllerFactory(url, config)
                safariPresenter(presenter, safariVC)
            } else {
                // Fallback if we cannot present in-app browser
                systemOpener(url)
            }
        } else {
            // Non-web URLs always use system handling
            systemOpener(url)
        }
    }

    private static func isWebURL(_ url: URL) -> Bool {
        // Web URLs are HTTP/HTTPS
        url.scheme == "http" || url.scheme == "https"
    }

    // Find the top-most view controller to present from
    private static func findPresenter() -> UIViewController? {
        let keyWindow = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
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

    // MARK: - Test Hooks

    static func setEnvironmentForTesting(
        settings: (() -> any SettingsUseCase)? = nil,
        openURL: ((URL) -> Void)? = nil,
        presenter: (() -> UIViewController?)? = nil,
        presentSafari: ((UIViewController, SFSafariViewController) -> Void)? = nil,
        safariControllerFactory: ((URL, SFSafariViewController.Configuration) -> SFSafariViewController)? = nil
    ) {
        if let settings { settingsProvider = settings }
        if let openURL { systemOpener = openURL }
        if let presenter { presenterProvider = presenter }
        if let presentSafari { safariPresenter = presentSafari }
        if let safariControllerFactory { self.safariControllerFactory = safariControllerFactory }
    }

    static func resetEnvironment() {
        settingsProvider = { DependencyContainer.shared.getSettingsUseCase() }
        systemOpener = { url in UIApplication.shared.open(url) }
        presenterProvider = { findPresenter() }
        safariPresenter = { presenter, safariVC in presenter.present(safariVC, animated: true) }
        safariControllerFactory = { url, configuration in
            SFSafariViewController(url: url, configuration: configuration)
        }
    }
}
