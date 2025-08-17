//
//  HackersKit+Authentication.swift
//  Hackers
//
//  Created by Weiran Zhang on 06/06/2020.
//  Copyright © 2020 Weiran Zhang. All rights reserved.
//

import Foundation

extension HackersKit {
    func login(username: String, password: String) async throws -> User {
        let url = URLs.login
        let body = "acct=\(username)&pw=\(password)"

        do {
            _ = try await networkManager.post(url: url, body: body)
            let user = User(
                username: username,
                karma: 0,
                joined: Date()
            )
            authenticationDelegate?.didAuthenticate(user: user)
            return user
        } catch let error {
            throw HackersKitAuthenticationError.badCredentials
        }
    }

    func logout() {
        networkManager.clearCookies()
    }

    func isAuthenticated() -> Bool {
        return networkManager.containsCookie(for: URL(string: HackersKit.hackerNewsBaseURL)!)
    }
}
