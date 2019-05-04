//
//  Settings+UserDefaultsExtensions.swift
//  Hackers
//
//  Created by Weiran Zhang on 05/05/2018.
//  Copyright © 2018 Glass Umbrella. All rights reserved.
//

extension UserDefaults {
    public var darkModeEnabled: Bool {
        let themeSetting = string(forKey: UserDefaultsKeys.Theme.rawValue)
        return themeSetting == "dark"
    }
    
    public func setDarkMode(_ enabled: Bool) {
        set(enabled ? "dark" : "light", forKey: UserDefaultsKeys.Theme.rawValue)
    }
    
    public var safariReaderModeEnabled: Bool {
        let safariReaderModeSetting = bool(forKey: UserDefaultsKeys.SafariReaderMode.rawValue)
        return safariReaderModeSetting
    }
    
    public func setSafariReaderMode(_ enabled: Bool) {
        set(enabled, forKey: UserDefaultsKeys.SafariReaderMode.rawValue)
    }
}

enum UserDefaultsKeys: String {
    case Theme
    case SafariReaderMode
}
