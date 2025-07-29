//
//  SessionService.swift
//  Hackers
//
//  Created by Weiran Zhang on 04/05/2019.
//  Copyright © 2019 Weiran Zhang. All rights reserved.
//

import Foundation

class SessionService {
    private var user: User?

    var authenticationState: AuthenticationState {
        if HackersKit.shared.isAuthenticated() {
            return .authenticated
        }
        return .notAuthenticated
    }

    var username: String? {
        return user?.username ?? UserDefaults.standard.string(forKey: "username")
    }

    func authenticate(username: String, password: String) async throws -> AuthenticationState {
        let user = try await HackersKit.shared.login(username: username, password: password)
        self.user = user
        UserDefaults.standard.set(user.username, forKey: "username")
        return .authenticated
    }

    func unauthenticate() {
        HackersKit.shared.logout()
    }

    enum AuthenticationState {
        case authenticated
        case notAuthenticated
    }
}
