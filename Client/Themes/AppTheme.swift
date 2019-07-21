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

    var statusBarStyle: UIStatusBarStyle

    var barBackgroundColor: UIColor
    var barForegroundColor: UIColor
    var backgroundColor: UIColor

    var titleTextColor: UIColor
    var textColor: UIColor
    var lightTextColor: UIColor

    var cellHighlightColor: UIColor
    var separatorColor: UIColor

    var upvotedColor: UIColor

    var activityIndicatorStyle: UIActivityIndicatorView.Style
}

extension AppTheme {
    private static let appTintColorLight = UIColor(rgb: 0x6513E5)
    private static let appTintColorDark = UIColor(rgb: 0xA06FED)

    static let light = AppTheme(
        appTintColor: appTintColorLight,

        statusBarStyle: .default,

        barBackgroundColor: .white,
        barForegroundColor: appTintColorLight,
        backgroundColor: .white,

        titleTextColor: .black,
        textColor: UIColor(rgb: 0x555555),
        lightTextColor: UIColor(rgb: 0xAAAAAA),

        cellHighlightColor: UIColor(rgb: 0xF4D1F2),
        separatorColor: UIColor(rgb: 0xCACACA),

        upvotedColor: UIColor(rgb: 0xFF9300),

        activityIndicatorStyle: .gray
    )

    static let dark = AppTheme(
        appTintColor: appTintColorDark,

        statusBarStyle: .lightContent,

        barBackgroundColor: .black,
        barForegroundColor: appTintColorDark,
        backgroundColor: .black,

        titleTextColor: UIColor(rgb: 0xDDDDDD),
        textColor: UIColor(rgb: 0xAAAAAA),
        lightTextColor: UIColor(rgb: 0x555555),

        cellHighlightColor: UIColor(rgb: 0x34363D),
        separatorColor: UIColor(rgb: 0x757575),

        upvotedColor: UIColor(rgb: 0xFF9300),

        activityIndicatorStyle: .white
    )

    @available(iOS 13.0, *)
    static let dynamic = AppTheme(
        appTintColor: UIColor(named: "appTintColor") ?? appTintColorDark,

        statusBarStyle: .default,

        barBackgroundColor: .systemBackground,
        barForegroundColor: UIColor(named: "appTintColor") ?? appTintColorDark,
        backgroundColor: .systemBackground,

        titleTextColor: UIColor(named: "titleTextColor") ?? .label,
        textColor: UIColor(named: "textColor") ?? .secondaryLabel,
        lightTextColor: UIColor(named: "lightTextColor") ?? .tertiaryLabel,

        cellHighlightColor: UIColor(named: "cellHighlightColor") ?? UIColor(rgb: 0x34363D),
        separatorColor: UIColor(named: "separatorColor") ?? UIColor(rgb: 0x757575),

        upvotedColor: UIColor(named: "upvotedColor") ?? UIColor(rgb: 0xFF9300),

        activityIndicatorStyle: .medium
    )
}
