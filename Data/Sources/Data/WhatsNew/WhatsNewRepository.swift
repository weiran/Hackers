//
//  WhatsNewRepository.swift
//  Data
//
//  Copyright © 2025 Weiran Zhang. All rights reserved.
//

import Domain
import Foundation

public protocol WhatsNewVersionStore: Sendable {
    func lastShownVersion() -> String?
    func save(shownVersion: String)
}

public final class UserDefaultsWhatsNewVersionStore: WhatsNewVersionStore, @unchecked Sendable {
    private let userDefaults: UserDefaults
    private let key = "com.weiran.hackers.whatsnew.shownVersion"

    private init(storage: UserDefaults) {
        userDefaults = storage
    }

    public convenience init(userDefaults: UserDefaults) {
        self.init(storage: userDefaults)
    }

    public convenience init() {
        let suite = "com.weiran.hackers.whatsnew"
        let defaults = UserDefaults(suiteName: suite) ?? .standard
        self.init(storage: defaults)
    }

    public func lastShownVersion() -> String? {
        userDefaults.string(forKey: key)
    }

    public func save(shownVersion: String) {
        userDefaults.set(shownVersion, forKey: key)
    }
}

public final class WhatsNewRepository: WhatsNewUseCase, @unchecked Sendable {
    private let versionStore: WhatsNewVersionStore
    private let processArguments: [String]

    public init(
        versionStore: WhatsNewVersionStore = UserDefaultsWhatsNewVersionStore(),
        processArguments: [String] = ProcessInfo.processInfo.arguments
    ) {
        self.versionStore = versionStore
        self.processArguments = processArguments
    }

    public func shouldShowWhatsNew(currentVersion: String, forceShow: Bool) -> Bool {
        if processArguments.contains("disableWhatsNew"), !forceShow {
            return false
        }

        if forceShow { return true }

        guard let lastShownVersion = versionStore.lastShownVersion() else {
            versionStore.save(shownVersion: currentVersion)
            return false
        }

        return shouldShowBasedOnMinorRelease(currentVersion: currentVersion, lastShownVersion: lastShownVersion)
    }

    public func markWhatsNewShown(for version: String) {
        versionStore.save(shownVersion: version)
    }

    private func shouldShowBasedOnMinorRelease(currentVersion: String, lastShownVersion: String) -> Bool {
        guard
            let current = SemanticVersion(versionString: currentVersion),
            let last = SemanticVersion(versionString: lastShownVersion)
        else {
            return currentVersion != lastShownVersion
        }

        if current.major > last.major { return true }
        if current.major < last.major { return false }

        return current.minor > last.minor
    }
}

private struct SemanticVersion {
    let major: Int
    let minor: Int

    init?(versionString: String) {
        let components = versionString.split(separator: ".")
        guard let majorComponent = components.first, let major = Int(majorComponent) else {
            return nil
        }

        let minorComponent = components.dropFirst().first
        let minor = minorComponent.flatMap { Int($0) } ?? 0

        self.major = major
        self.minor = minor
    }
}
