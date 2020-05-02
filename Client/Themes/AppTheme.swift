//
//  Theme.swift
//  Hackers
//
//  Created by Weiran Zhang on 14/12/2015.
//  Copyright © 2015 Glass Umbrella. All rights reserved.
//

import UIKit

struct AppTheme {
    var appTintColor: UIColor

    var backgroundColor: UIColor

    var titleTextColor: UIColor
    var textColor: UIColor
    var lightTextColor: UIColor

    var cellHighlightColor: UIColor
    var separatorColor: UIColor

    var groupedTableViewBackgroundColor: UIColor
    var groupedTableViewCellBackgroundColor: UIColor

    var upvotedColor: UIColor

    var userInterfaceStyle: UIUserInterfaceStyle
}

extension AppTheme {
    private static func themeBuilder(_ userInterfaceStyle: UIUserInterfaceStyle? = nil) -> AppTheme {
        // always get a fresh trait collection as the user may have changed system appearance
        var traitCollection = currentTraitCollection()
        var selectedUserInterfaceStyle = traitCollection.userInterfaceStyle

        // if a specific theme is selected
        if let userInterfaceStyle = userInterfaceStyle {
            traitCollection = UITraitCollection(userInterfaceStyle: userInterfaceStyle)
            selectedUserInterfaceStyle = userInterfaceStyle
        }

        return AppTheme(
            appTintColor: UIColor(named: "appTintColor", in: nil, compatibleWith: traitCollection)!,

            backgroundColor: .systemBackground,

            titleTextColor: UIColor(named: "titleTextColor", in: nil, compatibleWith: traitCollection)!,
            textColor: UIColor(named: "textColor", in: nil, compatibleWith: traitCollection)!,
            lightTextColor: UIColor(named: "lightTextColor", in: nil, compatibleWith: traitCollection)!,

            cellHighlightColor: UIColor(named: "cellHighlightColor", in: nil, compatibleWith: traitCollection)!,
            separatorColor: UIColor(named: "separatorColor", in: nil, compatibleWith: traitCollection)!,

            groupedTableViewBackgroundColor: UIColor(named: "groupedTableViewBackgroundColor",
                                                     in: nil, compatibleWith: traitCollection)!,
            groupedTableViewCellBackgroundColor: UIColor(named: "groupedTableViewCellBackgroundColor",
                                                         in: nil, compatibleWith: traitCollection)!,
            upvotedColor: UIColor(named: "upvotedColor", in: nil, compatibleWith: traitCollection)!,

            userInterfaceStyle: selectedUserInterfaceStyle
        )
    }

    private static func currentTraitCollection() -> UITraitCollection {
        // use a fresh UIViewController uncontaminated by theme changes
        let viewController = UIViewController()
        return viewController.traitCollection
    }

    static let light = AppTheme.themeBuilder(.light)
    static let dark = AppTheme.themeBuilder(.dark)
    static var system: AppTheme {
        AppTheme.themeBuilder()
    }
}
