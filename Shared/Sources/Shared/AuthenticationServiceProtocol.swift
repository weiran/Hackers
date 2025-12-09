//
//  AuthenticationServiceProtocol.swift
//  Shared
//
//  Copyright © 2025 Weiran Zhang. All rights reserved.
//

import Foundation

@MainActor
public protocol AuthenticationServiceProtocol: AnyObject {
    var isAuthenticated: Bool { get }
    var username: String? { get }

    func showLogin()
}
