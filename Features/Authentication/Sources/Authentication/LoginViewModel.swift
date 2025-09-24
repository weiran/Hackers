//
//  LoginViewModel.swift
//  Authentication
//
//  Copyright © 2025 Weiran Zhang. All rights reserved.
//

import Domain
import SwiftUI

@MainActor
public final class LoginViewModel: ObservableObject {
    @Published public var username: String
    @Published public var password: String
    @Published public private(set) var isAuthenticating: Bool
    @Published public var showAlert: Bool
    @Published public var isAuthenticated: Bool
    @Published public var currentUsername: String?

    public let textSize: TextSize

    private let onLogin: (String, String) async throws -> Void
    private let onLogout: () -> Void

    public init(
        isAuthenticated: Bool,
        currentUsername: String?,
        onLogin: @escaping (String, String) async throws -> Void,
        onLogout: @escaping () -> Void,
        textSize: TextSize = .medium,
        username: String = "",
        password: String = ""
    ) {
        self.isAuthenticated = isAuthenticated
        self.currentUsername = currentUsername
        self.onLogin = onLogin
        self.onLogout = onLogout
        self.textSize = textSize
        self.username = username
        self.password = password
        self.isAuthenticating = false
        self.showAlert = false
    }

    public var isLoginEnabled: Bool {
        !isAuthenticating && !username.isEmpty && !password.isEmpty
    }

    @discardableResult
    public func performLogin() async -> Bool {
        guard !isAuthenticating, !username.isEmpty, !password.isEmpty else {
            return false
        }

        isAuthenticating = true
        showAlert = false
        defer { isAuthenticating = false }

        do {
            try await onLogin(username, password)
            isAuthenticated = true
            currentUsername = username
            return true
        } catch {
            showAlert = true
            password = ""
            return false
        }
    }

    public func logout() {
        onLogout()
        isAuthenticated = false
        currentUsername = nil
    }
}
