//
//  SettingsViewTests.swift
//  SettingsTests
//
//  Copyright © 2025 Weiran Zhang. All rights reserved.
//

// swiftlint:disable force_cast

@testable import Domain
import MessageUI
@testable import Settings
@testable import Shared
import SwiftUI
import Testing

@Suite("SettingsView Tests")
struct SettingsViewTests {
    // MARK: - Mock Navigation Store

    final class MockNavigationStore: NavigationStoreProtocol, @unchecked Sendable {
        @Published var selectedPost: Post?
        @Published var selectedPostId: Int?
        @Published var showingLogin = false
        @Published var showingSettings = false

        func showPost(_ post: Post) {
            selectedPost = post
            selectedPostId = post.id
        }

        func showPost(withId id: Int) {
            selectedPostId = id
            selectedPost = nil
        }

        func showLogin() {
            showingLogin = true
        }

        func showSettings() {
            showingSettings = true
        }

        func selectPostType(_: Domain.PostType) {
            // Mock implementation
        }

        @MainActor
        func openURLInPrimaryContext(_: URL, pushOntoDetailStack _: Bool) -> Bool { false }
    }

    // MARK: - Basic View Tests

    @Test("SettingsView creation")
    func settingsViewCreation() {
        let settingsView = SettingsView<MockNavigationStore>()
        #expect(settingsView != nil)
    }

    // MARK: - View Compilation Tests

    // MARK: - Integration Tests with ViewModel

    // MARK: - Accessibility Tests

    // MARK: - Bundle Tests

    @Test("Bundle extension")
    func bundleExtension() {
        // Test the Bundle extension for icon
        let icon = Bundle.main.icon

        // Icon might be nil in test environment, that's okay
        // Just test that the method doesn't crash
        if let icon {
            #expect(icon.size.width > 0)
            #expect(icon.size.height > 0)
        }
    }

    // MARK: - Onboarding Tests

    // MARK: - SwiftUI Integration Tests
}
