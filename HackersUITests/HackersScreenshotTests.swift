import XCTest

@MainActor
final class HackersScreenshotTests: XCTestCase {
    private let screenshotPostTitle = "Chuwi Minibook X"
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
        snapshot("01-top-feed")

        tapScreenshotPost()
        XCTAssertTrue(app.collectionViews["comments.list"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["manakov_dev"].waitForExistence(timeout: 5))
        snapshot("02-comments")

        if !isWideLayout {
            scrollCommentsDownSlightly()
            snapshot("02-comments-scrolled")
        }

        if isWideLayout {
            snapshot("03-article")
        } else {
            relaunch(linkBrowserMode: "custom")
            XCTAssertTrue(app.collectionViews["feed.list"].waitForExistence(timeout: 8))
            tapScreenshotPost()
            XCTAssertTrue(app.otherElements["browser.view"].waitForExistence(timeout: 5))
            XCTAssertTrue(
                app.staticTexts["Fixture article loaded from the UI-test Hacker News Active snapshot."]
                    .waitForExistence(timeout: 5)
            )
            snapshot("03-article")

            relaunch(linkBrowserMode: "custom", usesArticleFixtures: false)
            XCTAssertTrue(app.collectionViews["feed.list"].waitForExistence(timeout: 8))
            tapScreenshotPostThumbnail()
            XCTAssertTrue(app.otherElements["browser.view"].waitForExistence(timeout: 5))
            XCTAssertTrue(app.webViews.firstMatch.waitForExistence(timeout: 15))
            XCTAssertFalse(app.otherElements["browser.mockArticle"].exists)
            waitForRealArticleContent()
            snapshot("03-browser-comments-collapsed")
        }

        relaunch(linkBrowserMode: "inApp")
        XCTAssertTrue(app.collectionViews["feed.list"].waitForExistence(timeout: 8))
        app.buttons["Search"].tap()

        let searchField = app.searchFields.firstMatch
        XCTAssertTrue(searchField.waitForExistence(timeout: 5))
        searchField.tap()
        searchField.typeText("Chuwi")
        XCTAssertTrue(app.staticTexts[screenshotPostTitle].waitForExistence(timeout: 5))
        snapshot("04-search")

        relaunch(linkBrowserMode: "inApp")
        XCTAssertTrue(app.collectionViews["feed.list"].waitForExistence(timeout: 8))
        app.buttons["settings.button"].tap()
        XCTAssertTrue(app.collectionViews["settings.form"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.switches["settings.showThumbnails"].waitForExistence(timeout: 5))
        snapshot("05-settings")
    }

    private func launchApp(linkBrowserMode: String, usesArticleFixtures: Bool = true) {
        app = XCUIApplication(bundleIdentifier: "com.weiranzhang.Hackers")
        setupSnapshot(app)
        configureApp(linkBrowserMode: linkBrowserMode, usesArticleFixtures: usesArticleFixtures)
        app.launch()
    }

    private func relaunch(linkBrowserMode: String, usesArticleFixtures: Bool = true) {
        app.terminate()
        configureApp(linkBrowserMode: linkBrowserMode, usesArticleFixtures: usesArticleFixtures)
        app.launch()
    }

    private func configureApp(linkBrowserMode: String, usesArticleFixtures: Bool) {
        appendLaunchArgument("--ui-testing")
        appendLaunchArgument("--screenshots")
        app.launchEnvironment["HACKERS_UI_TESTING"] = "1"
        app.launchEnvironment["HACKERS_SCREENSHOTS"] = "1"
        app.launchEnvironment["HACKERS_UI_LINK_BROWSER_MODE"] = linkBrowserMode
        app.launchEnvironment["HACKERS_UI_ARTICLE_FIXTURES"] = usesArticleFixtures ? "1" : "0"
    }

    private func appendLaunchArgument(_ argument: String) {
        if !app.launchArguments.contains(argument) {
            app.launchArguments.append(argument)
        }
    }

    private func tapScreenshotPost() {
        let title = app.staticTexts[screenshotPostTitle]
        XCTAssertTrue(title.waitForExistence(timeout: 5))
        title.tap()
    }

    private func tapScreenshotPostThumbnail() {
        let title = app.staticTexts[screenshotPostTitle]
        XCTAssertTrue(title.waitForExistence(timeout: 5))

        let thumbnailCoordinate = app.coordinate(
            withNormalizedOffset: CGVector(dx: 0, dy: 0)
        ).withOffset(CGVector(dx: max(title.frame.minX - 70, 30), dy: title.frame.midY))
        thumbnailCoordinate.tap()
    }

    private func scrollCommentsDownSlightly() {
        let commentsList = app.collectionViews["comments.list"]
        XCTAssertTrue(commentsList.waitForExistence(timeout: 5))

        let start = commentsList.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.62))
        let end = commentsList.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.55))
        start.press(forDuration: 0.05, thenDragTo: end)
    }

    private func waitForRealArticleContent() {
        let titlePredicate = NSPredicate { [self, screenshotPostTitle] _, _ in
            self.app.webViews.staticTexts[screenshotPostTitle].exists
                || self.app.staticTexts[screenshotPostTitle].exists
        }
        let result = XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: titlePredicate, object: app)], timeout: 20)
        XCTAssertEqual(result, .completed)
    }

    private var isWideLayout: Bool {
        app.windows.firstMatch.frame.width >= 700
    }
}
