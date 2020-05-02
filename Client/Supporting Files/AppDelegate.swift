//
//  AppDelegate.swift
//  Hackers2
//
//  Created by Weiran Zhang on 07/06/2014.
//  Copyright (c) 2014 Glass Umbrella. All rights reserved.
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

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Update the theme every time the app is active in case the system
        // appearance has changed. We're not using traitCollectionDidChange
        // as it doesn't get called reliably on an appearance change (iOS 13.4.1)
        ThemeSwitcher.switchTheme()
    }
}
