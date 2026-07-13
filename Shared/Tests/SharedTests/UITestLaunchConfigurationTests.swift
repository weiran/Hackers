#if DEBUG
@testable import Domain
@testable import Shared
import Testing

@Suite("UI-test launch configuration")
struct UITestLaunchConfigurationTests {
    @Test("Disabled launches do not create a configuration")
    func disabledLaunch() throws {
        #expect(try UITestLaunchConfiguration.parse(environment: [:]) == nil)
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
            "HACKERS_UI_BROWSER_MODE": "inApp",
            "HACKERS_UI_ROUTE": "story",
            "HACKERS_UI_POST_ID": "48350598",
            "HACKERS_UI_STORY_PRESENTATION": "expandedComments",
            "HACKERS_UI_ARTICLE_SOURCE": "live",
            "HACKERS_UI_READ_POST_IDS": "1, 2,2",
            "HACKERS_UI_DIM_READ_POSTS": "0",
            "HACKERS_UI_SHOW_THUMBNAILS": "1"
        ])
        let configuration = try #require(parsedConfiguration)

        #expect(configuration.browserMode == .inAppBrowser)
        #expect(configuration.route == .story(postID: 48_350_598, presentation: .expandedComments))
        #expect(configuration.articleSource == .live)
        #expect(configuration.readPostIDs == [1, 2])
        #expect(configuration.dimReadPosts == false)
        #expect(configuration.showThumbnails)
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
