//
//  SettingsViewModelTests.swift
//  SettingsTests
//
//  Copyright © 2025 Weiran Zhang. All rights reserved.
//

// swiftlint:disable force_cast

@testable import Domain
import Foundation
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
        private var _showThumbnails = true
        private var _rememberFeedCategory = false
        private var _lastFeedCategory: PostType?
        private var _textSize: TextSize = .medium
        var clearCacheCallCount = 0
        var cacheUsageBytesValue: Int64 = 0
        var cacheUsageCallCount = 0

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

        var showThumbnails: Bool {
            get {
                getterCallCounts["showThumbnails", default: 0] += 1
                return _showThumbnails
            }
            set {
                setterCallCounts["showThumbnails", default: 0] += 1
                _showThumbnails = newValue
            }
        }

        var rememberFeedCategory: Bool {
            get {
                getterCallCounts["rememberFeedCategory", default: 0] += 1
                return _rememberFeedCategory
            }
            set {
                setterCallCounts["rememberFeedCategory", default: 0] += 1
                _rememberFeedCategory = newValue
                if !newValue {
                    _lastFeedCategory = nil
                }
            }
        }

        var lastFeedCategory: PostType? {
            get {
                getterCallCounts["lastFeedCategory", default: 0] += 1
                return _lastFeedCategory
            }
            set {
                setterCallCounts["lastFeedCategory", default: 0] += 1
                _lastFeedCategory = newValue
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
            clearCacheCallCount = 0
            cacheUsageCallCount = 0
            _showThumbnails = true
            _rememberFeedCategory = false
            _lastFeedCategory = nil
        }

        func clearCache() { clearCacheCallCount += 1 }
        func cacheUsageBytes() async -> Int64 {
            cacheUsageCallCount += 1
            return cacheUsageBytesValue
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

    // MARK: - Thumbnail Setting Tests

    @Test("Show thumbnails getter")
    func showThumbnailsGetter() {
        mockSettingsUseCase.showThumbnails = false

        let value = settingsViewModel.showThumbnails

        #expect(value == false)
        #expect(mockSettingsUseCase.getterCallCounts["showThumbnails"] == 1)
    }

    @Test("Show thumbnails setter")
    func showThumbnailsSetter() {
        settingsViewModel.showThumbnails = false

        #expect(mockSettingsUseCase.showThumbnails == false)
        #expect(mockSettingsUseCase.setterCallCounts["showThumbnails"] == 1)
    }

    @Test("Show thumbnails toggle")
    func showThumbnailsToggle() {
        // Start with true
        #expect(settingsViewModel.showThumbnails == true)

        // Toggle to false
        settingsViewModel.showThumbnails = false
        #expect(settingsViewModel.showThumbnails == false)

        // Toggle back to true
        settingsViewModel.showThumbnails = true
        #expect(settingsViewModel.showThumbnails == true)
    }

    // MARK: - Remember Post Type Tests

    @Test("Remember feed category getter")
    func rememberFeedCategoryGetter() {
        mockSettingsUseCase.rememberFeedCategory = true

        let value = settingsViewModel.rememberFeedCategory

        #expect(value == true)
        #expect(mockSettingsUseCase.getterCallCounts["rememberFeedCategory"] == 1)
    }

    @Test("Remember feed category setter")
    func rememberFeedCategorySetter() {
        settingsViewModel.rememberFeedCategory = true

        #expect(mockSettingsUseCase.rememberFeedCategory == true)
        #expect(mockSettingsUseCase.setterCallCounts["rememberFeedCategory"] == 1)
    }

    @Test("Remember feed category toggle clears stored value when disabled")
    func rememberFeedCategoryToggle() {
        // Start with false
        #expect(settingsViewModel.rememberFeedCategory == false)

        // Toggle to true
        settingsViewModel.rememberFeedCategory = true
        #expect(settingsViewModel.rememberFeedCategory == true)

        // Simulate stored post type
        mockSettingsUseCase.lastFeedCategory = .ask

        // Toggle back to false
        settingsViewModel.rememberFeedCategory = false
        #expect(settingsViewModel.rememberFeedCategory == false)
        #expect(mockSettingsUseCase.lastFeedCategory == nil)
    }

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

    // MARK: - Cache Usage Tests

    @MainActor
    @Test("Cache usage refresh formats byte count")
    func refreshCacheUsageFormatsBytes() async {
        mockSettingsUseCase.cacheUsageBytesValue = 2_048
        let viewModel = settingsViewModel

        await waitUntil(viewModel.cacheUsageText != "Calculating…")
        let expected = ByteCountFormatter.string(fromByteCount: 2_048, countStyle: .file)
        #expect(viewModel.cacheUsageText == expected)

        mockSettingsUseCase.cacheUsageBytesValue = 4_096
        await viewModel.refreshCacheUsage()
        await waitUntil(viewModel.cacheUsageText == ByteCountFormatter.string(fromByteCount: 4_096, countStyle: .file))
        #expect(mockSettingsUseCase.cacheUsageCallCount >= 2)
    }

    @MainActor
    @Test("Clearing cache triggers use case and refresh")
    func clearCacheTriggersRefresh() async {
        mockSettingsUseCase.cacheUsageBytesValue = 1_024
        let viewModel = settingsViewModel
        await waitUntil(viewModel.cacheUsageText != "Calculating…")

        mockSettingsUseCase.cacheUsageBytesValue = 512
        viewModel.clearCache()

        await waitUntil(mockSettingsUseCase.clearCacheCallCount == 1)
        await waitUntil(viewModel.cacheUsageText == ByteCountFormatter.string(fromByteCount: 512, countStyle: .file))
        #expect(mockSettingsUseCase.cacheUsageCallCount >= 2)
    }

    // MARK: - Concurrent Access Tests

    // MARK: - Edge Cases Tests

    @MainActor
    private func waitUntil(_ predicate: @autoclosure () -> Bool, timeoutMilliseconds: Int = 200) async {
        var iterations = 0
        while !predicate() && iterations < timeoutMilliseconds {
            iterations += 1
            try? await Task.sleep(nanoseconds: 5_000_000)
        }
        if iterations == timeoutMilliseconds {
            Issue.record("Timed out waiting for condition")
        }
    }
}
