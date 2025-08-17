import Domain
import Foundation

public protocol UserDefaultsProtocol: Sendable {
    func bool(forKey defaultName: String) -> Bool
    func set(_ value: Bool, forKey defaultName: String)
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
                "showThumbnails": true,      // Default to true
                "swipeActions": true,        // Default to true
                "safariReaderMode": false,
                "showCommentsButton": false,
                "openInDefaultBrowser": false
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

    public var showThumbnails: Bool {
        get {
            userDefaults.bool(forKey: "showThumbnails")
        }
        set {
            userDefaults.set(newValue, forKey: "showThumbnails")
        }
    }

    public var swipeActions: Bool {
        get {
            userDefaults.bool(forKey: "swipeActions")
        }
        set {
            userDefaults.set(newValue, forKey: "swipeActions")
        }
    }

    public var showComments: Bool {
        get {
            userDefaults.bool(forKey: "showCommentsButton")
        }
        set {
            userDefaults.set(newValue, forKey: "showCommentsButton")
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
}