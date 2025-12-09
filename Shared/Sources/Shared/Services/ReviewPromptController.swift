//
//  ReviewPromptController.swift
//  Shared
//
//  Copyright © 2025 Weiran Zhang. All rights reserved.
//

import StoreKit
import UIKit

@MainActor
public enum ReviewPromptController {
    public static var disablePrompts = false

    private static let launchCountKey = "ReviewPromptController_LaunchCount"
    private static let lastRequestTimeKey = "ReviewPromptController_LastRequestTime"

    public static func incrementLaunchCounter() {
        let currentCount = UserDefaults.standard.integer(forKey: launchCountKey)
        UserDefaults.standard.set(currentCount + 1, forKey: launchCountKey)
    }

    public static func requestReview() {
        guard !disablePrompts else { return }

        let launchCount = UserDefaults.standard.integer(forKey: launchCountKey)
        let lastRequestTime = UserDefaults.standard.object(forKey: lastRequestTimeKey) as? Date

        // Request review after 10 launches and then every 50 launches
        let shouldRequest = launchCount == 10 || (launchCount > 10 && launchCount % 50 == 0)

        // Don't request more than once per 120 days
        if let lastRequest = lastRequestTime,
           Date().timeIntervalSince(lastRequest) < 120 * 24 * 60 * 60
        {
            return
        }

        if shouldRequest {
            Task { @MainActor in
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                    SKStoreReviewController.requestReview(in: windowScene)
                    UserDefaults.standard.set(Date(), forKey: lastRequestTimeKey)
                }
            }
        }
    }
}
