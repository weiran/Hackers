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

    static func requestReview() {
        if ProcessInfo.processInfo.arguments.contains("disableReviewPrompts") {
            return
        }

        let scene = UIApplication.shared.connectedScenes.first(where: {
            $0.activationState == .foregroundActive
        }) as? UIWindowScene

        if let scene = scene, showPromptIncrements.contains(launchCounter()), disablePrompts == false {
            SKStoreReviewController.requestReview(in: scene)
        }
    }
}
