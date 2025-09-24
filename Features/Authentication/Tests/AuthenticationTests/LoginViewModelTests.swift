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
    @Test("Successful login updates authentication state")
    func successfulLogin() async {
        var loginCalled = false
        let viewModel = LoginViewModel(
            isAuthenticated: false,
            currentUsername: nil,
            onLogin: { username, password in
                #expect(username == "tester")
                #expect(password == "secret")
                loginCalled = true
            },
            onLogout: {}
        )

        viewModel.username = "tester"
        viewModel.password = "secret"

        let didSucceed = await viewModel.performLogin()

        #expect(didSucceed, "Login should succeed when credentials are valid")
        #expect(loginCalled, "Closure should be invoked")
        #expect(viewModel.isAuthenticated, "Authentication state should flip to true")
        #expect(viewModel.currentUsername == "tester", "Username should be cached for the welcome view")
        #expect(!viewModel.isAuthenticating, "Activity indicator should stop animating")
        #expect(!viewModel.showAlert, "Alert should not appear on success")
    }

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
    func logoutClearsState() {
        var didLogout = false
        let viewModel = LoginViewModel(
            isAuthenticated: true,
            currentUsername: "tester",
            onLogin: { _, _ in },
            onLogout: { didLogout = true }
        )

        viewModel.logout()

        #expect(didLogout, "Logout callback should be invoked")
        #expect(!viewModel.isAuthenticated, "Authentication state should reset")
        #expect(viewModel.currentUsername == nil, "Cached username should be cleared")
    }
}
