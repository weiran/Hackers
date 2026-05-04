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
        #expect(network.postBodies.first?.contains("acct=test%20user") == true)
        #expect(network.postBodies.first?.contains("pw=secret") == true)
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
