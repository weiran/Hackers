//
//  UserDefaultsExtensions.swift
//  Data
//
//  Copyright © 2025 Weiran Zhang. All rights reserved.
//

import Foundation

public extension UserDefaults {
    var safariReaderModeEnabled: Bool {
        let safariReaderModeSetting = bool(forKey: UserDefaultsKeys.safariReaderMode.rawValue)
        return safariReaderModeSetting
    }

    func setSafariReaderMode(_ enabled: Bool) {
        set(enabled, forKey: UserDefaultsKeys.safariReaderMode.rawValue)
    }

    var openInDefaultBrowser: Bool {
        let openInDefaultBrowser = bool(forKey: UserDefaultsKeys.openInDefaultBrowser.rawValue)
        return openInDefaultBrowser
    }

    func setOpenInDefaultBrowser(_ enabled: Bool) {
        set(enabled, forKey: UserDefaultsKeys.openInDefaultBrowser.rawValue)
    }

    func registerDefaults() {
        register(defaults: [
            UserDefaultsKeys.safariReaderMode.rawValue: false,
            UserDefaultsKeys.openInDefaultBrowser.rawValue: false,
        ])
    }
}

public enum UserDefaultsKeys: String {
    case safariReaderMode
    case openInDefaultBrowser
}
