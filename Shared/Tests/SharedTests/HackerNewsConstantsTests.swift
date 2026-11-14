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
    @Test("isItemURL handles absolute and relative item URLs")
    func isItemURLHandlesAbsoluteAndRelativeURLs() throws {
        #expect(HackerNewsConstants.isItemURL(try #require(URL(string: "https://news.ycombinator.com/item?id=123"))))
        #expect(HackerNewsConstants.isItemURL(try #require(URL(string: "item?id=123"))))
        #expect(HackerNewsConstants.isItemURL(try #require(URL(string: "/item?id=123"))))
        #expect(!HackerNewsConstants.isItemURL(try #require(URL(string: "https://example.com/item?id=123"))))
        #expect(!HackerNewsConstants.isItemURL(try #require(URL(string: "https://news.ycombinator.com/news"))))
    }

    @Test("itemID handles absolute and relative item URLs")
    func itemIDHandlesAbsoluteAndRelativeURLs() throws {
        #expect(HackerNewsConstants.itemID(from: try #require(URL(string: "https://news.ycombinator.com/item?id=123"))) == 123)
        #expect(HackerNewsConstants.itemID(from: try #require(URL(string: "item?id=456"))) == 456)
        #expect(HackerNewsConstants.itemID(from: try #require(URL(string: "https://example.com/item?id=789"))) == nil)
    }
}
