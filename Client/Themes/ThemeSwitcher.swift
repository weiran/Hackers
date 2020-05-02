//
//  ThemeSwitcher.swift
//  Hackers
//
//  Created by Weiran Zhang on 22/06/2019.
//  Copyright © 2019 Glass Umbrella. All rights reserved.
//

import UIKit

enum ThemeSwitcher {
    public static func switchTheme() {
        switch (UserDefaults.standard.systemThemeEnabled, UserDefaults.standard.darkModeEnabled) {
        case (true, _): AppThemeProvider.shared.currentTheme = .system
        case (false, false): AppThemeProvider.shared.currentTheme = .light
        case (false, true): AppThemeProvider.shared.currentTheme = .dark
        }
    }
}
