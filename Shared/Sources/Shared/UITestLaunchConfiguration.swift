#if DEBUG
import Domain
import Foundation

public struct UITestLaunchConfiguration: Equatable, Sendable {
    public enum Route: Equatable, Sendable {
        case feed
        case comments(postID: Int)
        case story(postID: Int, presentation: PostLinkPresentation)
    }

    public enum ArticleSource: Equatable, Sendable {
        case fixture
        case live
    }

    public enum ParseError: Error, Equatable, CustomStringConvertible {
        case invalidValue(key: String, value: String)
        case missingValue(key: String, route: String)
        case unsupportedBrowserMode(String)
        case unexpectedValue(key: String, route: String)

        public var description: String {
            switch self {
            case let .invalidValue(key, value):
                "Invalid UI-test launch value for \(key): \(value)"
            case let .missingValue(key, route):
                "UI-test route \(route) requires \(key)"
            case let .unsupportedBrowserMode(mode):
                "UI tests do not support browser mode: \(mode)"
            case let .unexpectedValue(key, route):
                "UI-test route \(route) does not accept \(key)"
            }
        }
    }

    public let browserMode: LinkBrowserMode
    public let route: Route
    public let articleSource: ArticleSource
    public let readPostIDs: Set<Int>
    public let dimReadPosts: Bool
    public let showThumbnails: Bool

    public init(
        browserMode: LinkBrowserMode = .customBrowser,
        route: Route = .feed,
        articleSource: ArticleSource = .fixture,
        readPostIDs: Set<Int> = [],
        dimReadPosts: Bool = true,
        showThumbnails: Bool = false
    ) {
        self.browserMode = browserMode
        self.route = route
        self.articleSource = articleSource
        self.readPostIDs = readPostIDs
        self.dimReadPosts = dimReadPosts
        self.showThumbnails = showThumbnails
    }

    public static func parse(environment: [String: String]) throws -> UITestLaunchConfiguration? {
        guard environment["HACKERS_UI_TESTING"] == "1" else { return nil }

        let routeName = environment["HACKERS_UI_ROUTE"] ?? "feed"
        let postID = try optionalInteger(environment["HACKERS_UI_POST_ID"], key: "HACKERS_UI_POST_ID")
        let presentationValue = environment["HACKERS_UI_STORY_PRESENTATION"]

        let route: Route
        switch routeName {
        case "feed":
            if postID != nil {
                throw ParseError.unexpectedValue(key: "HACKERS_UI_POST_ID", route: routeName)
            }
            if presentationValue != nil {
                throw ParseError.unexpectedValue(key: "HACKERS_UI_STORY_PRESENTATION", route: routeName)
            }
            route = .feed
        case "comments":
            guard let postID else {
                throw ParseError.missingValue(key: "HACKERS_UI_POST_ID", route: routeName)
            }
            if presentationValue != nil {
                throw ParseError.unexpectedValue(key: "HACKERS_UI_STORY_PRESENTATION", route: routeName)
            }
            route = .comments(postID: postID)
        case "story":
            guard let postID else {
                throw ParseError.missingValue(key: "HACKERS_UI_POST_ID", route: routeName)
            }
            let presentation: PostLinkPresentation
            switch presentationValue ?? "collapsedBrowser" {
            case "collapsedBrowser": presentation = .collapsedBrowser
            case "expandedComments": presentation = .expandedComments
            case let value:
                throw ParseError.invalidValue(key: "HACKERS_UI_STORY_PRESENTATION", value: value)
            }
            route = .story(postID: postID, presentation: presentation)
        case let value:
            throw ParseError.invalidValue(key: "HACKERS_UI_ROUTE", value: value)
        }

        let browserMode: LinkBrowserMode
        switch environment["HACKERS_UI_BROWSER_MODE"] ?? "custom" {
        case "custom": browserMode = .customBrowser
        case "inApp": browserMode = .inAppBrowser
        case "system":
            throw ParseError.unsupportedBrowserMode("system")
        case let value:
            throw ParseError.invalidValue(key: "HACKERS_UI_BROWSER_MODE", value: value)
        }

        let articleSource: ArticleSource
        switch environment["HACKERS_UI_ARTICLE_SOURCE"] ?? "fixture" {
        case "fixture": articleSource = .fixture
        case "live": articleSource = .live
        case let value:
            throw ParseError.invalidValue(key: "HACKERS_UI_ARTICLE_SOURCE", value: value)
        }

        let readPostIDs = try integerSet(environment["HACKERS_UI_READ_POST_IDS"], key: "HACKERS_UI_READ_POST_IDS")
        let dimReadPosts = try boolean(environment["HACKERS_UI_DIM_READ_POSTS"], key: "HACKERS_UI_DIM_READ_POSTS") ?? true
        let showThumbnails = try boolean(environment["HACKERS_UI_SHOW_THUMBNAILS"], key: "HACKERS_UI_SHOW_THUMBNAILS") ?? false

        return UITestLaunchConfiguration(
            browserMode: browserMode,
            route: route,
            articleSource: articleSource,
            readPostIDs: readPostIDs,
            dimReadPosts: dimReadPosts,
            showThumbnails: showThumbnails
        )
    }

    private static func optionalInteger(_ value: String?, key: String) throws -> Int? {
        guard let value else { return nil }
        guard !value.isEmpty, let integer = Int(value) else {
            throw ParseError.invalidValue(key: key, value: value)
        }
        return integer
    }

    private static func integerSet(_ value: String?, key: String) throws -> Set<Int> {
        guard let value, !value.isEmpty else { return [] }
        let components = value.split(separator: ",", omittingEmptySubsequences: false)
        let integers = try components.map { component in
            let value = String(component).trimmingCharacters(in: .whitespacesAndNewlines)
            guard !value.isEmpty, let integer = Int(value) else {
                throw ParseError.invalidValue(key: key, value: value)
            }
            return integer
        }
        return Set(integers)
    }

    private static func boolean(_ value: String?, key: String) throws -> Bool? {
        guard let value else { return nil }
        switch value {
        case "1": return true
        case "0": return false
        default: throw ParseError.invalidValue(key: key, value: value)
        }
    }
}
#endif
