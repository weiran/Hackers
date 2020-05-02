//
//  UserDefaultsExtensions.swift
//  Hackers
//
//  Created by Weiran Zhang on 05/05/2018.
//  Copyright © 2018 Glass Umbrella. All rights reserved.
//

import Foundation

extension UserDefaults {
    public var darkModeEnabled: Bool {
        let themeSetting = string(forKey: UserDefaultsKeys.theme.rawValue)
        return themeSetting == "dark"
    }

    public func setDarkMode(_ enabled: Bool) {
        set(enabled ? "dark" : "light", forKey: UserDefaultsKeys.theme.rawValue)
    }

    public var systemThemeEnabled: Bool {
        let themeSetting = bool(forKey: UserDefaultsKeys.systemTheme.rawValue)
        return themeSetting
    }

    public func setSystemTheme(_ enabled: Bool) {
        set(enabled, forKey: UserDefaultsKeys.systemTheme.rawValue)
    }

    public var safariReaderModeEnabled: Bool {
        let safariReaderModeSetting = bool(forKey: UserDefaultsKeys.safariReaderMode.rawValue)
        return safariReaderModeSetting
    }

    public func setSafariReaderMode(_ enabled: Bool) {
        set(enabled, forKey: UserDefaultsKeys.safariReaderMode.rawValue)
    }

    public func registerDefaults() {
        register(defaults: [
            UserDefaultsKeys.theme.rawValue: "light",
            UserDefaultsKeys.systemTheme.rawValue: true,
            UserDefaultsKeys.safariReaderMode.rawValue: false
        ])
    }
}

enum UserDefaultsKeys: String {
    case theme
    case systemTheme
    case safariReaderMode
}
