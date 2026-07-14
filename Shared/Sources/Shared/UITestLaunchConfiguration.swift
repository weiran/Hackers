import Domain
import Foundation

public struct UITestLaunchConfiguration: Equatable, Sendable {
    public enum EnvironmentKey: String, CaseIterable, Sendable {
        case testing = "HACKERS_UI_TESTING"
        case browserMode = "HACKERS_UI_BROWSER_MODE"
        case route = "HACKERS_UI_ROUTE"
        case postID = "HACKERS_UI_POST_ID"
        case storyPresentation = "HACKERS_UI_STORY_PRESENTATION"
        case articleSource = "HACKERS_UI_ARTICLE_SOURCE"
        case fixtureProfile = "HACKERS_UI_FIXTURE_PROFILE"
        case readPostIDs = "HACKERS_UI_READ_POST_IDS"
        case dimReadPosts = "HACKERS_UI_DIM_READ_POSTS"
        case showThumbnails = "HACKERS_UI_SHOW_THUMBNAILS"
    }

    public enum Route: Equatable, Sendable {
        case feed
        case comments(postID: Int)
        case story(postID: Int, presentation: PostLinkPresentation)
    }

    public enum ArticleSource: String, Equatable, Sendable {
        case fixture
        case live
    }

    public enum FixtureProfile: String, Equatable, Sendable {
        case functional
        case marketing
        case stress
    }

    public enum ParseError: Error, Equatable, CustomStringConvertible {
        case invalidValue(key: String, value: String)
        case incompatibleValues(key: String, value: String, otherKey: String, otherValue: String)
        case missingValue(key: String, route: String)
        case unknownKey(String)
        case unsupportedBrowserMode(String)
        case unexpectedValue(key: String, route: String)

        public var description: String {
            switch self {
            case let .invalidValue(key, value):
                "Invalid UI-test launch value for \(key): \(value)"
            case let .incompatibleValues(key, value, otherKey, otherValue):
                "UI-test launch value \(key)=\(value) is incompatible with \(otherKey)=\(otherValue)"
            case let .missingValue(key, route):
                "UI-test route \(route) requires \(key)"
            case let .unknownKey(key):
                "Unknown UI-test launch key: \(key)"
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
    public let fixtureProfile: FixtureProfile
    public let readPostIDs: Set<Int>
    public let dimReadPosts: Bool
    public let showThumbnails: Bool

    public init(
        browserMode: LinkBrowserMode = .customBrowser,
        route: Route = .feed,
        articleSource: ArticleSource = .fixture,
        fixtureProfile: FixtureProfile = .functional,
        readPostIDs: Set<Int> = [],
        dimReadPosts: Bool = true,
        showThumbnails: Bool = false
    ) {
        self.browserMode = browserMode
        self.route = route
        self.articleSource = articleSource
        self.fixtureProfile = fixtureProfile
        self.readPostIDs = readPostIDs
        self.dimReadPosts = dimReadPosts
        self.showThumbnails = showThumbnails
    }

    public var environment: [String: String] {
        var environment = [
            EnvironmentKey.testing.rawValue: "1",
            EnvironmentKey.browserMode.rawValue: browserMode.environmentValue,
            EnvironmentKey.articleSource.rawValue: articleSource.rawValue,
            EnvironmentKey.fixtureProfile.rawValue: fixtureProfile.rawValue,
            EnvironmentKey.dimReadPosts.rawValue: dimReadPosts ? "1" : "0",
            EnvironmentKey.showThumbnails.rawValue: showThumbnails ? "1" : "0"
        ]

        if !readPostIDs.isEmpty {
            environment[EnvironmentKey.readPostIDs.rawValue] = readPostIDs
                .sorted()
                .map(String.init)
                .joined(separator: ",")
        }

        switch route {
        case .feed:
            environment[EnvironmentKey.route.rawValue] = "feed"
        case let .comments(postID):
            environment[EnvironmentKey.route.rawValue] = "comments"
            environment[EnvironmentKey.postID.rawValue] = String(postID)
        case let .story(postID, presentation):
            environment[EnvironmentKey.route.rawValue] = "story"
            environment[EnvironmentKey.postID.rawValue] = String(postID)
            environment[EnvironmentKey.storyPresentation.rawValue] = presentation.environmentValue
        }

        return environment
    }

    public static func parse(environment: [String: String]) throws -> UITestLaunchConfiguration? {
        guard try isTestingEnabled(in: environment) else { return nil }
        try validateKnownKeys(in: environment)

        let route = try parseRoute(in: environment)
        let browserMode = try parseBrowserMode(in: environment)
        try validate(route: route, browserMode: browserMode)

        let articleSource = try enumValue(
            environment[EnvironmentKey.articleSource.rawValue],
            key: .articleSource,
            default: ArticleSource.fixture
        )
        let fixtureProfile = try enumValue(
            environment[EnvironmentKey.fixtureProfile.rawValue],
            key: .fixtureProfile,
            default: FixtureProfile.functional
        )

        let readPostIDsKey = EnvironmentKey.readPostIDs.rawValue
        let dimReadPostsKey = EnvironmentKey.dimReadPosts.rawValue
        let showThumbnailsKey = EnvironmentKey.showThumbnails.rawValue
        let readPostIDs = try positiveIntegerSet(environment[readPostIDsKey], key: readPostIDsKey)
        let dimReadPosts = try boolean(environment[dimReadPostsKey], key: dimReadPostsKey) ?? true
        let showThumbnails = try boolean(environment[showThumbnailsKey], key: showThumbnailsKey) ?? false

        return UITestLaunchConfiguration(
            browserMode: browserMode,
            route: route,
            articleSource: articleSource,
            fixtureProfile: fixtureProfile,
            readPostIDs: readPostIDs,
            dimReadPosts: dimReadPosts,
            showThumbnails: showThumbnails
        )
    }

    private static func isTestingEnabled(in environment: [String: String]) throws -> Bool {
        let key = EnvironmentKey.testing.rawValue
        guard let value = environment[key] else { return false }
        switch value {
        case "0": return false
        case "1": return true
        default: throw ParseError.invalidValue(key: key, value: value)
        }
    }

    private static func validateKnownKeys(in environment: [String: String]) throws {
        let supportedKeys = Set(EnvironmentKey.allCases.map(\.rawValue))
        if let unknownKey = environment.keys
            .filter({ $0.hasPrefix("HACKERS_UI_") && !supportedKeys.contains($0) })
            .sorted()
            .first {
            throw ParseError.unknownKey(unknownKey)
        }
    }

    private static func parseRoute(in environment: [String: String]) throws -> Route {
        let routeKey = EnvironmentKey.route.rawValue
        let postIDKey = EnvironmentKey.postID.rawValue
        let presentationKey = EnvironmentKey.storyPresentation.rawValue
        let routeName = environment[routeKey] ?? "feed"
        let postID = try optionalPositiveInteger(environment[postIDKey], key: postIDKey)
        let presentationValue = environment[presentationKey]

        switch routeName {
        case "feed":
            try reject(postID.map(String.init), key: postIDKey, route: routeName)
            try reject(presentationValue, key: presentationKey, route: routeName)
            return .feed
        case "comments":
            guard let postID else {
                throw ParseError.missingValue(key: postIDKey, route: routeName)
            }
            try reject(presentationValue, key: presentationKey, route: routeName)
            return .comments(postID: postID)
        case "story":
            guard let postID else {
                throw ParseError.missingValue(key: postIDKey, route: routeName)
            }
            return .story(
                postID: postID,
                presentation: try parsePresentation(presentationValue, key: presentationKey)
            )
        case let value:
            throw ParseError.invalidValue(key: routeKey, value: value)
        }
    }

    private static func parsePresentation(_ value: String?, key: String) throws -> PostLinkPresentation {
        switch value ?? "collapsedBrowser" {
        case "collapsedBrowser": return .collapsedBrowser
        case "expandedComments": return .expandedComments
        case let value: throw ParseError.invalidValue(key: key, value: value)
        }
    }

    private static func parseBrowserMode(in environment: [String: String]) throws -> LinkBrowserMode {
        let key = EnvironmentKey.browserMode.rawValue
        switch environment[key] ?? "custom" {
        case "custom": return .customBrowser
        case "inApp": return .inAppBrowser
        case "system": throw ParseError.unsupportedBrowserMode("system")
        case let value: throw ParseError.invalidValue(key: key, value: value)
        }
    }

    private static func validate(route: Route, browserMode: LinkBrowserMode) throws {
        guard case .story = route, browserMode != .customBrowser else { return }
        throw ParseError.incompatibleValues(
            key: EnvironmentKey.route.rawValue,
            value: "story",
            otherKey: EnvironmentKey.browserMode.rawValue,
            otherValue: browserMode.environmentValue
        )
    }

    private static func reject(_ value: String?, key: String, route: String) throws {
        guard value == nil else {
            throw ParseError.unexpectedValue(key: key, route: route)
        }
    }

    private static func enumValue<Value: RawRepresentable>(
        _ value: String?,
        key: EnvironmentKey,
        default defaultValue: Value
    ) throws -> Value where Value.RawValue == String {
        guard let value else { return defaultValue }
        guard let parsedValue = Value(rawValue: value) else {
            throw ParseError.invalidValue(key: key.rawValue, value: value)
        }
        return parsedValue
    }

    private static func optionalPositiveInteger(_ value: String?, key: String) throws -> Int? {
        guard let value else { return nil }
        guard !value.isEmpty, let integer = Int(value), integer > 0 else {
            throw ParseError.invalidValue(key: key, value: value)
        }
        return integer
    }

    private static func positiveIntegerSet(_ value: String?, key: String) throws -> Set<Int> {
        guard let value, !value.isEmpty else { return [] }
        let components = value.split(separator: ",", omittingEmptySubsequences: false)
        let integers = try components.map { component in
            let value = String(component).trimmingCharacters(in: .whitespacesAndNewlines)
            guard !value.isEmpty, let integer = Int(value), integer > 0 else {
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

private extension LinkBrowserMode {
    var environmentValue: String {
        switch self {
        case .customBrowser: "custom"
        case .inAppBrowser: "inApp"
        case .systemBrowser: "system"
        }
    }
}

private extension PostLinkPresentation {
    var environmentValue: String {
        switch self {
        case .collapsedBrowser: "collapsedBrowser"
        case .expandedComments: "expandedComments"
        }
    }
}
