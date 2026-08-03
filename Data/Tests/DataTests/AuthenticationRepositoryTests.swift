//
//  AuthenticationRepositoryTests.swift
//  DataTests
//
//  Copyright © 2025 Weiran Zhang. All rights reserved.
//

@testable import Data
@testable import Domain
import Foundation
@testable import Networking
import Testing

@Suite("AuthenticationRepository Tests")
struct AuthenticationRepositoryTests {
    @Test("Successful authentication stores username through injected defaults")
    func successfulAuthenticationStoresUsername() async throws {
        let network = MockAuthenticationNetworkManager()
        let userDefaults = MockAuthenticationUserDefaults()
        let repository = AuthenticationRepository(networkManager: network, userDefaults: userDefaults)

        try await repository.authenticate(username: "test user", password: "secret")

        #expect(userDefaults.string(forKey: "hn_username") == "test user")
        #expect(network.postBodies.first?.contains("acct=test+user") == true)
        #expect(network.postBodies.first?.contains("pw=secret") == true)
    }

    @Test("Complex 64-character credentials are form encoded without delimiters")
    func complexCredentialsUseFormEncoding() async throws {
        let network = MockAuthenticationNetworkManager()
        let userDefaults = MockAuthenticationUserDefaults()
        let repository = AuthenticationRepository(networkManager: network, userDefaults: userDefaults)
        let username = "test user+&"
        let password = String(repeating: "a", count: 56) + "&=+%/?#é"

        #expect(password.count == 64)

        try await repository.authenticate(username: username, password: password)

        let expectedPassword =
            String(repeating: "a", count: 56) + "%26%3D%2B%25%2F%3F%23%C3%A9"
        #expect(network.postBodies == ["acct=test+user%2B%26&pw=\(expectedPassword)&goto=news"])
        #expect(userDefaults.string(forKey: "hn_username") == username)
    }

    @Test("Bad credentials do not store username")
    func badCredentialsDoNotStoreUsername() async {
        let network = MockAuthenticationNetworkManager(postResponse: "Bad login")
        let userDefaults = MockAuthenticationUserDefaults()
        let repository = AuthenticationRepository(networkManager: network, userDefaults: userDefaults)

        await #expect {
            try await repository.authenticate(username: "user", password: "wrong")
        } throws: { error in
            guard case HackersKitError.authenticationError(error: .badCredentials) = error else { return false }
            return true
        }

        #expect(userDefaults.string(forKey: "hn_username") == nil)
    }

    @Test("Response with stray 'Login' link but no form is treated as success")
    func strayLoginLinkWithoutFormIsSuccess() async throws {
        // A successful login response that happens to contain the word "Login" (e.g. in a
        // footer link) but not the login form's acct field must not be misclassified as a
        // failure. This guards the operator-precedence of the failure check.
        let response = "<html><body>news<a href='/login'>Login</a></body></html>"
        let network = MockAuthenticationNetworkManager(postResponse: response)
        let userDefaults = MockAuthenticationUserDefaults()
        let repository = AuthenticationRepository(networkManager: network, userDefaults: userDefaults)

        try await repository.authenticate(username: "user", password: "secret")

        #expect(userDefaults.string(forKey: "hn_username") == "user",
                "Stray 'Login' without the form should not block successful login")
    }

    @Test("Logout clears cookies and stored username")
    func logoutClearsCookiesAndUsername() async throws {
        let network = MockAuthenticationNetworkManager()
        let userDefaults = MockAuthenticationUserDefaults()
        userDefaults.set("user", forKey: "hn_username")
        let repository = AuthenticationRepository(networkManager: network, userDefaults: userDefaults)

        try await repository.logout()

        #expect(network.clearCookiesCallCount == 1)
        #expect(userDefaults.string(forKey: "hn_username") == nil)
    }

    @Test("Authentication state requires cookies and stored username")
    func authenticationStateRequiresCookiesAndUsername() async {
        let network = MockAuthenticationNetworkManager()
        let userDefaults = MockAuthenticationUserDefaults()
        let repository = AuthenticationRepository(networkManager: network, userDefaults: userDefaults)

        #expect(await repository.isAuthenticated() == false)

        network.hasCookie = true
        #expect(await repository.isAuthenticated() == false)

        userDefaults.set("user", forKey: "hn_username")
        #expect(await repository.isAuthenticated())
    }
}

private final class MockAuthenticationNetworkManager: NetworkManagerProtocol, @unchecked Sendable {
    var hasCookie = false
    var postBodies: [String] = []
    var clearCookiesCallCount = 0
    private let postResponse: String

    init(postResponse: String = "<html><body>news</body></html>") {
        self.postResponse = postResponse
    }

    func get(url _: URL) async throws -> String {
        "<html><body>login</body></html>"
    }

    func post(url _: URL, body: String) async throws -> String {
        postBodies.append(body)
        return postResponse
    }

    func clearCookies() {
        clearCookiesCallCount += 1
        hasCookie = false
    }

    func containsCookie(for _: URL) -> Bool {
        hasCookie
    }
}

private final class MockAuthenticationUserDefaults: UserDefaultsProtocol, @unchecked Sendable {
    private var storage: [String: Any] = [:]

    func object(forKey defaultName: String) -> Any? {
        storage[defaultName]
    }

    func bool(forKey defaultName: String) -> Bool {
        storage[defaultName] as? Bool ?? false
    }

    func integer(forKey defaultName: String) -> Int {
        storage[defaultName] as? Int ?? 0
    }

    func string(forKey defaultName: String) -> String? {
        storage[defaultName] as? String
    }

    func set(_ value: Bool, forKey defaultName: String) {
        storage[defaultName] = value
    }

    func set(_ value: Int, forKey defaultName: String) {
        storage[defaultName] = value
    }

    func set(_ value: Any?, forKey defaultName: String) {
        storage[defaultName] = value
    }
}
