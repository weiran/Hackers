//
//  HackerNewsConstants.swift
//  Shared
//
//  Copyright © 2025 Weiran Zhang. All rights reserved.
//

import Domain
import Foundation

public struct HackerNewsConstants {
    public static let baseURL = "https://news.ycombinator.com"
    public static let host = "news.ycombinator.com"
    public static let itemPrefix = "item?id="

    private init() {}

    public static func isItemURL(_ url: URL) -> Bool {
        if let urlHost = url.host?.lowercased(), urlHost != host {
            return false
        }

        return url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/")) == "item"
    }

    public static func itemID(from url: URL) -> Int? {
        guard isItemURL(url),
              let components = URLComponents(url: url, resolvingAgainstBaseURL: true)
        else { return nil }

        return components.queryItems?.first(where: { $0.name == "id" })?.value.flatMap(Int.init)
    }
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
