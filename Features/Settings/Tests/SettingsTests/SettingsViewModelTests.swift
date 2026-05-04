//
//  SettingsViewModelTests.swift
//  SettingsTests
//
//  Copyright © 2025 Weiran Zhang. All rights reserved.
//

@testable import Domain
import Foundation
@testable import Settings
import Testing

@MainActor
@Suite("SettingsViewModel Tests")
struct SettingsViewModelTests {
    let mockSettingsUseCase = MockSettingsUseCase()
    var settingsViewModel: SettingsViewModel {
        SettingsViewModel(settingsUseCase: mockSettingsUseCase)
    }

    final class MockSettingsUseCase: SettingsUseCase, @unchecked Sendable {
        var safariReaderMode = false
        var linkBrowserMode: LinkBrowserMode = .customBrowser
        var showThumbnails = true
        var rememberFeedCategory = false
        var lastFeedCategory: PostType?
        var textSize: TextSize = .medium
        var compactFeedDesign = false
        var dimReadPosts = true
        var clearCacheCallCount = 0
        var cacheUsageBytesValue: Int64 = 0
        var cacheUsageCallCount = 0

        func clearCache() { clearCacheCallCount += 1 }
        func cacheUsageBytes() async -> Int64 {
            cacheUsageCallCount += 1
            return cacheUsageBytesValue
        }
    }

    @Test("Initialization loads stored settings")
    func initializationLoadsStoredSettings() {
        mockSettingsUseCase.safariReaderMode = true
        mockSettingsUseCase.linkBrowserMode = .systemBrowser
        mockSettingsUseCase.showThumbnails = false
        mockSettingsUseCase.rememberFeedCategory = true
        mockSettingsUseCase.textSize = .large
        mockSettingsUseCase.compactFeedDesign = true
        mockSettingsUseCase.dimReadPosts = false

        let viewModel = settingsViewModel

        #expect(viewModel.safariReaderMode == true)
        #expect(viewModel.linkBrowserMode == .systemBrowser)
        #expect(viewModel.showThumbnails == false)
        #expect(viewModel.rememberFeedCategory == true)
        #expect(viewModel.textSize == .large)
        #expect(viewModel.compactFeedDesign == true)
        #expect(viewModel.dimReadPosts == false)
    }

    @Test("Setting changes persist to use case")
    func settingChangesPersistToUseCase() {
        let viewModel = settingsViewModel

        viewModel.safariReaderMode = true
        viewModel.linkBrowserMode = .inAppBrowser
        viewModel.showThumbnails = false
        viewModel.rememberFeedCategory = true
        viewModel.textSize = .large
        viewModel.compactFeedDesign = true
        viewModel.dimReadPosts = false

        #expect(mockSettingsUseCase.safariReaderMode == true)
        #expect(mockSettingsUseCase.linkBrowserMode == .inAppBrowser)
        #expect(mockSettingsUseCase.showThumbnails == false)
        #expect(mockSettingsUseCase.rememberFeedCategory == true)
        #expect(mockSettingsUseCase.textSize == .large)
        #expect(mockSettingsUseCase.compactFeedDesign == true)
        #expect(mockSettingsUseCase.dimReadPosts == false)
    }

    @Test("Cache usage refresh formats byte count")
    func refreshCacheUsageFormatsBytes() async {
        mockSettingsUseCase.cacheUsageBytesValue = 2_048
        let viewModel = settingsViewModel

        await waitUntil(viewModel.cacheUsageText != "Calculating…")
        let expected = ByteCountFormatter.string(fromByteCount: 2_048, countStyle: .file)
        #expect(viewModel.cacheUsageText == expected)

        mockSettingsUseCase.cacheUsageBytesValue = 4_096
        viewModel.refreshCacheUsage()

        await waitUntil(viewModel.cacheUsageText == ByteCountFormatter.string(fromByteCount: 4_096, countStyle: .file))
        #expect(mockSettingsUseCase.cacheUsageCallCount >= 2)
    }

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

    private func waitUntil(_ predicate: @autoclosure () -> Bool, timeoutMilliseconds: Int = 200) async {
        var iterations = 0
        while !predicate() && iterations < timeoutMilliseconds {
            iterations += 1
            try? await Task.sleep(for: .milliseconds(5))
        }
        if iterations == timeoutMilliseconds {
            Issue.record("Timed out waiting for condition")
        }
    }
}
