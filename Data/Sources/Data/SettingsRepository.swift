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
    func string(forKey defaultName: String) -> String?
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
                "ShowThumbnails": true,
                "RememberFeedCategory": false,
                "textSize": TextSize.medium.rawValue
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

    public var showThumbnails: Bool {
        get {
            userDefaults.bool(forKey: "ShowThumbnails")
        }
        set {
            userDefaults.set(newValue, forKey: "ShowThumbnails")
        }
    }

    public var rememberFeedCategory: Bool {
        get {
            userDefaults.bool(forKey: "RememberFeedCategory")
        }
        set {
            userDefaults.set(newValue, forKey: "RememberFeedCategory")
            if newValue == false {
                userDefaults.set(nil, forKey: "LastFeedCategory")
            }
        }
    }

    public var lastFeedCategory: PostType? {
        get {
            guard let rawValue = userDefaults.string(forKey: "LastFeedCategory") else { return nil }
            return PostType(rawValue: rawValue)
        }
        set {
            userDefaults.set(newValue?.rawValue, forKey: "LastFeedCategory")
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

    public func clearCache() {
        // Remove all cached URL responses (affects AsyncImage and URLSession.shared consumers)
        URLCache.shared.removeAllCachedResponses()

        // Also purge temporary directory contents to reclaim space
        let fileManager = FileManager.default
        let tempDir = fileManager.temporaryDirectory
        if let items = try? fileManager.contentsOfDirectory(at: tempDir, includingPropertiesForKeys: nil) {
            for url in items {
                // Best-effort removal; ignore errors to avoid disrupting UX
                try? fileManager.removeItem(at: url)
            }
        }
    }

    public func cacheUsageBytes() async -> Int64 {
        let fileManager = FileManager.default

        func directorySize(at url: URL) -> Int64 {
            var total: Int64 = 0
            let resourceKeys: Set<URLResourceKey> = [
                .isRegularFileKey,
                .totalFileAllocatedSizeKey,
                .fileAllocatedSizeKey
            ]
            if let enumerator = fileManager.enumerator(
                at: url,
                includingPropertiesForKeys: Array(resourceKeys),
                options: [.skipsHiddenFiles, .skipsPackageDescendants]
            ) {
                for case let fileURL as URL in enumerator {
                    guard let values = try? fileURL.resourceValues(forKeys: resourceKeys),
                          values.isRegularFile == true
                    else { continue }
                    if let size = values.totalFileAllocatedSize ?? values.fileAllocatedSize {
                        total += Int64(size)
                    }
                }
            }
            return total
        }

        var total: Int64 = 0
        // Include Library/Caches where URLCache stores responses
        if let cachesURL = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first {
            total += directorySize(at: cachesURL)
        }
        // Include tmp directory where we might place transient files
        total += directorySize(at: fileManager.temporaryDirectory)
        return total
    }
}
