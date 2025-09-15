//
//  SettingsViewModelTests.swift
//  SettingsTests
//
//  Copyright © 2025 Weiran Zhang. All rights reserved.
//

// swiftlint:disable force_cast

@testable import Domain
import Observation
@testable import Settings
import Testing

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
        private var _textSize: TextSize = .medium
        var clearCacheCallCount = 0

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

        var textSize: TextSize {
            get {
                getterCallCounts["textSize", default: 0] += 1
                return _textSize
            }
            set {
                setterCallCounts["textSize", default: 0] += 1
                _textSize = newValue
            }
        }

        func reset() {
            getterCallCounts.removeAll()
            setterCallCounts.removeAll()
        }

        func clearCache() { clearCacheCallCount += 1 }
        func cacheUsageBytes() async -> Int64 { 0 }
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
        mockSettingsUseCase.safariReaderMode = true

        let value = settingsViewModel.safariReaderMode

        #expect(value == true)
        #expect(mockSettingsUseCase.getterCallCounts["safariReaderMode"] == 1)
    }

    @Test("Safari reader mode setter")
    func safariReaderModeSetter() {
        settingsViewModel.safariReaderMode = true

        #expect(mockSettingsUseCase.safariReaderMode == true)
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
        mockSettingsUseCase.openInDefaultBrowser = true

        let value = settingsViewModel.openInDefaultBrowser

        #expect(value == true)
        #expect(mockSettingsUseCase.getterCallCounts["openInDefaultBrowser"] == 1)
    }

    @Test("Open in default browser setter")
    func openInDefaultBrowserSetter() {
        settingsViewModel.openInDefaultBrowser = true

        #expect(mockSettingsUseCase.openInDefaultBrowser == true)
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

        // Basic test that the property can be read and set
        settingsViewModel.safariReaderMode = true
        #expect(settingsViewModel.safariReaderMode == true)

        settingsViewModel.safariReaderMode = false
        #expect(settingsViewModel.safariReaderMode == false)
    }

    // MARK: - Concurrent Access Tests

    // MARK: - Edge Cases Tests
}
