//
//  SettingsStore.swift
//  Hackers
//
//  Created by Weiran Zhang on 22/06/2019.
//  Copyright © 2019 Glass Umbrella. All rights reserved.
//

import SwiftUI
import Combine
import UIKit

class SettingsStore: ObservableObject {
    var didChange = PassthroughSubject<Void, Never>()

    private enum Keys {
        static let theme = "theme"
        static let safariReaderMode = "safariReaderMode"
        static let username = "username"
    }

    private let cancellable: Cancellable
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        defaults.register(defaults: [
            Keys.theme: ThemeType.system.rawValue,
            Keys.safariReaderMode: false
        ])

        cancellable = NotificationCenter.default
            .publisher(for: UserDefaults.didChangeNotification)
            .map { _ in () }
            .subscribe(didChange)
    }

    enum ThemeType: String, CaseIterable {
        case system
        case dark
        case light
    }

    var theme: ThemeType {
        set {
            defaults.set(newValue.rawValue, forKey: Keys.theme)
            ThemeSwitcher.switchTheme()
        }
        get { return defaults.string(forKey: Keys.theme)
            .flatMap { ThemeType(rawValue: $0) } ?? .system
        }
    }

    var safariReaderMode: Bool {
        set { defaults.set(newValue, forKey: Keys.safariReaderMode) }
        get { return defaults.bool(forKey: Keys.safariReaderMode) }
    }

    var username: String? {
        set { defaults.set(newValue, forKey: Keys.username) }
        get { return defaults.string(forKey: Keys.username) }
    }
}
