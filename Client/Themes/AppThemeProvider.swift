//
//  AppThemeProvider.swift
//  Night Mode
//
//  Created by Michael on 01/04/2018.
//  Copyright © 2018 Late Night Swift. All rights reserved.
//

import UIKit

final class AppThemeProvider: ThemeProvider {
    static let shared: AppThemeProvider = .init()

    private var theme: SubscribableValue<AppTheme>
    private var availableThemes: [AppTheme] = [.light, .dark]

    var currentTheme: AppTheme {
        get {
            return theme.value
        }
        set {
            setNewTheme(newValue)
        }
    }

    init() {
        if #available(iOS 13, *) {
            theme = SubscribableValue<AppTheme>(value: .system)
        } else {
            theme = SubscribableValue<AppTheme>(value: .light)
        }
    }

    private func setNewTheme(_ newTheme: AppTheme) {
        let window = UIApplication.shared.delegate!.window!!
        UIView.transition(
            with: window,
            duration: 0.3,
            options: [UIView.AnimationOptions.transitionCrossDissolve],
            animations: {
                self.theme.value = newTheme
            }
        )
    }

    func subscribeToChanges(_ object: AnyObject, handler: @escaping (AppTheme) -> Void) {
        theme.subscribe(object, using: handler)
    }
}

extension Themed where Self: AnyObject {
    var themeProvider: AppThemeProvider {
        return AppThemeProvider.shared
    }
}
