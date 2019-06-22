//
//  Theming.swift
//  Hackers
//
//  Created by Weiran Zhang on 05/05/2018.
//  Copyright © 2018 Glass Umbrella. All rights reserved.
//

import Foundation

/// Describes a type that holds a current `Theme` and allows
/// an object to be notified when the theme is changed.
protocol ThemeProvider {
    /// Placeholder for the theme type that the app will use
    associatedtype Theme

    /// The current theme that is active
    var currentTheme: Theme { get }

    /// Subscribe to be notified when the theme changes. Handler will be
    /// remove from subscription when `object` is deallocated.
    func subscribeToChanges(_ object: AnyObject, handler: @escaping (Theme) -> Void)
}

/// Describes a type that can have a theme applied to it
protocol Themed {
    /// A Themed type needs to know about what concrete type the
    /// ThemeProvider is. So we don't clash with the protocol,
    /// let's call this associated type _ThemeProvider
    associatedtype T: ThemeProvider

    /// Return the current app-wide theme provider
    var themeProvider: T { get }

    /// This will be called whenever the current theme changes
    func applyTheme(_ theme: T.Theme)
}

extension Themed where Self: AnyObject {
    /// This is to be called once when Self wants to start listening for
    /// theme changes. This immediately triggers `applyTheme()` with the
    /// current theme.
    func setupTheming() {
        applyTheme(themeProvider.currentTheme)
        themeProvider.subscribeToChanges(self) { [weak self] newTheme in
            self?.applyTheme(newTheme)
        }
    }
}
