//
//  HackersKit+Authentication.swift
//  Hackers
//
//  Created by Weiran Zhang on 06/06/2020.
//  Copyright © 2020 Weiran Zhang. All rights reserved.
//

import Foundation
import PromiseKit

protocol HackerNewsAuthenticationDelegate: class {
    func didAuthenticate(user: User)
}

extension HackersKit {
    func login(username: String, password: String) -> Promise<User> {
        scraperShim.login(username: username, password: password)
    }

    func logout() {
        scraperShim.logout()
    }

    func isAuthenticated() -> Bool {
        scraperShim.isAuthenticated()
    }
}

extension HackersKit: HNScraperShimAuthenticationDelegate {
    func didAuthenticate(user: User, cookie: HTTPCookie) {
        authenticationDelegate?.didAuthenticate(user: user)
    }
}
