//
//  Theme.swift
//  Hackers
//
//  Created by Weiran Zhang on 14/12/2015.
//  Copyright © 2015 Glass Umbrella. All rights reserved.
//

import UIKit

struct OldTheme {
    static let purpleColour = UIColor(red: 101/255.0, green: 19/255.0, blue: 229/255.0, alpha: 1)
    static let backgroundPurpleColour = UIColor(red:0.879, green:0.816, blue:0.951, alpha:1)
    
    static func setupNavigationBar(_ navigationBar: UINavigationBar?) {
        navigationBar?.barTintColor = .white
        navigationBar?.tintColor = purpleColour
        navigationBar?.setValue(true, forKey: "hidesShadow")
    }
}

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
        separatorColor: UIColor(rgb: 0xCACACA)
    )
    
    static let dark = AppTheme(
        appTintColor: appTintColorDark,
        
        statusBarStyle: .lightContent,
        
        barBackgroundColor: UIColor(rgb: 0x111111),
        barForegroundColor: appTintColorDark,
        backgroundColor: .black,
        
        titleTextColor: UIColor(rgb: 0xDDDDDD),
        textColor: UIColor(rgb: 0xAAAAAA),
        lightTextColor: UIColor(rgb: 0x555555),
        
        cellHighlightColor: UIColor(rgb: 0x34363D),
        separatorColor: UIColor(rgb: 0x757575)
    )
}
