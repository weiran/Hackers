//
//  AuthenticationRepository.swift
//  Data
//
//  Copyright © 2025 Weiran Zhang. All rights reserved.
//

import Domain
import Foundation
import Networking
import SwiftSoup

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
        guard let loginURL = URL(string: "\(urlBase)/login") else {
            throw HackersKitError.requestFailure
        }

        // First, get the login page to extract any CSRF tokens or form data
        let loginPageHTML = try await networkManager.get(url: loginURL)

        // Build the login form data
        let encodedUsername = username.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let encodedPassword = password.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let formData = "acct=\(encodedUsername)&pw=\(encodedPassword)&goto=news"

        // Submit the login form
        let response = try await networkManager.post(url: loginURL, body: formData)

        // Check if login was successful by looking for signs of authentication
        // HN redirects to /news on successful login and shows username in header
        if response.contains("Bad login") || response.contains("Login") && response.contains("name=\"acct\"") {
            throw HackersKitError.authenticationError(error: .badCredentials)
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
        // Check if we have authentication cookies for HN
        guard let hnURL = URL(string: urlBase) else { return false }

        let hasCookies = networkManager.containsCookie(for: hnURL)
        let hasStoredUsername = userDefaults.string(forKey: "hn_username") != nil

        return hasCookies && hasStoredUsername
    }

    public func getCurrentUser() async -> User? {
        guard let username = userDefaults.string(forKey: "hn_username") else {
            return nil
        }

        // For now, return a basic user object
        // In the future, we could fetch more user details from HN
        return User(username: username, karma: 0, joined: Date())
    }
}
