//
//  SessionService.swift
//  Hackers
//
//  Copyright © 2025 Weiran Zhang. All rights reserved.
//

import Foundation
import Domain
import Data
import Combine
import Shared

@MainActor
class SessionService: ObservableObject, AuthenticationServiceProtocol {
    @Published private var user: Domain.User?
    private let authenticationUseCase: AuthenticationUseCase

    init() {
        // Get authentication use case from dependency container
        self.authenticationUseCase = DependencyContainer.shared.getAuthenticationUseCase()

        // Load current user on init
        Task {
            self.user = await authenticationUseCase.getCurrentUser()
        }
    }

    var authenticationState: AuthenticationState {
        // Check if we have a stored user
        if user != nil {
            return .authenticated
        }
        return .notAuthenticated
    }

    var username: String? {
        return user?.username
    }

    // MARK: - AuthenticationServiceProtocol

    var isAuthenticated: Bool {
        return authenticationState == .authenticated
    }

    func showLogin() {
        // This will be handled by NavigationStore in the view layer
    }

    func authenticate(username: String, password: String) async throws -> AuthenticationState {
        // Use the actual authentication repository to log in to Hacker News
        try await authenticationUseCase.authenticate(username: username, password: password)

        // Update the user after successful authentication
        self.user = await authenticationUseCase.getCurrentUser()

        return .authenticated
    }

    func unauthenticate() {
        Task {
            try? await authenticationUseCase.logout()
            self.user = nil
        }
    }

    enum AuthenticationState {
        case authenticated
        case notAuthenticated
    }
}
