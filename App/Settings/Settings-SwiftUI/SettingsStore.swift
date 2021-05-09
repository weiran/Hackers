//
//  SettingsStore.swift
//  Hackers
//
//  Created by Weiran Zhang on 22/06/2019.
//  Copyright © 2019 Weiran Zhang. All rights reserved.
//

import SwiftUI
import Combine
import UIKit

class SettingsStore: ObservableObject {
    var didChange = PassthroughSubject<Void, Never>()

    private enum Keys {
        static let safariReaderMode = "safariReaderMode"
        static let username = "username"
    }

    private let cancellable: Cancellable
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        defaults.register(defaults: [
            Keys.safariReaderMode: false
        ])

        cancellable = NotificationCenter.default
            .publisher(for: UserDefaults.didChangeNotification)
            .map { _ in () }
            .subscribe(didChange)
    }

    var safariReaderMode: Bool {
        get { return defaults.bool(forKey: Keys.safariReaderMode) }
        set { defaults.set(newValue, forKey: Keys.safariReaderMode) }
    }

    var username: String? {
        get { return defaults.string(forKey: Keys.username) }
        set { defaults.set(newValue, forKey: Keys.username) }
    }
}
