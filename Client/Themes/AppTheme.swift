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
    private static let appTintColorLight = UIColor(rgb: 0x6513E5)
    private static let appTintColorDark = UIColor(rgb: 0xA06FED)

    static let light = AppTheme(
        appTintColor: appTintColorLight,

        statusBarStyle: .darkContent,

        backgroundColor: .white,

        titleTextColor: .black,
        textColor: UIColor(rgb: 0x555555),
        lightTextColor: UIColor(rgb: 0xAAAAAA),

        cellHighlightColor: UIColor(rgb: 0xF4D1F2),
        separatorColor: UIColor(rgb: 0xCACACA),

        groupedTableViewBackgroundColor: UIColor(rgb: 0xF2F2F7),
        groupedTableViewCellBackgroundColor: .white,

        upvotedColor: UIColor(rgb: 0xFF9300),

        userInterfaceStyle: .light
    )

    static let dark = AppTheme(
        appTintColor: appTintColorDark,

        statusBarStyle: .lightContent,

        backgroundColor: .black,

        titleTextColor: UIColor(rgb: 0xDDDDDD),
        textColor: UIColor(rgb: 0xAAAAAA),
        lightTextColor: UIColor(rgb: 0x555555),

        cellHighlightColor: UIColor(rgb: 0x34363D),
        separatorColor: UIColor(rgb: 0x757575),

        // these are colours for a presented VC
        groupedTableViewBackgroundColor: UIColor(rgb: 0x1c1c1e),
        groupedTableViewCellBackgroundColor: UIColor(rgb: 0x2c2c2e),

        upvotedColor: UIColor(rgb: 0xFF9300),

        userInterfaceStyle: .dark
    )
}
