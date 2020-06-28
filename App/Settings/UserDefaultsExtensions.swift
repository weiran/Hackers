//
//  UserDefaultsExtensions.swift
//  Hackers
//
//  Created by Weiran Zhang on 05/05/2018.
//  Copyright © 2018 Weiran Zhang. All rights reserved.
//

import Foundation

extension UserDefaults {
    var darkModeEnabled: Bool {
        let themeSetting = string(forKey: UserDefaultsKeys.theme.rawValue)
        return themeSetting == "dark"
    }

    func setDarkMode(_ enabled: Bool) {
        set(enabled ? "dark" : "light", forKey: UserDefaultsKeys.theme.rawValue)
    }

    var systemThemeEnabled: Bool {
        let themeSetting = bool(forKey: UserDefaultsKeys.systemTheme.rawValue)
        return themeSetting
    }

    func setSystemTheme(_ enabled: Bool) {
        set(enabled, forKey: UserDefaultsKeys.systemTheme.rawValue)
    }

    var showThumbnails: Bool {
        let showThumbnails = bool(forKey: UserDefaultsKeys.showThumbnails.rawValue)
        return showThumbnails
    }

    func setShowThumbnails(_ enabled: Bool) {
        set(enabled, forKey: UserDefaultsKeys.showThumbnails.rawValue)
    }

    var safariReaderModeEnabled: Bool {
        let safariReaderModeSetting = bool(forKey: UserDefaultsKeys.safariReaderMode.rawValue)
        return safariReaderModeSetting
    }

    func setSafariReaderMode(_ enabled: Bool) {
        set(enabled, forKey: UserDefaultsKeys.safariReaderMode.rawValue)
    }

    func registerDefaults() {
        register(defaults: [
            UserDefaultsKeys.theme.rawValue: "light",
            UserDefaultsKeys.systemTheme.rawValue: true,
            UserDefaultsKeys.showThumbnails.rawValue: true,
            UserDefaultsKeys.safariReaderMode.rawValue: false
        ])
    }
}

enum UserDefaultsKeys: String {
    case theme
    case systemTheme
    case safariReaderMode
    case showThumbnails
}
