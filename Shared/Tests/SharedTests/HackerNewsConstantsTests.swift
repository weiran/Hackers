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
}
