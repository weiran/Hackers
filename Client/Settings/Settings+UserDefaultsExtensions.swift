//
//  Settings+UserDefaultsExtensions.swift
//  Hackers
//
//  Created by Weiran Zhang on 05/05/2018.
//  Copyright © 2018 Glass Umbrella. All rights reserved.
//

import SafariServices

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

    public func openInBrowser(_ url: URL) -> ThemedSafariViewController? {
        let browserSetting = string(forKey: UserDefaultsKeys.OpenInBrowser.rawValue)
        switch browserSetting {
        case "Google Chrome":
            if OpenInChromeController.sharedInstance.isChromeInstalled() {
                _ = OpenInChromeController.sharedInstance.openInChrome(url, callbackURL: nil)
            } else { // User uninstalled Chrome, fallback to Safari
                UserDefaults.standard.setOpenLinksIn("Safari")
                UIApplication.shared.open(url)
            }
            return nil
        case "Safari":
            UIApplication.shared.open(url)
            return nil
        case "In-app browser (Reader mode)":
            let config = SFSafariViewController.Configuration.init()
            config.barCollapsingEnabled = true
            config.entersReaderIfAvailable = true
            return ThemedSafariViewController(url: url, configuration: config)
        default:
            let config = SFSafariViewController.Configuration.init()
            config.barCollapsingEnabled = true
            return ThemedSafariViewController(url: url, configuration: config)
        }
    }

    public func setOpenLinksIn(_ browserName: String) {
        set(browserName, forKey: UserDefaultsKeys.OpenInBrowser.rawValue)
    }
}

enum UserDefaultsKeys: String {
    case Theme
    case OpenInBrowser
}
