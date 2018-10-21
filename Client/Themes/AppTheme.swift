//
//  Theme.swift
//  Hackers
//
//  Created by Weiran Zhang on 14/12/2015.
//  Copyright © 2015 Glass Umbrella. All rights reserved.
//

import UIKit

public struct AppTheme {
    public var description: String

    var appTintColor: UIColor
    
    var statusBarStyle: UIStatusBarStyle
    
    var barBackgroundColor: UIColor
    var barForegroundColor: UIColor
    var navigationBarTextColor: UIColor
    var backgroundColor: UIColor
    
    var titleTextColor: UIColor
    var textColor: UIColor
    var lightTextColor: UIColor
    
    var cellHighlightColor: UIColor
    var separatorColor: UIColor
    
    var skeletonColor: UIColor

    var regularFontName: String
    var boldFontName: String
    var italicFontName: String
}

extension AppTheme {
    private static let appTintColorLight = UIColor(rgb: 0x6513E5)
    private static let appTintColorDark = UIColor(rgb: 0xA06FED)
    
    static let light = AppTheme(
        description: "Light",

        appTintColor: appTintColorLight,
        
        statusBarStyle: .default,
        
        barBackgroundColor: .white,
        barForegroundColor: appTintColorLight,
        navigationBarTextColor: .black,
        backgroundColor: .white,
        
        titleTextColor: .black,
        textColor: UIColor(rgb: 0x555555),
        lightTextColor: UIColor(rgb: 0xAAAAAA),
        
        cellHighlightColor: UIColor(rgb: 0xF4D1F2),
        separatorColor: UIColor(rgb: 0xCACACA),
        
        skeletonColor: UIColor(rgb: 0xAAAAAA),

        regularFontName: UIFont.systemFont(ofSize: 1).fontName,
        boldFontName: UIFont.boldSystemFont(ofSize: 1).fontName,
        italicFontName: UIFont.italicSystemFont(ofSize: 1).fontName
    )
    
    static let dark = AppTheme(
        description: "Dark",

        appTintColor: appTintColorDark,
        
        statusBarStyle: .lightContent,
        
        barBackgroundColor: UIColor(rgb: 0x111111),
        barForegroundColor: appTintColorDark,
        navigationBarTextColor: UIColor(rgb: 0xDDDDDD),
        backgroundColor: .black,
        
        titleTextColor: UIColor(rgb: 0xDDDDDD),
        textColor: UIColor(rgb: 0xAAAAAA),
        lightTextColor: UIColor(rgb: 0x555555),
        
        cellHighlightColor: UIColor(rgb: 0x34363D),
        separatorColor: UIColor(rgb: 0x757575),
        
        skeletonColor: UIColor(rgb: 0x555555),

        regularFontName: UIFont.systemFont(ofSize: 1).fontName,
        boldFontName: UIFont.boldSystemFont(ofSize: 1).fontName,
        italicFontName: UIFont.italicSystemFont(ofSize: 1).fontName
    )

    static let black = AppTheme(
        description: "Black",

        appTintColor: .white,

        statusBarStyle: .lightContent,

        barBackgroundColor: .black,
        barForegroundColor: .white,
        navigationBarTextColor: .white,
        backgroundColor: .black,

        titleTextColor: .white,
        textColor: .white,
        lightTextColor: .white,

        cellHighlightColor: UIColor(rgb: 0x555555),
        separatorColor: .white,

        skeletonColor: UIColor(rgb: 0x555555),

        regularFontName: UIFont.systemFont(ofSize: 1).fontName,
        boldFontName: UIFont.boldSystemFont(ofSize: 1).fontName,
        italicFontName: UIFont.italicSystemFont(ofSize: 1).fontName
    )

    static let original = AppTheme(
        description: "Original",

        appTintColor: .white,

        statusBarStyle: .lightContent,

        barBackgroundColor: UIColor(rgb: 0xFF6600),
        barForegroundColor: .white,
        navigationBarTextColor: .white,
        backgroundColor: .white,

        titleTextColor: .black,
        textColor: .black,
        lightTextColor: UIColor(rgb: 0x828282),

        cellHighlightColor: UIColor(rgb: 0xF6F6F6),
        separatorColor: UIColor(rgb: 0x5A5A5A),

        skeletonColor: UIColor(rgb: 0xF6F6F6),

        regularFontName: "Verdana",
        boldFontName: "Verdana-Bold",
        italicFontName: "Verdana-Italic"
    )
}
