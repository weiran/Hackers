//
//  AuthenticationRepository.swift
//  Data
//
//  Copyright © 2025 Weiran Zhang. All rights reserved.
//

import Domain
import Foundation
import Networking

public final class AuthenticationRepository: AuthenticationUseCase, Sendable {
    private let networkManager: NetworkManagerProtocol
    private let userDefaults: UserDefaultsProtocol
    private let urlBase = "https://news.ycombinator.com"

    public init(
        networkManager: NetworkManagerProtocol,
        userDefaults: UserDefaultsProtocol = UserDefaults.standard
    ) {
        self.networkManager = networkManager
        self.userDefaults = userDefaults
    }

    public func authenticate(username: String, password: String) async throws {
        guard let hnURL = URL(string: urlBase), let loginURL = URL(string: "\(urlBase)/login") else {
            throw HackersKitError.requestFailure
        }

        let formData = FormEncoder.encode([
            FormField(name: "acct", value: username),
            FormField(name: "pw", value: password),
            FormField(name: "goto", value: "news")
        ])

        // Submit the login form
        let response = try await networkManager.post(url: loginURL, body: formData)

        // Check if login was successful by looking for signs of authentication. HN redirects
        // to /news on a successful login and shows the username in the header; on failure it
        // re-renders the login form. Detect failure explicitly: "Bad login" outright, or a
        // page that still contains the login form (both "Login" and the acct input field).
        // Parentheses make the intended precedence explicit: failure = Bad login OR (form present).
        let badCredentials = response.contains("Bad login")
            || (response.contains("Login") && response.contains("name=\"acct\""))
        if badCredentials {
            throw HackersKitError.authenticationError(error: .badCredentials)
        }

        // HN signals a real session solely through a cookie named "user"; a page that
        // merely looks successful is not enough to treat the account as signed in.
        guard networkManager.containsCookie(named: "user", for: hnURL) else {
            throw HackersKitError.authenticationError(error: .sessionNotEstablished)
        }

        // Store username locally for reference
        userDefaults.set(username, forKey: "hn_username")
    }

    public func logout() async throws {
        // Clear cookies to log out
        networkManager.clearCookies()

        // Clear stored username
        userDefaults.set(nil, forKey: "hn_username")
    }

    public func isAuthenticated() async -> Bool {
        // A valid session needs both the stored username and the HN session cookie,
        // which Hacker News sets under the exact name "user".
        guard let hnURL = URL(string: urlBase) else { return false }

        let hasSessionCookie = networkManager.containsCookie(named: "user", for: hnURL)
        let hasStoredUsername = userDefaults.string(forKey: "hn_username") != nil

        return hasSessionCookie && hasStoredUsername
    }

    public func getCurrentUser() async -> User? {
        guard await isAuthenticated(),
              let username = userDefaults.string(forKey: "hn_username") else {
            return nil
        }

        // For now, return a basic user object
        // In the future, we could fetch more user details from HN
        return User(username: username, karma: 0, joined: Date())
    }
}
