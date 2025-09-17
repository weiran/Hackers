//
//  HackerNewsConstants.swift
//  Shared
//
//  Copyright © 2025 Weiran Zhang. All rights reserved.
//

import Foundation
import Domain

public struct HackerNewsConstants {
    public static let baseURL = "https://news.ycombinator.com"
    public static let host = "news.ycombinator.com"
    public static let itemPrefix = "item?id="

    private init() {}
}

public extension Post {
    var hackerNewsURL: URL {
        URL(string: "\(HackerNewsConstants.baseURL)/item?id=\(id)")!
    }
}

public extension Comment {
    var hackerNewsURL: URL {
        URL(string: "\(HackerNewsConstants.baseURL)/item?id=\(id)")!
    }
}
