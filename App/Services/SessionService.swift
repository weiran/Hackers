//
//  SessionService.swift
//  Hackers
//
//  Created by Weiran Zhang on 04/05/2019.
//  Copyright © 2019 Weiran Zhang. All rights reserved.
//

import Foundation
import PromiseKit

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

    func authenticate(username: String, password: String) -> Promise<AuthenticationState> {
        let (promise, seal) = Promise<AuthenticationState>.pending()

        firstly {
            HackersKit.shared.login(username: username, password: password)
        }.done { user in
            self.user = user
            UserDefaults.standard.set(user.username, forKey: "username")
            seal.fulfill(.authenticated)
        }.catch { error in
            seal.reject(error)
        }

        return promise
    }

    enum AuthenticationState {
        case authenticated
        case notAuthenticated
    }
}
