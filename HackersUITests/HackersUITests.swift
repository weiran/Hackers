import XCTest

final class HackersUITests: XCTestCase {
    private let screenshotPostID = 48_350_598
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {
        app = nil
    }

    func testSmokeLaunchFeedAndSettings() throws {
        launchApp()

        XCTAssertTrue(app.collectionViews["feed.list"].waitForExistence(timeout: 8))
        XCTAssertTrue(app.staticTexts["Swift 6.2 Released"].exists)
        XCTAssertTrue(app.staticTexts["Cloudflare Turnstile requiring fingerprintable WebGL"].exists)
        XCTAssertTrue(app.staticTexts["United Airlines 767 returns to Newark after Bluetooth name sparks alert"].exists)

        app.buttons["settings.button"].tap()

        XCTAssertTrue(app.collectionViews["settings.form"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Settings"].exists)
        XCTAssertTrue(app.switches["settings.showThumbnails"].exists)
        XCTAssertTrue(app.switches["settings.compactFeed"].exists)
        XCTAssertTrue(app.staticTexts.containing(NSPredicate(format: "label BEGINSWITH %@", "Version")).firstMatch.exists)
    }

    func testSmokeOpenCustomBrowserFromFeed() throws {
        launchApp(linkBrowserMode: "custom")

        let post = app.buttons["feed.post.\(screenshotPostID)"]
        XCTAssertTrue(post.waitForExistence(timeout: 8))
        tapPost(post)

        XCTAssertTrue(app.otherElements["browser.view"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Fixture article loaded from the UI-test Hacker News Active snapshot."].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Swift 6.2 Released"].exists)
    }

    func testOpenCommentsFromFeed() throws {
        launchApp(linkBrowserMode: "inApp")

        let post = app.buttons["feed.post.\(screenshotPostID)"]
        XCTAssertTrue(post.waitForExistence(timeout: 8))
        tapPost(post)

        XCTAssertTrue(app.collectionViews["comments.list"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Swift 6.2 Released"].exists)
        XCTAssertTrue(app.staticTexts["manakov_dev"].exists)
        XCTAssertTrue(app.staticTexts["Tiny machines make sense when travel weight matters more than benchmark numbers, especially for light terminal and browser work."].exists)
    }

    func testSearchUsesMockedAlgoliaResults() throws {
        launchApp()

        XCTAssertTrue(app.collectionViews["feed.list"].waitForExistence(timeout: 8))
        tapBottomBarSearchButton()

        let searchField = app.searchFields.firstMatch
        XCTAssertTrue(searchField.waitForExistence(timeout: 5))
        searchField.tap()
        searchField.typeText("Swift")

        XCTAssertTrue(app.staticTexts["Swift 6.2 Released"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["United Airlines 767 returns to Newark after Bluetooth name sparks alert"].exists)
    }

    func testCategoryMenuUsesMockedFeeds() throws {
        launchApp()

        XCTAssertTrue(app.collectionViews["feed.list"].waitForExistence(timeout: 8))
        app.navigationBars.buttons["Top"].tap()
        app.buttons["Ask"].tap()

        XCTAssertTrue(app.staticTexts["Ask HN: What are you using for iOS UI testing in 2026?"].waitForExistence(timeout: 5))
    }

    func testLoginFailureAndSuccessUseMockedAuthentication() throws {
        launchApp()

        XCTAssertTrue(app.collectionViews["feed.list"].waitForExistence(timeout: 8))
        app.buttons["settings.button"].tap()
        XCTAssertTrue(app.collectionViews["settings.form"].waitForExistence(timeout: 5))
        app.buttons["Login"].tap()

        let username = app.textFields["login.username"]
        let password = app.secureTextFields["login.password"]
        XCTAssertTrue(username.waitForExistence(timeout: 5))
        username.tap()
        username.typeText("ui-user")
        password.tap()
        password.typeText("wrong")
        app.buttons["login.signIn"].tap()
        XCTAssertTrue(app.alerts["Login Failed"].waitForExistence(timeout: 5))
        app.alerts["Login Failed"].buttons["OK"].tap()

        password.tap()
        password.typeText("password")
        app.buttons["login.signIn"].tap()

        XCTAssertTrue(app.staticTexts["Welcome back, ui-user"].waitForExistence(timeout: 5))
    }

    private func launchApp(linkBrowserMode: String = "custom") {
        app = XCUIApplication(bundleIdentifier: "com.weiranzhang.Hackers")
        app.terminate()
        app.launchArguments = ["--ui-testing"]
        app.launchEnvironment["HACKERS_UI_TESTING"] = "1"
        app.launchEnvironment["HACKERS_UI_LINK_BROWSER_MODE"] = linkBrowserMode
        app.launch()
    }

    private func tapPost(_ post: XCUIElement) {
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
}
