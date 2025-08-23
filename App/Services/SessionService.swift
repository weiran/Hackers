//
//  SessionService.swift
//  Hackers
//
//  Created by Weiran Zhang on 04/05/2019.
//  Copyright © 2019 Weiran Zhang. All rights reserved.
//

import Foundation
import Domain
import Data

class SessionService {
    private var user: Domain.User?

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
