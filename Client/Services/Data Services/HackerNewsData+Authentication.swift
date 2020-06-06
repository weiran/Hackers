//
//  HackerNewsData+Authentication.swift
//  Hackers
//
//  Created by Weiran Zhang on 06/06/2020.
//  Copyright © 2020 Glass Umbrella. All rights reserved.
//

import Foundation
import PromiseKit

protocol HackerNewsAuthenticationDelegate: class {
    func didAuthenticate(user: HackerNewsUser)
}

extension HackerNewsData {
    func login(username: String, password: String) -> Promise<HackerNewsUser> {
        scraperShim.login(username: username, password: password)
    }

    func logout() {
        scraperShim.logout()
    }

    func isAuthenticated() -> Bool {
        scraperShim.isAuthenticated()
    }
}

extension HackerNewsData: HNScraperShimAuthenticationDelegate {
    func didAuthenticate(user: HackerNewsUser, cookie: HTTPCookie) {
        authenticationDelegate?.didAuthenticate(user: user)
    }
}
