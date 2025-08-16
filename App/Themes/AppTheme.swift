//
//  Theme.swift
//  Hackers
//
//  Created by Weiran Zhang on 14/12/2015.
//  Copyright © 2015 Weiran Zhang. All rights reserved.
//

import UIKit

struct AppTheme {
    var appTintColor: UIColor
    var upvotedColor: UIColor
}

extension AppTheme {
    private static func themeBuilder(_ userInterfaceStyle: UIUserInterfaceStyle? = nil) -> AppTheme {
        // always get a fresh trait collection as the user may have changed system appearance
        var traitCollection = currentTraitCollection()

        return AppTheme(
            appTintColor: UIColor(named: "appTintColor", in: nil, compatibleWith: traitCollection)!,
            upvotedColor: UIColor(named: "upvotedColor", in: nil, compatibleWith: traitCollection)!
        )
    }

    private static func currentTraitCollection() -> UITraitCollection {
        // use a fresh UIViewController uncontaminated by theme changes
        let viewController = UIViewController()
        return viewController.traitCollection
    }

    static var `default`: AppTheme {
        AppTheme.themeBuilder()
    }
}
