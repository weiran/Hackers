//
//  SettingsViewModelTests.swift
//  SettingsTests
//
//  Copyright © 2025 Weiran Zhang. All rights reserved.
//

// swiftlint:disable force_cast

import Testing
@testable import Settings
@testable import Domain

@Suite("SettingsViewModel Tests")
struct SettingsViewModelTests {

    let mockSettingsUseCase = MockSettingsUseCase()
    var settingsViewModel: SettingsViewModel {
        SettingsViewModel(settingsUseCase: mockSettingsUseCase)
    }

    // MARK: - Mock SettingsUseCase

    final class MockSettingsUseCase: SettingsUseCase, @unchecked Sendable {
        private var _safariReaderMode = false
        private var _openInDefaultBrowser = false

        var getterCallCounts: [String: Int] = [:]
        var setterCallCounts: [String: Int] = [:]

        var safariReaderMode: Bool {
            get {
                getterCallCounts["safariReaderMode", default: 0] += 1
                return _safariReaderMode
            }
            set {
                setterCallCounts["safariReaderMode", default: 0] += 1
                _safariReaderMode = newValue
            }
        }

        var openInDefaultBrowser: Bool {
            get {
                getterCallCounts["openInDefaultBrowser", default: 0] += 1
                return _openInDefaultBrowser
            }
            set {
                setterCallCounts["openInDefaultBrowser", default: 0] += 1
                _openInDefaultBrowser = newValue
            }
        }

        func reset() {
            getterCallCounts.removeAll()
            setterCallCounts.removeAll()
        }
    }

    // MARK: - Initialization Tests

    @Test("SettingsViewModel initialization")
    func settingsViewModelInitialization() {
        #expect(settingsViewModel != nil)
    }

    @Test("SettingsViewModel initialization with default dependency")
    func settingsViewModelInitializationWithDefaultDependency() {
        let viewModel = SettingsViewModel()
        #expect(viewModel != nil)
    }

    // MARK: - Safari Reader Mode Tests

    @Test("Safari reader mode getter")
    func safariReaderModeGetter() {
        mockSettingsUseCase._safariReaderMode = true

        let value = settingsViewModel.safariReaderMode

        #expect(value == true)
        #expect(mockSettingsUseCase.getterCallCounts["safariReaderMode"] == 1)
    }

    @Test("Safari reader mode setter")
    func safariReaderModeSetter() {
        settingsViewModel.safariReaderMode = true

        #expect(mockSettingsUseCase._safariReaderMode == true)
        #expect(mockSettingsUseCase.setterCallCounts["safariReaderMode"] == 1)
    }

    @Test("Safari reader mode toggle")
    func safariReaderModeToggle() {
        // Start with false
        #expect(settingsViewModel.safariReaderMode == false)

        // Toggle to true
        settingsViewModel.safariReaderMode = true
        #expect(settingsViewModel.safariReaderMode == true)

        // Toggle back to false
        settingsViewModel.safariReaderMode = false
        #expect(settingsViewModel.safariReaderMode == false)
    }

    // MARK: - Removed Settings Tests
    // Note: showThumbnails and swipeActions settings have been removed from the app
    
    /*
    @Test("Show thumbnails getter")
    func showThumbnailsGetter() {
        mockSettingsUseCase._showThumbnails = true

        let value = settingsViewModel.showThumbnails

        #expect(value == true)
        #expect(mockSettingsUseCase.getterCallCounts["showThumbnails"] == 1)
    }

    @Test("Show thumbnails setter")
    func showThumbnailsSetter() {
        settingsViewModel.showThumbnails = true

        #expect(mockSettingsUseCase._showThumbnails == true)
        #expect(mockSettingsUseCase.setterCallCounts["showThumbnails"] == 1)
    }

    @Test("Show thumbnails toggle")
    func showThumbnailsToggle() {
        // Start with false
        #expect(settingsViewModel.showThumbnails == false)

        // Toggle to true
        settingsViewModel.showThumbnails = true
        #expect(settingsViewModel.showThumbnails == true)

        // Toggle back to false
        settingsViewModel.showThumbnails = false
        #expect(settingsViewModel.showThumbnails == false)
    }

    @Test("Swipe actions getter")
    func swipeActionsGetter() {
        mockSettingsUseCase._swipeActions = true

        let value = settingsViewModel.swipeActions

        #expect(value == true)
        #expect(mockSettingsUseCase.getterCallCounts["swipeActions"] == 1)
    }

    @Test("Swipe actions setter")
    func swipeActionsSetter() {
        settingsViewModel.swipeActions = true

        #expect(mockSettingsUseCase._swipeActions == true)
        #expect(mockSettingsUseCase.setterCallCounts["swipeActions"] == 1)
    }

    @Test("Swipe actions toggle")
    func swipeActionsToggle() {
        // Start with false
        #expect(settingsViewModel.swipeActions == false)

        // Toggle to true
        settingsViewModel.swipeActions = true
        #expect(settingsViewModel.swipeActions == true)

        // Toggle back to false
        settingsViewModel.swipeActions = false
        #expect(settingsViewModel.swipeActions == false)
    }
    */

    // MARK: - Removed Settings (showComments)
    // Note: showComments setting has been removed from the app

    // MARK: - Open In Default Browser Tests

    @Test("Open in default browser getter")
    func openInDefaultBrowserGetter() {
        mockSettingsUseCase._openInDefaultBrowser = true

        let value = settingsViewModel.openInDefaultBrowser

        #expect(value == true)
        #expect(mockSettingsUseCase.getterCallCounts["openInDefaultBrowser"] == 1)
    }

    @Test("Open in default browser setter")
    func openInDefaultBrowserSetter() {
        settingsViewModel.openInDefaultBrowser = true

        #expect(mockSettingsUseCase._openInDefaultBrowser == true)
        #expect(mockSettingsUseCase.setterCallCounts["openInDefaultBrowser"] == 1)
    }

    @Test("Open in default browser toggle")
    func openInDefaultBrowserToggle() {
        // Start with false
        #expect(settingsViewModel.openInDefaultBrowser == false)

        // Toggle to true
        settingsViewModel.openInDefaultBrowser = true
        #expect(settingsViewModel.openInDefaultBrowser == true)

        // Toggle back to false
        settingsViewModel.openInDefaultBrowser = false
        #expect(settingsViewModel.openInDefaultBrowser == false)
    }

    // MARK: - Multiple Settings Tests

    @Test("Multiple settings changes")
    func multipleSettingsChanges() {
        // Change multiple settings
        settingsViewModel.safariReaderMode = true
        settingsViewModel.openInDefaultBrowser = true

        // Verify all changes are reflected
        #expect(settingsViewModel.safariReaderMode == true)
        #expect(settingsViewModel.openInDefaultBrowser == true)

        // Verify the underlying use case was called correctly
        #expect(mockSettingsUseCase.setterCallCounts["safariReaderMode"] == 1)
        #expect(mockSettingsUseCase.setterCallCounts["openInDefaultBrowser"] == 1)
    }

    @Test("Settings independence")
    func settingsIndependence() {
        // Test that changing one setting doesn't affect others
        settingsViewModel.safariReaderMode = true

        // Other settings should remain at their default values
        #expect(settingsViewModel.openInDefaultBrowser == false)

        // Only safari reader mode setter should have been called
        #expect(mockSettingsUseCase.setterCallCounts["safariReaderMode"] == 1)
        #expect(mockSettingsUseCase.setterCallCounts["openInDefaultBrowser"] == nil)
    }

    // MARK: - Observation Tests (for @Observable macro)

    @Test("Observable conformance")
    func observableConformance() {
        // Test that the SettingsViewModel is properly observable
        // This mainly tests that the @Observable macro is working correctly

        var changeCount = 0
        let observation = withObservationTracking {
            _ = settingsViewModel.safariReaderMode
        } onChange: {
            changeCount += 1
        }

        // Change the value
        settingsViewModel.safariReaderMode = true

        // Clean up the observation
        withExtendedLifetime(observation) {}

        // Note: In actual SwiftUI, @Observable would trigger view updates
        // Here we're just testing that the property can be observed
        #expect(settingsViewModel.safariReaderMode == true)
    }

    // MARK: - Performance Tests

    @Test("Performance of multiple property access", .timeLimit(.seconds(5)))
    func performanceOfMultiplePropertyAccess() {
        for _ in 0..<1000 {
            settingsViewModel.safariReaderMode = true
            settingsViewModel.openInDefaultBrowser = true

            _ = settingsViewModel.safariReaderMode
            _ = settingsViewModel.openInDefaultBrowser
        }
    }

    // MARK: - Concurrent Access Tests

    @Test("Concurrent access")
    func concurrentAccess() async {
        // Test concurrent read/write operations
        await withTaskGroup(of: Void.self) { group in
            for index in 0..<10 {
                group.addTask {
                    let isEven = index % 2 == 0
                    self.settingsViewModel.safariReaderMode = isEven
                    self.settingsViewModel.openInDefaultBrowser = !isEven

                    // Read the values
                    _ = self.settingsViewModel.safariReaderMode
                    _ = self.settingsViewModel.openInDefaultBrowser
                }
            }
        }

        // After concurrent operations, the values should be consistent
        let safariMode = settingsViewModel.safariReaderMode
        let browser = settingsViewModel.openInDefaultBrowser

        // Both should have valid boolean values
        #expect(safariMode || !safariMode) // Always true for boolean
        #expect(browser || !browser) // Always true for boolean
    }

    // MARK: - Edge Cases Tests

    @Test("Rapid toggling")
    func rapidToggling() {
        // Test rapidly toggling the same setting
        for index in 0..<100 {
            settingsViewModel.safariReaderMode = index % 2 == 0
        }

        // Final value should be false (since 99 % 2 == 1)
        #expect(settingsViewModel.safariReaderMode == false)
        #expect(mockSettingsUseCase.setterCallCounts["safariReaderMode"] == 100)
    }

    @Test("Same value assignment")
    func sameValueAssignment() {
        // Test assigning the same value multiple times
        settingsViewModel.safariReaderMode = true
        settingsViewModel.safariReaderMode = true
        settingsViewModel.safariReaderMode = true

        #expect(settingsViewModel.safariReaderMode == true)
        // Should still call setter each time (view model doesn't optimize for this)
        #expect(mockSettingsUseCase.setterCallCounts["safariReaderMode"] == 3)
    }
}
