//
//  AuthenticationUseCase.swift
//  Domain
//
//  Copyright © 2025 Weiran Zhang. All rights reserved.
//

import Foundation

public protocol AuthenticationUseCase: Sendable {
    func authenticate(username: String, password: String) async throws
    func logout() async throws
    func isAuthenticated() async -> Bool
    func getCurrentUser() async -> User?
}