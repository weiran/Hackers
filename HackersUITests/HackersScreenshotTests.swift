import XCTest

@MainActor
final class HackersScreenshotTests: XCTestCase {
    private enum BrowserMode: String {
        case custom
        case inApp
    }

    private enum ArticleSource: String {
        case fixture
        case live
    }

    private enum Route {
        case feed
        case comments(postID: Int)
        case story(postID: Int)
    }

    private struct LaunchConfiguration {
        let browserMode: BrowserMode
        var articleSource: ArticleSource = .fixture
        var route: Route = .feed
        var readPostIDs: [Int] = []
    }

    private let screenshotPostID = 48_350_598
    private let screenshotPostTitle = "Swift 6.2 Released"
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testAppStoreScreenshots() throws {
        launchApp(configuration: LaunchConfiguration(browserMode: .inApp))

        XCTAssertTrue(app.collectionViews["feed.list"].waitForExistence(timeout: 8))
        XCTAssertTrue(app.staticTexts[screenshotPostTitle].waitForExistence(timeout: 5))
        snapshot("01-feed-built-for-reading")

        relaunch(configuration: LaunchConfiguration(
            browserMode: .custom,
            articleSource: .live,
            route: .story(postID: screenshotPostID)
        ))
        waitForRealArticleContent()
        snapshot("02-open-stories-inside-hackers")

        relaunch(configuration: LaunchConfiguration(
            browserMode: .inApp,
            route: .comments(postID: screenshotPostID)
        ))
        waitForScreenshotComments()
        snapshot("03-read-comments-alongside-story")

        relaunch(configuration: LaunchConfiguration(browserMode: .inApp))
        XCTAssertTrue(app.collectionViews["feed.list"].waitForExistence(timeout: 8))
        tapBottomBarSearchButton()

        let searchField = app.searchFields.firstMatch
        XCTAssertTrue(searchField.waitForExistence(timeout: 5))
        searchField.tap()
        searchField.typeText("Swift")
        XCTAssertTrue(app.staticTexts[screenshotPostTitle].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["search.sort.menu"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["search.date.menu"].waitForExistence(timeout: 5))
        snapshot("04-search-by-popular-recent-date")

        relaunch(configuration: LaunchConfiguration(
            browserMode: .inApp,
            readPostIDs: [48_345_248, 48_347_354, 48_345_840]
        ))
        XCTAssertTrue(app.collectionViews["feed.list"].waitForExistence(timeout: 8))
        XCTAssertTrue(app.staticTexts[screenshotPostTitle].waitForExistence(timeout: 5))
        snapshot("05-dim-read-posts-across-devices")

        relaunch(configuration: LaunchConfiguration(
            browserMode: .inApp,
            route: .comments(postID: screenshotPostID)
        ))
        waitForScreenshotComments()
        scrollCommentsDownSlightly()
        snapshot("06-vote-reply-follow-deep-threads")
    }

    private func launchApp(configuration: LaunchConfiguration) {
        app = XCUIApplication(bundleIdentifier: "com.weiranzhang.Hackers")
        setupSnapshot(app)
        configureApp(configuration)
        app.launch()
    }

    private func relaunch(configuration: LaunchConfiguration) {
        app.terminate()
        configureApp(configuration)
        app.launch()
    }

    private func configureApp(_ configuration: LaunchConfiguration) {
        app.launchEnvironment["HACKERS_UI_TESTING"] = "1"
        app.launchEnvironment["HACKERS_UI_BROWSER_MODE"] = configuration.browserMode.rawValue
        app.launchEnvironment["HACKERS_UI_ARTICLE_SOURCE"] = configuration.articleSource.rawValue
        app.launchEnvironment["HACKERS_UI_READ_POST_IDS"] = configuration.readPostIDs.map(String.init).joined(separator: ",")
        app.launchEnvironment["HACKERS_UI_DIM_READ_POSTS"] = configuration.readPostIDs.isEmpty ? "0" : "1"
        app.launchEnvironment["HACKERS_UI_SHOW_THUMBNAILS"] = "1"
        app.launchEnvironment.removeValue(forKey: "HACKERS_UI_POST_ID")
        app.launchEnvironment.removeValue(forKey: "HACKERS_UI_STORY_PRESENTATION")

        switch configuration.route {
        case .feed:
            app.launchEnvironment["HACKERS_UI_ROUTE"] = "feed"
        case let .comments(postID):
            app.launchEnvironment["HACKERS_UI_ROUTE"] = "comments"
            app.launchEnvironment["HACKERS_UI_POST_ID"] = String(postID)
        case let .story(postID):
            app.launchEnvironment["HACKERS_UI_ROUTE"] = "story"
            app.launchEnvironment["HACKERS_UI_POST_ID"] = String(postID)
            app.launchEnvironment["HACKERS_UI_STORY_PRESENTATION"] = "collapsedBrowser"
        }
    }

    private func tapScreenshotPost() {
        let post = app.buttons.matching(identifier: "feed.post.\(screenshotPostID)").firstMatch
        XCTAssertTrue(post.waitForExistence(timeout: 5))
        post.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
    }

    private func tapBottomBarSearchButton() {
        let searchButton = app.buttons["Search"]
        if searchButton.waitForExistence(timeout: 2), searchButton.isHittable {
            searchButton.tap()
            return
        }

        let coordinate = app.coordinate(withNormalizedOffset: CGVector(dx: 0.88, dy: 0.92))
        coordinate.tap()
    }

    private func scrollCommentsDownSlightly() {
        let commentsList = app.descendants(matching: .any)["comments.list"]
        guard commentsList.waitForExistence(timeout: 2) else {
            app.swipeUp()
            return
        }

        let start = commentsList.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.62))
        let end = commentsList.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.55))
        start.press(forDuration: 0.05, thenDragTo: end)
    }

    private func waitForScreenshotComments() {
        XCTAssertTrue(app.staticTexts["manakov_dev"].waitForExistence(timeout: 10))
    }

    private func waitForRealArticleContent() {
        let webView = app.webViews.firstMatch
        XCTAssertTrue(webView.waitForExistence(timeout: 20))
        XCTAssertTrue(webView.staticTexts[screenshotPostTitle].waitForExistence(timeout: 20))
        let collapsedHeader = app.descendants(matching: .any)
            .matching(identifier: "browser.commentsSheet.collapsedHeader")
            .firstMatch
        XCTAssertTrue(collapsedHeader.waitForExistence(timeout: 10))
        XCTAssertTrue(app.frame.intersects(collapsedHeader.frame))
    }

    private var isWideLayout: Bool {
        app.windows.firstMatch.frame.width >= 700
    }
}
