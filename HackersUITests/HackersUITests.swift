import XCTest

final class HackersUITests: XCTestCase {
    private let screenshotPostID = 48_350_598
    private let longCommentsPostID = 48_345_840
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

    func testCustomBrowserCommentsSheetCollapsedPreview() throws {
        launchApp(linkBrowserMode: "custom")

        let post = app.buttons["feed.post.\(longCommentsPostID)"]
        XCTAssertTrue(post.waitForExistence(timeout: 8))
        tapPost(post)

        XCTAssertTrue(app.otherElements["browser.view"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Fixture article loaded from the UI-test Hacker News Active snapshot."].waitForExistence(timeout: 5))

        let collapsedHeader = app.staticTexts["HACKTIVIS.ME"].firstMatch
        XCTAssertTrue(collapsedHeader.waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["366"].firstMatch.exists)
        XCTAssertTrue(app.staticTexts["675"].firstMatch.exists)
    }

    func testCustomBrowserExpandedCommentsChrome() throws {
        launchApp(linkBrowserMode: "custom")

        let post = app.buttons["feed.post.\(longCommentsPostID)"]
        XCTAssertTrue(post.waitForExistence(timeout: 8))
        tapPost(post)

        XCTAssertTrue(app.otherElements["browser.view"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Cloudflare Turnstile requiring fingerprintable WebGL"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["browser.commentsSheet.back"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Share"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["Reload"].exists)
        XCTAssertFalse(app.buttons["Open in Safari"].exists)
        XCTAssertTrue(app.buttons["comments.comment.48346154"].waitForExistence(timeout: 5))
    }

    func testCustomBrowserTitlePillTapCollapsesExpandedComments() throws {
        launchApp(linkBrowserMode: "custom")

        let post = app.buttons["feed.post.\(longCommentsPostID)"]
        XCTAssertTrue(post.waitForExistence(timeout: 8))
        tapPost(post)

        let titlePill = app.buttons["Cloudflare Turnstile requiring fingerprintable WebGL"]
        XCTAssertTrue(titlePill.waitForExistence(timeout: 5))
        titlePill.tap()

        XCTAssertTrue(app.staticTexts["Fixture article loaded from the UI-test Hacker News Active snapshot."].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["HACKTIVIS.ME"].firstMatch.waitForExistence(timeout: 5))
    }

    func testCustomBrowserHandleDragCollapsesExpandedComments() throws {
        launchApp(linkBrowserMode: "custom")

        let post = app.buttons["feed.post.\(longCommentsPostID)"]
        XCTAssertTrue(post.waitForExistence(timeout: 8))
        tapPost(post)

        XCTAssertTrue(app.buttons["comments.comment.48346154"].waitForExistence(timeout: 5))

        let handle = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.08))
        let collapsedPosition = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.82))
        handle.press(forDuration: 0.1, thenDragTo: collapsedPosition)

        XCTAssertTrue(app.staticTexts["Fixture article loaded from the UI-test Hacker News Active snapshot."].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["HACKTIVIS.ME"].firstMatch.waitForExistence(timeout: 5))
    }

    func testCustomBrowserCommentsBodyDragAtTopCollapsesExpandedComments() throws {
        launchApp(linkBrowserMode: "custom")

        let post = app.buttons["feed.post.\(longCommentsPostID)"]
        XCTAssertTrue(post.waitForExistence(timeout: 8))
        tapPost(post)

        XCTAssertTrue(app.buttons["comments.comment.48346154"].waitForExistence(timeout: 5))

        let commentsBody = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.45))
        let collapsedPosition = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.82))
        commentsBody.press(forDuration: 0.1, thenDragTo: collapsedPosition)

        XCTAssertTrue(app.staticTexts["Fixture article loaded from the UI-test Hacker News Active snapshot."].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["HACKTIVIS.ME"].firstMatch.waitForExistence(timeout: 5))
    }

    func testSystemBackSwipeFromCustomBrowserCollapsedComments() throws {
        launchApp(linkBrowserMode: "custom")

        let post = app.buttons["feed.post.\(screenshotPostID)"]
        XCTAssertTrue(post.waitForExistence(timeout: 8))
        tapPost(post)

        XCTAssertTrue(app.otherElements["browser.view"].waitForExistence(timeout: 5))
        edgeSwipeBack()

        XCTAssertTrue(app.collectionViews["feed.list"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.otherElements["browser.view"].exists)
    }

    func testSystemBackSwipeFromCustomBrowserExpandedComments() throws {
        launchApp(linkBrowserMode: "custom")

        let post = app.buttons["feed.post.\(longCommentsPostID)"]
        XCTAssertTrue(post.waitForExistence(timeout: 8))
        tapPost(post)

        XCTAssertTrue(app.otherElements["browser.view"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["comments.comment.48346154"].waitForExistence(timeout: 5))

        edgeSwipeBack()

        XCTAssertTrue(app.collectionViews["feed.list"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.otherElements["browser.view"].exists)
    }

    func testSystemBackSwipeFromComments() throws {
        launchApp(linkBrowserMode: "inApp")

        let post = app.buttons["feed.post.\(screenshotPostID)"]
        XCTAssertTrue(post.waitForExistence(timeout: 8))
        tapPost(post)

        XCTAssertTrue(commentsList.waitForExistence(timeout: 5))
        edgeSwipeBack()

        XCTAssertTrue(app.collectionViews["feed.list"].waitForExistence(timeout: 5))
        XCTAssertFalse(commentsList.exists)
    }

    func testOpenCommentsFromFeed() throws {
        launchApp(linkBrowserMode: "inApp")

        let post = app.buttons["feed.post.\(screenshotPostID)"]
        XCTAssertTrue(post.waitForExistence(timeout: 8))
        tapPost(post)

        XCTAssertTrue(commentsList.waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Swift 6.2 Released"].exists)
        XCTAssertTrue(app.staticTexts["manakov_dev"].exists)
        XCTAssertTrue(app.staticTexts["Tiny machines make sense when travel weight matters more than benchmark numbers, especially for light terminal and browser work."].exists)
    }

    func testCollapsePreservesRootCommentContext() throws {
        launchApp(linkBrowserMode: "inApp")

        let post = app.buttons["feed.post.\(longCommentsPostID)"]
        XCTAssertTrue(post.waitForExistence(timeout: 8))
        tapPost(post)

        let list = commentsList
        XCTAssertTrue(list.waitForExistence(timeout: 5))

        let rootComment = app.buttons["comments.comment.48348985"]
        scroll(list, untilVisible: rootComment)
        XCTAssertTrue(rootComment.waitForExistence(timeout: 2))

        rootComment.tap()
        XCTAssertTrue(rootComment.waitForExistence(timeout: 2))
        XCTAssertTrue(list.frame.intersects(rootComment.frame))

        rootComment.press(forDuration: 1)
        XCTAssertTrue(app.buttons["Copy"].exists)
        XCTAssertTrue(app.buttons["Share"].exists)
    }

    func testSearchUsesMockedAlgoliaResults() throws {
        launchApp(initialSearchQuery: "Swift")

        XCTAssertTrue(app.staticTexts["Swift 6.2 Released"].waitForExistence(timeout: 8))
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

    private func launchApp(linkBrowserMode: String = "custom", initialSearchQuery: String? = nil) {
        app = XCUIApplication(bundleIdentifier: "com.weiranzhang.Hackers")
        app.terminate()
        app.launchArguments = ["--ui-testing"]
        app.launchEnvironment["HACKERS_UI_TESTING"] = "1"
        app.launchEnvironment["HACKERS_UI_LINK_BROWSER_MODE"] = linkBrowserMode
        app.launchEnvironment["HACKERS_UI_INITIAL_SEARCH_QUERY"] = initialSearchQuery ?? ""
        app.launch()
    }

    private var commentsList: XCUIElement {
        app.descendants(matching: .any)["comments.list"]
    }

    private func tapPost(_ post: XCUIElement) {
        post.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
    }

    private func scroll(_ container: XCUIElement, untilVisible element: XCUIElement, maxSwipes: Int = 6) {
        for _ in 0 ..< maxSwipes where !element.exists || !container.frame.intersects(element.frame) {
            container.swipeUp()
        }
    }

    private func edgeSwipeBack() {
        let start = app.coordinate(withNormalizedOffset: CGVector(dx: 0.01, dy: 0.5))
        let end = app.coordinate(withNormalizedOffset: CGVector(dx: 0.85, dy: 0.5))
        start.press(forDuration: 0.05, thenDragTo: end)
    }

}
