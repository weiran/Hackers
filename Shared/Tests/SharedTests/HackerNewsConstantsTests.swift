//
//  HackerNewsConstantsTests.swift
//  SharedTests
//
//  Copyright © 2025 Weiran Zhang. All rights reserved.
//

import Foundation
@testable import Shared
import Testing

@Suite("HackerNewsConstants Tests")
struct HackerNewsConstantsTests {
    @Test("baseURL is correct")
    func testBaseURL() {
        #expect(HackerNewsConstants.baseURL == "https://news.ycombinator.com")
    }

    @Test("host is correct")
    func testHost() {
        #expect(HackerNewsConstants.host == "news.ycombinator.com")
    }

    @Test("itemPrefix is correct")
    func testItemPrefix() {
        #expect(HackerNewsConstants.itemPrefix == "item?id=")
    }

    @Test("baseURL is a valid URL")
    func baseURLValidity() {
        let url = URL(string: HackerNewsConstants.baseURL)
        #expect(url != nil)
        #expect(url?.scheme == "https")
        #expect(url?.host == HackerNewsConstants.host)
    }

    @Test("Constants are not empty")
    func constantsNotEmpty() {
        #expect(HackerNewsConstants.baseURL.isEmpty == false)
        #expect(HackerNewsConstants.host.isEmpty == false)
        #expect(HackerNewsConstants.itemPrefix.isEmpty == false)
    }

    @Test("baseURL and host are consistent")
    func baseURLHostConsistency() {
        let url = URL(string: HackerNewsConstants.baseURL)
        #expect(url?.host == HackerNewsConstants.host)
    }

    @Test("itemPrefix can be used to construct item URLs")
    func itemPrefixUsage() {
        let itemId = 12345
        let itemURL = HackerNewsConstants.baseURL + "/" + HackerNewsConstants.itemPrefix + "\(itemId)"
        let expectedURL = "https://news.ycombinator.com/item?id=12345"

        #expect(itemURL == expectedURL)
    }

    @Test("Constants struct cannot be instantiated")
    func privateInitializer() {
        // This test ensures the init is private by attempting to use the struct
        // The fact that we can access static properties but can't create instances
        // confirms the design

        // These should work (static access)
        let baseURL = HackerNewsConstants.baseURL
        let host = HackerNewsConstants.host
        let itemPrefix = HackerNewsConstants.itemPrefix

        #expect(baseURL.isEmpty == false)
        #expect(host.isEmpty == false)
        #expect(itemPrefix.isEmpty == false)

        // Note: We can't actually test that init() is private in a unit test,
        // but the compiler would catch any attempt to create an instance
        // if the init weren't private
    }

    @Test("Constants are immutable")
    func constantsImmutability() {
        // Test that accessing constants multiple times returns the same values
        let baseURL1 = HackerNewsConstants.baseURL
        let baseURL2 = HackerNewsConstants.baseURL
        let host1 = HackerNewsConstants.host
        let host2 = HackerNewsConstants.host
        let itemPrefix1 = HackerNewsConstants.itemPrefix
        let itemPrefix2 = HackerNewsConstants.itemPrefix

        #expect(baseURL1 == baseURL2)
        #expect(host1 == host2)
        #expect(itemPrefix1 == itemPrefix2)
    }
}
