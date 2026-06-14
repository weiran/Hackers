import XCTest

@MainActor
final class HackersScreenshotTests: XCTestCase {
    private let screenshotPostID = 48_350_598
    private let screenshotPostTitle = "Swift 6.2 Released"
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {
        app = nil
    }

    func testAppStoreScreenshots() throws {
        launchApp(linkBrowserMode: "inApp")

        XCTAssertTrue(app.collectionViews["feed.list"].waitForExistence(timeout: 8))
        XCTAssertTrue(app.staticTexts[screenshotPostTitle].waitForExistence(timeout: 5))
        snapshot("01-feed-built-for-reading")

        relaunch(
            linkBrowserMode: "custom",
            usesArticleFixtures: false,
            initialLinkPostID: screenshotPostID
        )
        waitForRealArticleContent()
        snapshot("02-open-stories-inside-hackers")

        relaunch(linkBrowserMode: "inApp", initialPostID: screenshotPostID)
        waitForScreenshotComments()
        snapshot("03-read-comments-alongside-story")

        relaunch(linkBrowserMode: "inApp")
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

        relaunch(linkBrowserMode: "inApp", readPostIDs: [48_345_248, 48_347_354, 48_345_840])
        XCTAssertTrue(app.collectionViews["feed.list"].waitForExistence(timeout: 8))
        XCTAssertTrue(app.staticTexts[screenshotPostTitle].waitForExistence(timeout: 5))
        snapshot("05-dim-read-posts-across-devices")

        relaunch(linkBrowserMode: "inApp", initialPostID: screenshotPostID)
        waitForScreenshotComments()
        scrollCommentsDownSlightly()
        snapshot("06-vote-reply-follow-deep-threads")
    }

    private func launchApp(
        linkBrowserMode: String,
        usesArticleFixtures: Bool = true,
        readPostIDs: [Int] = [],
        initialPostID: Int? = nil,
        initialLinkPostID: Int? = nil,
        browserOnly: Bool = false
    ) {
        app = XCUIApplication(bundleIdentifier: "com.weiranzhang.Hackers")
        setupSnapshot(app)
        configureApp(
            linkBrowserMode: linkBrowserMode,
            usesArticleFixtures: usesArticleFixtures,
            readPostIDs: readPostIDs,
            initialPostID: initialPostID,
            initialLinkPostID: initialLinkPostID,
            browserOnly: browserOnly
        )
        app.launch()
    }

    private func relaunch(
        linkBrowserMode: String,
        usesArticleFixtures: Bool = true,
        readPostIDs: [Int] = [],
        initialPostID: Int? = nil,
        initialLinkPostID: Int? = nil,
        browserOnly: Bool = false
    ) {
        app.terminate()
        configureApp(
            linkBrowserMode: linkBrowserMode,
            usesArticleFixtures: usesArticleFixtures,
            readPostIDs: readPostIDs,
            initialPostID: initialPostID,
            initialLinkPostID: initialLinkPostID,
            browserOnly: browserOnly
        )
        app.launch()
    }

    private func configureApp(
        linkBrowserMode: String,
        usesArticleFixtures: Bool,
        readPostIDs: [Int],
        initialPostID: Int?,
        initialLinkPostID: Int?,
        browserOnly: Bool
    ) {
        appendLaunchArgument("--ui-testing")
        appendLaunchArgument("--screenshots")
        app.launchEnvironment["HACKERS_UI_TESTING"] = "1"
        app.launchEnvironment["HACKERS_SCREENSHOTS"] = "1"
        app.launchEnvironment["HACKERS_UI_LINK_BROWSER_MODE"] = linkBrowserMode
        app.launchEnvironment["HACKERS_UI_ARTICLE_FIXTURES"] = usesArticleFixtures ? "1" : "0"
        app.launchEnvironment["HACKERS_UI_DIM_READ_POSTS"] = readPostIDs.isEmpty ? "0" : "1"
        app.launchEnvironment["HACKERS_UI_READ_POST_IDS"] = readPostIDs.map(String.init).joined(separator: ",")
        app.launchEnvironment["HACKERS_UI_INITIAL_POST_ID"] = initialPostID.map(String.init) ?? ""
        app.launchEnvironment["HACKERS_UI_INITIAL_LINK_POST_ID"] = initialLinkPostID.map(String.init) ?? ""
        app.launchEnvironment["HACKERS_UI_BROWSER_ONLY"] = browserOnly ? "1" : "0"
    }

    private func appendLaunchArgument(_ argument: String) {
        if !app.launchArguments.contains(argument) {
            app.launchArguments.append(argument)
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
        let commentsList = app.collectionViews["comments.list"]
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
        let loadedPredicate = NSPredicate { [self] _, _ in
            self.app.webViews.firstMatch.exists
                || self.app.otherElements["browser.view"].exists
        }
        let result = XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: loadedPredicate, object: app)], timeout: 20)
        XCTAssertEqual(result, .completed)
        RunLoop.current.run(until: Date().addingTimeInterval(3))
        waitForScreenshotComments()
    }

    private var isWideLayout: Bool {
        app.windows.firstMatch.frame.width >= 700
    }
}
