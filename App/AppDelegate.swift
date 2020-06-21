//
//  AppDelegate.swift
//  Hackers2
//
//  Created by Weiran Zhang on 07/06/2014.
//  Copyright (c) 2014 Weiran Zhang. All rights reserved.
//

import UIKit
import SwinjectStoryboard

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    var navigationService: NavigationService?

    func applicationDidFinishLaunching(_ application: UIApplication) {
        // process args for testing
        if ProcessInfo.processInfo.arguments.contains("disableReviewPrompts") {
            ReviewController.disablePrompts = true
        }
        if ProcessInfo.processInfo.arguments.contains("skipAnimations") {
            UIView.setAnimationsEnabled(false)
        }

        // setup window and entry point
        window = UIWindow()
        let storyboard = UIStoryboard(name: "Main", bundle: .main)
        let mainSplitViewController = storyboard.instantiateViewController(
            identifier: "MainSplitViewController"
        ) as MainSplitViewController
        window?.rootViewController = mainSplitViewController
        window?.makeKeyAndVisible()

        // setup NavigationService
        navigationService = SwinjectStoryboard.getService()
        navigationService?.mainSplitViewController = mainSplitViewController

        // setup review prompt
        ReviewController.incrementLaunchCounter()
        ReviewController.requestReview()

        // init default settings
        UserDefaults.standard.registerDefaults()

        // setup theming
        ThemeSwitcher.switchTheme()
    }

    func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey: Any] = [:]
    ) -> Bool {
        // handle incoming links to open post
        let bundleIdentifier = String(Bundle.main.bundleIdentifier!)
        if let scheme = url.scheme,
            scheme.localizedCaseInsensitiveCompare(bundleIdentifier) == .orderedSame,
            let view = url.host {
            let parameters = parseParameters(from: url)

            switch view {
            case "item":
                if let idString = parameters["id"],
                    let id = Int(idString) {
                    navigationService?.showPost(id: id)
                }
            default: break
            }
        }
        return true
    }

    private func parseParameters(from url: URL) -> [String: String] {
        var parameters: [String: String] = [:]
        URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems?.forEach {
            parameters[$0.name] = $0.value
        }
        return parameters
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Update the theme every time the app is active in case the system
        // appearance has changed. We're not using traitCollectionDidChange
        // as it doesn't get called reliably on an appearance change (iOS 13.4.1)
        ThemeSwitcher.switchTheme()
    }
}
