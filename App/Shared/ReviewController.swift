//
//  ReviewController.swift
//  Hackers
//
//  Created by Weiran Zhang on 07/10/2017.
//  Copyright © 2017 Weiran Zhang. All rights reserved.
//

import StoreKit

enum ReviewController {
    static var disablePrompts = false

    private static let showPromptIncrements = [5, 10, 15]
    private static let LaunchCounter = "Launch Counter"

    static func incrementLaunchCounter() {
        let counter = launchCounter()
        UserDefaults.standard.set(counter + 1, forKey: LaunchCounter)
    }

    static func launchCounter() -> Int {
        return UserDefaults.standard.integer(forKey: LaunchCounter)
    }

    @MainActor
    static func requestReview() {
        if ProcessInfo.processInfo.arguments.contains("disableReviewPrompts") {
            return
        }

        if let scene = PresentationService.shared.windowScene,
           showPromptIncrements.contains(launchCounter()),
           disablePrompts == false {
            // Note: SKStoreReviewController.requestReview is deprecated in iOS 18.0
            // The replacement AppStore.requestReview requires iOS 18.0+ and AppStore framework
            // For now, continue using the deprecated method for compatibility
            SKStoreReviewController.requestReview(in: scene)
        }
    }
}
