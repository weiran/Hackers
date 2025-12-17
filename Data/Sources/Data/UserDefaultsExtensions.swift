//
//  UserDefaultsExtensions.swift
//  Data
//
//  Copyright © 2025 Weiran Zhang. All rights reserved.
//

import Domain
import Foundation

public extension UserDefaults {
    var safariReaderModeEnabled: Bool {
        let safariReaderModeSetting = bool(forKey: UserDefaultsKeys.safariReaderMode.rawValue)
        return safariReaderModeSetting
    }

    func setSafariReaderMode(_ enabled: Bool) {
        set(enabled, forKey: UserDefaultsKeys.safariReaderMode.rawValue)
    }

    var linkBrowserMode: LinkBrowserMode {
        LinkBrowserMode(rawValue: integer(forKey: UserDefaultsKeys.linkBrowserMode.rawValue)) ?? .inAppBrowser
    }

    func setLinkBrowserMode(_ mode: LinkBrowserMode) {
        set(mode.rawValue, forKey: UserDefaultsKeys.linkBrowserMode.rawValue)
    }

    func registerDefaults() {
        register(defaults: [
            UserDefaultsKeys.safariReaderMode.rawValue: false,
            UserDefaultsKeys.linkBrowserMode.rawValue: LinkBrowserMode.customBrowser.rawValue
        ])
    }
}

public enum UserDefaultsKeys: String {
    case safariReaderMode
    case linkBrowserMode
}
