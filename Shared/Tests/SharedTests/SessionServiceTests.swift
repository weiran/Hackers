//
//  SessionServiceTests.swift
//  SharedTests
//

import Domain
import Foundation
import Testing
@testable import Shared

private actor DelayedCurrentUserAuthenticationUseCase: AuthenticationUseCase {
    private let delayedUser: User
    private var lookupCount = 0
    private var lookupStarted = false
    private var lookupStartWaiter: CheckedContinuation<Void, Never>?
    private var lookupContinuation: CheckedContinuation<User?, Never>?
    private var lookupReturned = false
    private var lookupReturnedWaiter: CheckedContinuation<Void, Never>?

    init(delayedUser: User) {
        self.delayedUser = delayedUser
    }

    func authenticate(username _: String, password _: String) async throws {}

    func logout() async throws {}

    func isAuthenticated() async -> Bool { false }

    func getCurrentUser() async -> User? {
        lookupCount += 1
        if lookupCount > 1 { return delayedUser }
        lookupStarted = true
        lookupStartWaiter?.resume()
        lookupStartWaiter = nil
        let user = await withCheckedContinuation { continuation in
            lookupContinuation = continuation
        }
        lookupReturned = true
        lookupReturnedWaiter?.resume()
        lookupReturnedWaiter = nil
        return user
    }

    func waitUntilLookupStarted() async {
        if lookupStarted { return }
        await withCheckedContinuation { continuation in
            lookupStartWaiter = continuation
        }
    }

    /// Deliberately ignores task cancellation to prove the service's generation guard.
    func releaseDelayedUser() {
        lookupContinuation?.resume(returning: delayedUser)
        lookupContinuation = nil
    }

    func waitUntilLookupReturned() async {
        if lookupReturned { return }
        await withCheckedContinuation { continuation in
            lookupReturnedWaiter = continuation
        }
    }
}

@MainActor
@Suite("SessionService")
struct SessionServiceTests {
    @Test("Logout invalidates a delayed startup user lookup")
    func logoutWinsOverDelayedStartupLookup() async {
        let delayedUser = User(username: "old-user", karma: 1, joined: Date(timeIntervalSince1970: 0))
        let authentication = DelayedCurrentUserAuthenticationUseCase(delayedUser: delayedUser)
        let service = SessionService(authenticationUseCase: authentication)

        await authentication.waitUntilLookupStarted()
        _ = try? await service.authenticate(username: "old-user", password: "password")
        NotificationCenter.default.post(name: .userDidLogout, object: nil)
        #expect(service.authenticationState == .notAuthenticated)
        await authentication.releaseDelayedUser()
        await authentication.waitUntilLookupReturned()

        #expect(service.authenticationState == .notAuthenticated)
        #expect(service.username == nil)
    }
}
