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
        ReviewController.incrementLaunchCounter()
        ReviewController.requestReview()
        setAppTheme()
    }

    private func setAppTheme() {
        if #available(iOS 13, *) {
            AppThemeProvider.shared.currentTheme = .dynamic
        } else {
            AppThemeProvider.shared.currentTheme = UserDefaults.standard.darkModeEnabled ? .dark : .light
        }
    }
}
