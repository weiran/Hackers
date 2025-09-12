//
//  SettingsRepositoryTests.swift
//  DataTests
//
//  Copyright © 2025 Weiran Zhang. All rights reserved.
//

// swiftlint:disable force_cast

import Testing
@testable import Data
@testable import Domain
import Foundation

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

        func bool(forKey defaultName: String) -> Bool {
            lock.lock(); defer { lock.unlock() }
            return storage[defaultName] as? Bool ?? false
        }

        func set(_ value: Bool, forKey defaultName: String) {
            lock.lock(); defer { lock.unlock() }
            storage[defaultName] = value
        }

        func string(forKey defaultName: String) -> String? {
            lock.lock(); defer { lock.unlock() }
            return storage[defaultName] as? String
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
        #expect(mockUserDefaults.bool(forKey: "SafariReaderMode") == true)

        // Test setting to false
        settingsRepository.safariReaderMode = false
        #expect(settingsRepository.safariReaderMode == false)
        #expect(mockUserDefaults.bool(forKey: "SafariReaderMode") == false)
    }

    // MARK: - Removed Settings Tests
    // Note: showThumbnails and swipeActions settings have been removed from the app
    
    /*
    @Test("Show thumbnails default value")
    func showThumbnailsDefaultValue() {
        // Default should be false for bool values
        #expect(settingsRepository.showThumbnails == false)
    }

    @Test("Show thumbnails setter and getter")
    func showThumbnailsSetterAndGetter() {
        // Test setting to true
        settingsRepository.showThumbnails = true
        #expect(settingsRepository.showThumbnails == true)
        #expect(mockUserDefaults.bool(forKey: "ShowThumbnails") == true)

        // Test setting to false
        settingsRepository.showThumbnails = false
        #expect(settingsRepository.showThumbnails == false)
        #expect(mockUserDefaults.bool(forKey: "ShowThumbnails") == false)
    }

    @Test("Swipe actions default value")
    func swipeActionsDefaultValue() {
        // Default should be false for bool values
        #expect(settingsRepository.swipeActions == false)
    }

    @Test("Swipe actions setter and getter")
    func swipeActionsSetterAndGetter() {
        // Test setting to true
        settingsRepository.swipeActions = true
        #expect(settingsRepository.swipeActions == true)
        #expect(mockUserDefaults.bool(forKey: "SwipeActionsEnabled") == true)

        // Test setting to false
        settingsRepository.swipeActions = false
        #expect(settingsRepository.swipeActions == false)
        #expect(mockUserDefaults.bool(forKey: "SwipeActionsEnabled") == false)
    }
    */

    // MARK: - Removed Settings (showComments)
    // Note: showComments setting has been removed from the app

    // MARK: - Open In Default Browser Tests

    @Test("Open in default browser default value")
    func openInDefaultBrowserDefaultValue() {
        // Default should be false for bool values
        #expect(settingsRepository.openInDefaultBrowser == false)
    }

    @Test("Open in default browser setter and getter")
    func openInDefaultBrowserSetterAndGetter() {
        // Test setting to true
        settingsRepository.openInDefaultBrowser = true
        #expect(settingsRepository.openInDefaultBrowser == true)
        #expect(mockUserDefaults.bool(forKey: "OpenInDefaultBrowser") == true)

        // Test setting to false
        settingsRepository.openInDefaultBrowser = false
        #expect(settingsRepository.openInDefaultBrowser == false)
        #expect(mockUserDefaults.bool(forKey: "OpenInDefaultBrowser") == false)
    }

    // MARK: - Integration Tests

    @Test("Multiple settings changes persist")
    func multipleSettingsChangesPersist() {
        // Change multiple settings
        settingsRepository.safariReaderMode = true
        settingsRepository.openInDefaultBrowser = true

        // Verify all changes persist
        #expect(settingsRepository.safariReaderMode == true)
        #expect(settingsRepository.openInDefaultBrowser == true)

        // Verify underlying storage
        #expect(mockUserDefaults.bool(forKey: "SafariReaderMode") == true)
        #expect(mockUserDefaults.bool(forKey: "OpenInDefaultBrowser") == true)
    }

    @Test("Settings independence")
    func settingsIndependence() {
        // Test that changing one setting doesn't affect others
        settingsRepository.safariReaderMode = true

        // Other settings should remain at their default values
        #expect(settingsRepository.openInDefaultBrowser == false)
    }

    // MARK: - Use Case Protocol Conformance Tests

    @Test("Conforms to SettingsUseCase")
    func conformsToSettingsUseCase() {
        // Test that the repository properly conforms to SettingsUseCase protocol
        var useCase: SettingsUseCase = settingsRepository

        // Test that we can access properties through the protocol
        useCase.safariReaderMode = true
        #expect(useCase.safariReaderMode == true)

        useCase.openInDefaultBrowser = true
        #expect(useCase.openInDefaultBrowser == true)
    }

    // MARK: - Key Consistency Tests

    @Test("UserDefaults keys")
    func userDefaultsKeys() {
        // Test that the correct keys are being used for UserDefaults
        settingsRepository.safariReaderMode = true
        settingsRepository.openInDefaultBrowser = true

        // Verify the keys match what's expected
        #expect(mockUserDefaults.bool(forKey: "SafariReaderMode") == true)
        #expect(mockUserDefaults.bool(forKey: "OpenInDefaultBrowser") == true)
    }

    // MARK: - Thread Safety Tests

    @Test("Concurrent access")
    func concurrentAccess() async {
        // Test concurrent read/write operations
        await withTaskGroup(of: Void.self) { group in
            // Add multiple concurrent tasks
            for _ in 0..<10 {
                group.addTask {
                    self.settingsRepository.safariReaderMode = true
                    self.settingsRepository.openInDefaultBrowser = true
                }
            }
        }

        // After concurrent operations, both values should be true
        let safariMode = settingsRepository.safariReaderMode
        let browser = settingsRepository.openInDefaultBrowser

        #expect(safariMode == true)
        #expect(browser == true)
    }
}
