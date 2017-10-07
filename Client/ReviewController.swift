//
//  ReviewController.swift
//  Hackers
//
//  Created by Weiran Zhang on 07/10/2017.
//  Copyright © 2017 Glass Umbrella. All rights reserved.
//

import StoreKit

class ReviewController {
    fileprivate static let showPromptIncrements = [5, 10, 15]
    fileprivate static let LaunchCounter = "Launch Counter"
    
    static func incrementLaunchCounter() {
        let counter = launchCounter()
        UserDefaults.standard.set(counter + 1, forKey: LaunchCounter)
    }
    
    static func launchCounter() -> Int {
        return UserDefaults.standard.integer(forKey: LaunchCounter)
    }
    
    static func requestReview() {
        if showPromptIncrements.contains(launchCounter()) {
            SKStoreReviewController.requestReview()
        }
    }
}
