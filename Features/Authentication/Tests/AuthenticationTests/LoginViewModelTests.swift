//
//  LoginViewModelTests.swift
//  AuthenticationTests
//
//  Copyright © 2025 Weiran Zhang. All rights reserved.
//

@testable import Authentication
import Testing

@Suite("LoginViewModel Tests")
@MainActor
struct LoginViewModelTests {
    @Test("Failed login resets credentials and shows alert")
    func failedLogin() async {
        enum SampleError: Error { case failed }

        let viewModel = LoginViewModel(
            isAuthenticated: false,
            currentUsername: nil,
            onLogin: { _, _ in throw SampleError.failed },
            onLogout: {}
        )

        viewModel.username = "tester"
        viewModel.password = "secret"

        let didSucceed = await viewModel.performLogin()

        #expect(!didSucceed, "Login should report failure")
        #expect(viewModel.password.isEmpty, "Password should be cleared after a failure")
        #expect(viewModel.showAlert, "Alert flag should toggle on failure")
        #expect(!viewModel.isAuthenticated, "Authentication state should remain false")
        #expect(viewModel.currentUsername == nil, "Username should not be cached on failure")
        #expect(!viewModel.isAuthenticating, "Activity indicator should stop animating")
    }

    @Test("Logout clears authentication state")
    func logoutClearsState() async {
        var didLogout = false
        let viewModel = LoginViewModel(
            isAuthenticated: true,
            currentUsername: "tester",
            onLogin: { _, _ in },
            onLogout: { didLogout = true }
        )

        let didSucceed = await viewModel.logout()

        #expect(didSucceed)
        #expect(didLogout, "Logout callback should be invoked")
        #expect(!viewModel.isAuthenticated, "Authentication state should reset")
        #expect(viewModel.currentUsername == nil, "Cached username should be cleared")
    }
}
