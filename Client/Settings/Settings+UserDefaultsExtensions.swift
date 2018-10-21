//
//  Settings+UserDefaultsExtensions.swift
//  Hackers
//
//  Created by Weiran Zhang on 05/05/2018.
//  Copyright © 2018 Glass Umbrella. All rights reserved.
//

extension UserDefaults {
    public var enabledTheme: AppTheme {
        let themeSetting = string(forKey: UserDefaultsKeys.Theme.rawValue)
        switch themeSetting {
        case "Light":
            return AppTheme.light
        case "Dark":
            return AppTheme.dark
        case "Black":
            return AppTheme.black
        case "Original":
            return AppTheme.original
        default:
            return .light
        }
    }
    
    public func setTheme(_ themeKey: String) {
        set(themeKey, forKey: UserDefaultsKeys.Theme.rawValue)
    }
}

enum UserDefaultsKeys: String {
    case Theme
}
