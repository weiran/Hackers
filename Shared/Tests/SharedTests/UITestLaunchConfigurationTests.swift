#if DEBUG
@testable import Domain
@testable import Shared
import Testing

@Suite("UI-test launch configuration")
struct UITestLaunchConfigurationTests {
    @Test("Disabled launches do not create a configuration")
    func disabledLaunch() throws {
        #expect(try UITestLaunchConfiguration.parse(environment: [:]) == nil)
        #expect(try UITestLaunchConfiguration.parse(environment: [
            "HACKERS_UI_TESTING": "0"
        ]) == nil)
    }

    @Test("Defaults provide deterministic functional-test behavior")
    func defaults() throws {
        let parsedConfiguration = try UITestLaunchConfiguration.parse(environment: [
            "HACKERS_UI_TESTING": "1"
        ])
        let configuration = try #require(parsedConfiguration)

        #expect(configuration == UITestLaunchConfiguration())
    }

    @Test("Story routes parse all supported fields")
    func storyRoute() throws {
        let parsedConfiguration = try UITestLaunchConfiguration.parse(environment: [
            "HACKERS_UI_TESTING": "1",
            "HACKERS_UI_BROWSER_MODE": "custom",
            "HACKERS_UI_ROUTE": "story",
            "HACKERS_UI_POST_ID": "48350598",
            "HACKERS_UI_STORY_PRESENTATION": "expandedComments",
            "HACKERS_UI_ARTICLE_SOURCE": "live",
            "HACKERS_UI_FIXTURE_PROFILE": "stress",
            "HACKERS_UI_READ_POST_IDS": "1, 2,2",
            "HACKERS_UI_DIM_READ_POSTS": "0",
            "HACKERS_UI_SHOW_THUMBNAILS": "1"
        ])
        let configuration = try #require(parsedConfiguration)

        #expect(configuration.browserMode == .customBrowser)
        #expect(configuration.route == .story(postID: 48_350_598, presentation: .expandedComments))
        #expect(configuration.articleSource == .live)
        #expect(configuration.fixtureProfile == .stress)
        #expect(configuration.readPostIDs == [1, 2])
        #expect(configuration.dimReadPosts == false)
        #expect(configuration.showThumbnails)
    }

    @Test("Encoded environments round-trip through the parser")
    func environmentRoundTrip() throws {
        let expected = UITestLaunchConfiguration(
            browserMode: .customBrowser,
            route: .story(postID: 48_350_598, presentation: .expandedComments),
            articleSource: .fixture,
            fixtureProfile: .marketing,
            readPostIDs: [48_345_248, 48_347_354],
            dimReadPosts: true,
            showThumbnails: true
        )

        #expect(try UITestLaunchConfiguration.parse(environment: expected.environment) == expected)
    }

    @Test("Comments routes require a post ID")
    func missingCommentsPostID() {
        #expect(throws: UITestLaunchConfiguration.ParseError.missingValue(
            key: "HACKERS_UI_POST_ID",
            route: "comments"
        )) {
            try UITestLaunchConfiguration.parse(environment: [
                "HACKERS_UI_TESTING": "1",
                "HACKERS_UI_ROUTE": "comments"
            ])
        }
    }

    @Test("Feed routes reject story fields")
    func invalidFeedFields() {
        #expect(throws: UITestLaunchConfiguration.ParseError.unexpectedValue(
            key: "HACKERS_UI_POST_ID",
            route: "feed"
        )) {
            try UITestLaunchConfiguration.parse(environment: [
                "HACKERS_UI_TESTING": "1",
                "HACKERS_UI_POST_ID": "123"
            ])
        }
    }

    @Test("System browser mode is explicitly unsupported")
    func systemBrowser() {
        #expect(throws: UITestLaunchConfiguration.ParseError.unsupportedBrowserMode("system")) {
            try UITestLaunchConfiguration.parse(environment: [
                "HACKERS_UI_TESTING": "1",
                "HACKERS_UI_BROWSER_MODE": "system"
            ])
        }
    }

    @Test("Story routes reject browser modes that cannot present them")
    func incompatibleStoryBrowserMode() {
        #expect(throws: UITestLaunchConfiguration.ParseError.incompatibleValues(
            key: "HACKERS_UI_ROUTE",
            value: "story",
            otherKey: "HACKERS_UI_BROWSER_MODE",
            otherValue: "inApp"
        )) {
            try UITestLaunchConfiguration.parse(environment: [
                "HACKERS_UI_TESTING": "1",
                "HACKERS_UI_BROWSER_MODE": "inApp",
                "HACKERS_UI_ROUTE": "story",
                "HACKERS_UI_POST_ID": "48350598"
            ])
        }
    }

    @Test("Malformed test opt-in values fail parsing", arguments: ["", "true", " "])
    func malformedTestingOptIn(value: String) {
        #expect(throws: UITestLaunchConfiguration.ParseError.invalidValue(
            key: "HACKERS_UI_TESTING",
            value: value
        )) {
            try UITestLaunchConfiguration.parse(environment: [
                "HACKERS_UI_TESTING": value
            ])
        }
    }

    @Test("Unknown UI-test keys fail parsing")
    func unknownKey() {
        #expect(throws: UITestLaunchConfiguration.ParseError.unknownKey("HACKERS_UI_BROWSER")) {
            try UITestLaunchConfiguration.parse(environment: [
                "HACKERS_UI_TESTING": "1",
                "HACKERS_UI_BROWSER": "custom"
            ])
        }
    }

    @Test("Post and read IDs must be positive", arguments: ["0", "-1"])
    func nonPositiveIDs(value: String) {
        #expect(throws: UITestLaunchConfiguration.ParseError.invalidValue(
            key: "HACKERS_UI_POST_ID",
            value: value
        )) {
            try UITestLaunchConfiguration.parse(environment: [
                "HACKERS_UI_TESTING": "1",
                "HACKERS_UI_ROUTE": "comments",
                "HACKERS_UI_POST_ID": value
            ])
        }

        #expect(throws: UITestLaunchConfiguration.ParseError.invalidValue(
            key: "HACKERS_UI_READ_POST_IDS",
            value: value
        )) {
            try UITestLaunchConfiguration.parse(environment: [
                "HACKERS_UI_TESTING": "1",
                "HACKERS_UI_READ_POST_IDS": value
            ])
        }
    }

    @Test("Malformed booleans and ID lists fail parsing", arguments: [
        ["HACKERS_UI_DIM_READ_POSTS": "true"],
        ["HACKERS_UI_READ_POST_IDS": "1,nope"]
    ])
    func malformedValues(values: [String: String]) {
        #expect(throws: UITestLaunchConfiguration.ParseError.self) {
            try UITestLaunchConfiguration.parse(environment: values.merging([
                "HACKERS_UI_TESTING": "1"
            ]) { current, _ in current })
        }
    }
}
#endif
