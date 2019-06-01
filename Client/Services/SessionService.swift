//
//  SessionService.swift
//  Hackers
//
//  Created by Weiran Zhang on 04/05/2019.
//  Copyright © 2019 Glass Umbrella. All rights reserved.
//

import PromiseKit
import HNScraper

class SessionService {
    private var hackerNewsService: HackerNewsService

    private var user: HNUser?

    public var authenticationState: AuthenticationState {
        if HNLogin.shared.sessionCookie != nil {
            return .authenticated
        }
        return .notAuthenticated
    }

    public var username: String? {
        return user?.username ?? UserDefaults.standard.string(forKey: "username")
    }

    init(hackerNewsService: HackerNewsService) {
        self.hackerNewsService = hackerNewsService
        HNLogin.shared.addObserver(self)
    }

    public func authenticate(username: String, password: String) -> Promise<AuthenticationState> {
        let (promise, seal) = Promise<AuthenticationState>.pending()

        firstly {
            self.hackerNewsService.login(username: username, password: password)
        }.done { (user, _) in
            if let user = user {
                self.user = user
                seal.fulfill(.authenticated)
            } else {
                seal.reject(HNScraper.HNScraperError.notLoggedIn)
            }
        }.catch { error in
            seal.reject(error)
        }

        return promise
    }

    public enum AuthenticationState {
        case authenticated
        case notAuthenticated
    }
}

extension SessionService: HNLoginDelegate {
    func didLogin(user: HNUser, cookie: HTTPCookie) {
        self.user = user
        UserDefaults.standard.set(user.username, forKey: "username")
    }
}
