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
    }

    public var safariReaderMode: Bool {
        get {
            userDefaults.bool(forKey: "SafariReaderMode")
        }
        set {
            userDefaults.set(newValue, forKey: "SafariReaderMode")
        }
    }

    public var showThumbnails: Bool {
        get {
            userDefaults.bool(forKey: "ShowThumbnails")
        }
        set {
            userDefaults.set(newValue, forKey: "ShowThumbnails")
        }
    }

    public var swipeActions: Bool {
        get {
            userDefaults.bool(forKey: "SwipeActionsEnabled")
        }
        set {
            userDefaults.set(newValue, forKey: "SwipeActionsEnabled")
        }
    }

    public var showComments: Bool {
        get {
            userDefaults.bool(forKey: "ShowCommentsButton")
        }
        set {
            userDefaults.set(newValue, forKey: "ShowCommentsButton")
        }
    }

    public var openInDefaultBrowser: Bool {
        get {
            userDefaults.bool(forKey: "OpenInDefaultBrowser")
        }
        set {
            userDefaults.set(newValue, forKey: "OpenInDefaultBrowser")
        }
    }
}