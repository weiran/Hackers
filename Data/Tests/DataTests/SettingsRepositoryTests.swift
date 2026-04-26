//
//  SettingsRepositoryTests.swift
//  DataTests
//
//  Copyright © 2025 Weiran Zhang. All rights reserved.
//

// swiftlint:disable force_cast

@testable import Data
@testable import Domain
import Foundation
import Testing

@Suite("SettingsRepository Tests")
struct SettingsRepositoryTests {
    let mockUserDefaults = MockUserDefaults()
    var settingsRepository: SettingsRepository {
        SettingsRepository(userDefaults: mockUserDefaults)
    }

    // MARK: - Mock UserDefaults

    final class MockUserDefaults: UserDefaultsProtocol, @unchecked Sendable {
        private var storage: [String: Any] = [:]
        private let lock = NSLock()

        func object(forKey defaultName: String) -> Any? {
            lock.lock(); defer { lock.unlock() }
            return storage[defaultName]
        }

        func bool(forKey defaultName: String) -> Bool {
            lock.lock(); defer { lock.unlock() }
            return storage[defaultName] as? Bool ?? false
        }

        func integer(forKey defaultName: String) -> Int {
            lock.lock(); defer { lock.unlock() }
            return storage[defaultName] as? Int ?? 0
        }

        func string(forKey defaultName: String) -> String? {
            lock.lock(); defer { lock.unlock() }
            return storage[defaultName] as? String
        }

        func set(_ value: Bool, forKey defaultName: String) {
            lock.lock(); defer { lock.unlock() }
            storage[defaultName] = value
        }

        func set(_ value: Int, forKey defaultName: String) {
            lock.lock(); defer { lock.unlock() }
            storage[defaultName] = value
        }

        func set(_ value: Any?, forKey defaultName: String) {
            lock.lock(); defer { lock.unlock() }
            storage[defaultName] = value
        }

        func removeObject(forKey defaultName: String) {
            lock.lock(); defer { lock.unlock() }
            storage.removeValue(forKey: defaultName)
        }

        func clearAll() {
            lock.lock(); defer { lock.unlock() }
            storage.removeAll()
        }
    }

    // MARK: - Initialization Tests

    @Test("SettingsRepository initialization")
    func settingsRepositoryInitialization() {
        #expect(settingsRepository != nil, "SettingsRepository should initialize successfully")
    }

    @Test("SettingsRepository initialization with default UserDefaults")
    func settingsRepositoryInitializationWithDefaultUserDefaults() {
        let repository = SettingsRepository()
        #expect(repository != nil)
    }

    // MARK: - Safari Reader Mode Tests

    @Test("Safari reader mode default value")
    func safariReaderModeDefaultValue() {
        // Default should be false for bool values
        #expect(settingsRepository.safariReaderMode == false)
    }

    @Test("Safari reader mode setter and getter")
    func safariReaderModeSetterAndGetter() {
        // Test setting to true
        settingsRepository.safariReaderMode = true
        #expect(settingsRepository.safariReaderMode == true)
        #expect(mockUserDefaults.bool(forKey: "safariReaderMode") == true)

        // Test setting to false
        settingsRepository.safariReaderMode = false
        #expect(settingsRepository.safariReaderMode == false)
        #expect(mockUserDefaults.bool(forKey: "safariReaderMode") == false)
    }

    // MARK: - Thumbnail Settings Tests

    @Test("Show thumbnails default value")
    func showThumbnailsDefaultValue() {
        mockUserDefaults.clearAll()
        mockUserDefaults.set(true, forKey: "ShowThumbnails")

        let repository = SettingsRepository(userDefaults: mockUserDefaults)

        #expect(repository.showThumbnails == true)
    }

    @Test("Show thumbnails setter and getter")
    func showThumbnailsSetterAndGetter() {
        mockUserDefaults.clearAll()

        let repository = SettingsRepository(userDefaults: mockUserDefaults)

        // Test setting to false
        repository.showThumbnails = false
        #expect(repository.showThumbnails == false)
        #expect(mockUserDefaults.bool(forKey: "ShowThumbnails") == false)

        // Test setting to true
        repository.showThumbnails = true
        #expect(repository.showThumbnails == true)
        #expect(mockUserDefaults.bool(forKey: "ShowThumbnails") == true)
    }

    // MARK: - Remember Feed Category Tests

    @Test("Remember feed category default value")
    func rememberFeedCategoryDefaultValue() {
        mockUserDefaults.clearAll()

        let repository = SettingsRepository(userDefaults: mockUserDefaults)

        #expect(repository.rememberFeedCategory == false)
    }

    @Test("Remember feed category setter clears stored category when disabled")
    func rememberFeedCategorySetter() {
        mockUserDefaults.clearAll()

        let repository = SettingsRepository(userDefaults: mockUserDefaults)

        repository.rememberFeedCategory = true
        #expect(repository.rememberFeedCategory == true)
        repository.lastFeedCategory = .ask
        repository.rememberFeedCategory = false

        #expect(repository.rememberFeedCategory == false)
        #expect(repository.lastFeedCategory == nil)
        #expect(mockUserDefaults.string(forKey: "LastFeedCategory") == nil)
    }

    @Test("Last feed category getter and setter")
    func lastFeedCategoryGetterSetter() {
        mockUserDefaults.clearAll()

        let repository = SettingsRepository(userDefaults: mockUserDefaults)

        repository.lastFeedCategory = .best
        #expect(repository.lastFeedCategory == .best)
        #expect(mockUserDefaults.string(forKey: "LastFeedCategory") == PostType.best.rawValue)
    }

    // MARK: - Removed Settings (showComments)

    // Note: showComments setting has been removed from the app

    // MARK: - Link Browser Mode Tests

    @Test("Link browser mode default value")
    func linkBrowserModeDefaultValue() {
        #expect(settingsRepository.linkBrowserMode == .customBrowser)
        #expect(mockUserDefaults.integer(forKey: "linkBrowserMode") == LinkBrowserMode.customBrowser.rawValue)
    }

    @Test("Link browser mode setter and getter")
    func linkBrowserModeSetterAndGetter() {
        settingsRepository.linkBrowserMode = .systemBrowser
        #expect(settingsRepository.linkBrowserMode == .systemBrowser)
        #expect(mockUserDefaults.integer(forKey: "linkBrowserMode") == LinkBrowserMode.systemBrowser.rawValue)

        settingsRepository.linkBrowserMode = .customBrowser
        #expect(settingsRepository.linkBrowserMode == .customBrowser)
        #expect(mockUserDefaults.integer(forKey: "linkBrowserMode") == LinkBrowserMode.customBrowser.rawValue)
    }

    // MARK: - Integration Tests

    @Test("Multiple settings changes persist")
    func multipleSettingsChangesPersist() {
        // Change multiple settings
        settingsRepository.safariReaderMode = true
        settingsRepository.linkBrowserMode = .customBrowser

        // Verify all changes persist
        #expect(settingsRepository.safariReaderMode == true)
        #expect(settingsRepository.linkBrowserMode == .customBrowser)

        // Verify underlying storage
        #expect(mockUserDefaults.bool(forKey: "safariReaderMode") == true)
        #expect(mockUserDefaults.integer(forKey: "linkBrowserMode") == LinkBrowserMode.customBrowser.rawValue)
    }

    @Test("Settings independence")
    func settingsIndependence() {
        // Test that changing one setting doesn't affect others
        settingsRepository.safariReaderMode = true

        // Other settings should remain at their default values
        #expect(settingsRepository.linkBrowserMode == .customBrowser)
    }

    // MARK: - Use Case Protocol Conformance Tests

    @Test("Conforms to SettingsUseCase")
    func conformsToSettingsUseCase() {
        // Test that the repository properly conforms to SettingsUseCase protocol
        var useCase: SettingsUseCase = settingsRepository

        // Test that we can access properties through the protocol
        useCase.safariReaderMode = true
        #expect(useCase.safariReaderMode == true)

        useCase.linkBrowserMode = .systemBrowser
        #expect(useCase.linkBrowserMode == .systemBrowser)
    }

    // MARK: - Key Consistency Tests

    @Test("UserDefaults keys")
    func userDefaultsKeys() {
        // Test that the correct keys are being used for UserDefaults
        settingsRepository.safariReaderMode = true
        settingsRepository.linkBrowserMode = .customBrowser

        // Verify the keys match what's expected
        #expect(mockUserDefaults.bool(forKey: "safariReaderMode") == true)
        #expect(mockUserDefaults.integer(forKey: "linkBrowserMode") == LinkBrowserMode.customBrowser.rawValue)
    }

    // MARK: - Thread Safety Tests

    @Test("Concurrent access")
    func concurrentAccess() async {
        // Test concurrent read/write operations
        await withTaskGroup(of: Void.self) { group in
            // Add multiple concurrent tasks
            for _ in 0 ..< 10 {
                group.addTask {
                    settingsRepository.safariReaderMode = true
                    settingsRepository.linkBrowserMode = .customBrowser
                }
            }
        }

        // After concurrent operations, both values should be true
        let safariMode = settingsRepository.safariReaderMode
        let mode = settingsRepository.linkBrowserMode

        #expect(safariMode == true)
        #expect(mode == .customBrowser)
    }
}
