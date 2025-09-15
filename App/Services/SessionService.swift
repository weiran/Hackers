//
//  SessionService.swift
//  Hackers
//
//  Copyright © 2025 Weiran Zhang. All rights reserved.
//

import Combine
import Data
import Domain
import Foundation
import Shared

@MainActor
class SessionService: ObservableObject, AuthenticationServiceProtocol {
    @Published private var user: Domain.User?
    private let authenticationUseCase: AuthenticationUseCase

    init() {
        // Get authentication use case from dependency container
        authenticationUseCase = DependencyContainer.shared.getAuthenticationUseCase()

        // Load current user on init
        Task { [weak self] in
            guard let useCase = self?.authenticationUseCase else { return }
            let user = await useCase.getCurrentUser()
            await MainActor.run { self?.user = user }
        }

        // Observe explicit logout notifications to update session state
        NotificationCenter.default.addObserver(
            forName: .userDidLogout,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.user = nil
            }
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
        user?.username
    }

    // MARK: - AuthenticationServiceProtocol

    var isAuthenticated: Bool {
        authenticationState == .authenticated
    }

    func showLogin() {
        // This will be handled by NavigationStore in the view layer
    }

    func authenticate(username: String, password: String) async throws -> AuthenticationState {
        // Use the actual authentication repository to log in to Hacker News
        try await authenticationUseCase.authenticate(username: username, password: password)

        // Update the user after successful authentication
        user = await authenticationUseCase.getCurrentUser()

        return .authenticated
    }

    func unauthenticate() {
        Task { [weak self] in
            guard let useCase = self?.authenticationUseCase else { return }
            try? await useCase.logout()
            await MainActor.run { self?.user = nil }
        }
    }

    enum AuthenticationState {
        case authenticated
        case notAuthenticated
    }
}
