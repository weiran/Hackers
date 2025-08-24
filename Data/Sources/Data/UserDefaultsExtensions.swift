//
//  UserDefaultsExtensions.swift
//  Data
//
//  Copyright © 2025 Weiran Zhang. All rights reserved.
//

import Foundation

public extension UserDefaults {
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

    var swipeActionsEnabled: Bool {
        let swipeActionsSetting = bool(forKey: UserDefaultsKeys.swipeActions.rawValue)
        return swipeActionsSetting
    }

    var showCommentsButton: Bool {
        return bool(forKey: UserDefaultsKeys.showCommentsButton.rawValue)
    }

    func setShowCommentsButton(_ enabled: Bool) {
        set(enabled, forKey: UserDefaultsKeys.showCommentsButton.rawValue)
    }

    func setSwipeActions(_ enabled: Bool) {
        set(enabled, forKey: UserDefaultsKeys.swipeActions.rawValue)
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
            UserDefaultsKeys.theme.rawValue: "light",
            UserDefaultsKeys.systemTheme.rawValue: true,
            UserDefaultsKeys.showThumbnails.rawValue: true,
            UserDefaultsKeys.swipeActions.rawValue: true,
            UserDefaultsKeys.showCommentsButton.rawValue: false,
            UserDefaultsKeys.safariReaderMode.rawValue: false,
            UserDefaultsKeys.openInDefaultBrowser.rawValue: false
        ])
    }
}

public enum UserDefaultsKeys: String {
    case theme
    case systemTheme
    case safariReaderMode
    case openInDefaultBrowser
    case showThumbnails
    case swipeActions
    case showCommentsButton
}
