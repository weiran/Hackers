//
//  SettingsRepository.swift
//  Data
//
//  Copyright © 2025 Weiran Zhang. All rights reserved.
//

import Domain
import Foundation

public protocol UserDefaultsProtocol: Sendable {
    func bool(forKey defaultName: String) -> Bool
    func integer(forKey defaultName: String) -> Int
    func set(_ value: Bool, forKey defaultName: String)
    func set(_ value: Int, forKey defaultName: String)
    func set(_ value: Any?, forKey defaultName: String)
}

extension UserDefaults: UserDefaultsProtocol {}

public final class SettingsRepository: SettingsUseCase, @unchecked Sendable {
    private let userDefaults: UserDefaultsProtocol

    public init(userDefaults: UserDefaultsProtocol = UserDefaults.standard) {
        self.userDefaults = userDefaults
        registerDefaults()
    }

    private func registerDefaults() {
        // Register default values for fresh installs
        // Note: This only sets defaults for keys that don't exist yet
        if let userDefaults = userDefaults as? UserDefaults {
            userDefaults.register(defaults: [
                "safariReaderMode": false,
                "openInDefaultBrowser": false,
                "textSize": TextSize.medium.rawValue,
            ])
        }
    }

    public var safariReaderMode: Bool {
        get {
            userDefaults.bool(forKey: "safariReaderMode")
        }
        set {
            userDefaults.set(newValue, forKey: "safariReaderMode")
        }
    }

    public var openInDefaultBrowser: Bool {
        get {
            userDefaults.bool(forKey: "openInDefaultBrowser")
        }
        set {
            userDefaults.set(newValue, forKey: "openInDefaultBrowser")
        }
    }

    public var textSize: TextSize {
        get {
            let rawValue = userDefaults.integer(forKey: "textSize")
            return TextSize(rawValue: rawValue) ?? .medium
        }
        set {
            userDefaults.set(newValue.rawValue, forKey: "textSize")
        }
    }
}
