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
    private var currentUserGeneration = 0
    public private(set) var logoutError: Error?

    public init(authenticationUseCase: any AuthenticationUseCase) {
        self.authenticationUseCase = authenticationUseCase

        currentUserGeneration += 1
        let generation = currentUserGeneration
        currentUserTask = Task { [weak self, authenticationUseCase] in
            let user = await authenticationUseCase.getCurrentUser()
            guard !Task.isCancelled else { return }
            guard let self, self.currentUserGeneration == generation else { return }
            self.user = user
        }

        logoutObserver = NotificationCenter.default.addObserver(
            forName: .userDidLogout,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            MainActor.assumeIsolated {
                self.handleLogoutNotification()
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
        currentUserGeneration += 1
        try await authenticationUseCase.authenticate(username: username, password: password)
        user = await authenticationUseCase.getCurrentUser()
        logoutError = nil
        return .authenticated
    }

    public func unauthenticate() async throws {
        currentUserTask?.cancel()
        currentUserGeneration += 1
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

    private func handleLogoutNotification() {
        currentUserTask?.cancel()
        currentUserGeneration += 1
        user = nil
    }

    public enum AuthenticationState {
        case authenticated
        case notAuthenticated
    }
}
