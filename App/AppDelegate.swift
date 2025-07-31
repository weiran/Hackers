//
//  AppDelegate.swift
//  Hackers
//
//  Created by Weiran Zhang on 07/06/2014.
//  Copyright (c) 2014 Weiran Zhang. All rights reserved.
//

import UIKit
import SwinjectStoryboard
import Nuke

class AppDelegate: NSObject, UIApplicationDelegate {
    var navigationService: NavigationService?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // process args for testing
        if ProcessInfo.processInfo.arguments.contains("disableReviewPrompts") {
            ReviewController.disablePrompts = true
        }
        if ProcessInfo.processInfo.arguments.contains("skipAnimations") {
            UIView.setAnimationsEnabled(false)
        }

        // setup review prompt
        ReviewController.incrementLaunchCounter()
        ReviewController.requestReview()

        // init default settings
        UserDefaults.standard.registerDefaults()

        // setup Nuke
        DataLoader.sharedUrlCache.diskCapacity = 1024 * 1024 * 100 // 100MB

        return true
    }

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        let sceneConfig = UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
        sceneConfig.delegateClass = SceneDelegate.self
        return sceneConfig
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
                    // TODO: Handle navigation to post in SwiftUI
                    print("Navigate to post ID: \(id)")
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
}
