//
//  SessionService.swift
//  Shared
//
//  Copyright © 2025 Weiran Zhang. All rights reserved.
//

import Combine
import Domain
import Foundation
import Observation

@MainActor
@Observable
public final class SessionService {
    private var user: Domain.User?
    private let authenticationUseCase: any AuthenticationUseCase
    @ObservationIgnored private var logoutObserver: NSObjectProtocol?
    @ObservationIgnored private var currentUserTask: Task<Void, Never>?
    public private(set) var logoutError: Error?

    public init(authenticationUseCase: any AuthenticationUseCase) {
        self.authenticationUseCase = authenticationUseCase

        currentUserTask = Task { [weak self, authenticationUseCase] in
            let user = await authenticationUseCase.getCurrentUser()
            guard !Task.isCancelled else { return }
            self?.user = user
        }

        logoutObserver = NotificationCenter.default.addObserver(
            forName: .userDidLogout,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.user = nil
            }
        }
    }

    isolated deinit {
        currentUserTask?.cancel()
        if let observer = logoutObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    public var authenticationState: AuthenticationState {
        user == nil ? .notAuthenticated : .authenticated
    }

    public var username: String? {
        user?.username
    }

    public func authenticate(username: String, password: String) async throws -> AuthenticationState {
        currentUserTask?.cancel()
        try await authenticationUseCase.authenticate(username: username, password: password)
        user = await authenticationUseCase.getCurrentUser()
        logoutError = nil
        return .authenticated
    }

    public func unauthenticate() async throws {
        currentUserTask?.cancel()
        logoutError = nil
        do {
            try await authenticationUseCase.logout()
            user = nil
        } catch {
            logoutError = error
            user = await authenticationUseCase.getCurrentUser()
            throw error
        }
    }

    public enum AuthenticationState {
        case authenticated
        case notAuthenticated
    }
}
