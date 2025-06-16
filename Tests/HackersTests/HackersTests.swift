//
//  HackersTests.swift
//  HackersTests
//
//  Created by Weiran Zhang on 16/06/2025.
//  Copyright © 2025 Glass Umbrella. All rights reserved.
//

import Testing
@testable import Hackers
import PromiseKit

class HackersTests {
    let sessionService: SessionService

    init() {
        sessionService = SessionService()
    }

    @Test func testAuthenticate() {
        firstly {
            sessionService.authenticate(username: "hackerstestuser", password: "hackerspassword")
        }.done { authenticationState in
            #expect(authenticationState == .authenticated, "Authentication failed")
        }
    }

    @Test func testUnauthenticate() {
        sessionService.unauthenticate()
        #expect(sessionService.authenticationState == .notAuthenticated, "Authentication state not reset")
    }
}
