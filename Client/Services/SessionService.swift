//
//  SessionService.swift
//  Hackers
//
//  Created by Weiran Zhang on 04/05/2019.
//  Copyright © 2019 Weiran Zhang. All rights reserved.
//

import PromiseKit

class SessionService {
    private var user: HackerNewsUser?

    var authenticationState: AuthenticationState {
        if HackerNewsData.shared.isAuthenticated() {
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
            HackerNewsData.shared.login(username: username, password: password)
        }.done { user in
            self.user = user
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

extension SessionService: HNScraperShimAuthenticationDelegate {
    func didAuthenticate(user: HackerNewsUser, cookie: HTTPCookie) {
        self.user = user
        UserDefaults.standard.set(user.username, forKey: "username")
    }
}
