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

    var authenticationState: AuthenticationState {
        // For now, check if username exists in UserDefaults
        // TODO: Replace with proper authentication use case when implemented
        if UserDefaults.standard.string(forKey: "username") != nil {
            return .authenticated
        }
        return .notAuthenticated
    }

    var username: String? {
        return user?.username ?? UserDefaults.standard.string(forKey: "username")
    }

    // MARK: - AuthenticationServiceProtocol

    var isAuthenticated: Bool {
        return authenticationState == .authenticated
    }

    func showLogin() {
        // This will be handled by NavigationStore in the view layer
    }

    func authenticate(username: String, password: String) async throws -> AuthenticationState {
        // TODO: Replace with proper authentication use case when implemented
        // For now, just simulate authentication by storing username
        self.user = Domain.User(username: username, karma: 0, joined: Date())
        UserDefaults.standard.set(username, forKey: "username")
        return .authenticated
    }

    func unauthenticate() {
        // TODO: Replace with proper authentication use case when implemented  
        UserDefaults.standard.removeObject(forKey: "username")
        self.user = nil
    }

    enum AuthenticationState {
        case authenticated
        case notAuthenticated
    }
}
