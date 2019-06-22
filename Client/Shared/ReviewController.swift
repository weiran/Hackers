//
//  ReviewController.swift
//  Hackers
//
//  Created by Weiran Zhang on 07/10/2017.
//  Copyright © 2017 Glass Umbrella. All rights reserved.
//

import StoreKit

enum ReviewController {
    public static var disablePrompts = false

    private static let showPromptIncrements = [5, 10, 15]
    private static let LaunchCounter = "Launch Counter"

    public static func incrementLaunchCounter() {
        let counter = launchCounter()
        UserDefaults.standard.set(counter + 1, forKey: LaunchCounter)
    }

    public static func launchCounter() -> Int {
        return UserDefaults.standard.integer(forKey: LaunchCounter)
    }

    public static func requestReview() {
        if ProcessInfo.processInfo.arguments.contains("disableReviewPrompts") {
            return
        }
        if showPromptIncrements.contains(launchCounter()) && disablePrompts == false {
            SKStoreReviewController.requestReview()
        }
    }
}
