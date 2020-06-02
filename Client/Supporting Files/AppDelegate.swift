//
//  AppDelegate.swift
//  Hackers2
//
//  Created by Weiran Zhang on 07/06/2014.
//  Copyright (c) 2014 Weiran Zhang. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func applicationDidFinishLaunching(_ application: UIApplication) {
        if ProcessInfo.processInfo.arguments.contains("disableReviewPrompts") {
            ReviewController.disablePrompts = true
        }
        if ProcessInfo.processInfo.arguments.contains("skipAnimations") {
            UIView.setAnimationsEnabled(false)
        }
        ReviewController.incrementLaunchCounter()
        ReviewController.requestReview()
        UserDefaults.standard.registerDefaults()
        ThemeSwitcher.switchTheme()
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        if let scheme = url.scheme,
            scheme.localizedCaseInsensitiveCompare("com.weiranzhang.Hackers") == .orderedSame,
            let view = url.host {
            let parameters = parseParameters(from: url)

            switch view {
            case "item":
                if let idString = parameters["id"], let id = Int(idString) {
                    // redirect to post
                }
            default: break
            }

//            redirect(to: view, with: parameters)
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
