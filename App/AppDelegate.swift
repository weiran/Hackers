//
//  AppDelegate.swift
//  Hackers
//
//  Copyright © 2025 Weiran Zhang. All rights reserved.
//

import Data
import Shared
import UIKit

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _: UIApplication,
        didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // Configure a modest shared URL cache to limit on-disk growth from image/HTTP caching
        // This affects system components like AsyncImage that use URLSession.shared
        let memoryCapacity = 64 * 1024 * 1024 // 64 MB
        let diskCapacity = 128 * 1024 * 1024 // 128 MB
        URLCache.shared = URLCache(memoryCapacity: memoryCapacity, diskCapacity: diskCapacity)

        // process args for testing
        #if DEBUG
        let runtimePolicy = UITestingBootstrap.runtimePolicy
        #else
        let runtimePolicy = AppRuntimePolicy.standard
        #endif
        let disableReviewPrompts = ProcessInfo.processInfo.arguments.contains("disableReviewPrompts")
            || !runtimePolicy.allowsReviewPrompts
        ReviewPromptController.disablePrompts = disableReviewPrompts
        if ProcessInfo.processInfo.arguments.contains("skipAnimations") {
            UIView.setAnimationsEnabled(false)
        }

        // setup review prompt
        if !disableReviewPrompts {
            ReviewPromptController.incrementLaunchCounter()
            ReviewPromptController.requestReview()
        }

        // init default settings
        UserDefaults.standard.registerDefaults()

        return true
    }
}
