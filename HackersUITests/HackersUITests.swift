import XCTest

final class HackersUITests: XCTestCase {
    private enum BrowserMode: String {
        case custom
        case inApp
    }

    private let screenshotPostID = 48_350_598
    private let longCommentsPostID = 48_345_840
    private let largeCommentsPostID = 48_399_999
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
        launchApp(linkBrowserMode: .custom)

        let post = app.buttons["feed.post.\(screenshotPostID)"]
        XCTAssertTrue(post.waitForExistence(timeout: 8))
        tapPost(post)

        XCTAssertTrue(app.otherElements["browser.view"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Fixture article loaded from the UI-test Hacker News Active snapshot."].waitForExistence(timeout: 5))
        let titlePill = app.buttons["Swift 6.2 Released"]
        XCTAssertTrue(titlePill.exists)
        XCTAssertLessThan(titlePill.frame.width, app.frame.width - 176)
    }

    func testCustomBrowserCommentsSheetCollapsedPreview() throws {
        launchApp(linkBrowserMode: .custom)

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
        XCUIDevice.shared.orientation = .portrait
        launchApp(linkBrowserMode: .custom)

        let post = app.buttons["feed.post.\(longCommentsPostID)"]
        XCTAssertTrue(post.waitForExistence(timeout: 8))
        tapPost(post)

        XCTAssertTrue(app.otherElements["browser.view"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Cloudflare Turnstile requiring fingerprintable WebGL"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["browser.commentsSheet.back"].exists)
        XCTAssertTrue(app.buttons["Share"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["Reload"].exists)
        XCTAssertFalse(app.buttons["Open in Safari"].exists)
        let firstComment = app.buttons["comments.comment.48346154"]
        XCTAssertTrue(firstComment.waitForExistence(timeout: 5))
        XCTAssertEqual(firstComment.frame.minX, 0, accuracy: 1)
        XCTAssertEqual(firstComment.frame.width, app.frame.width, accuracy: 1)
    }

    func testCustomBrowserTitlePillTapCollapsesExpandedComments() throws {
        launchApp(linkBrowserMode: .custom)

        let post = app.buttons["feed.post.\(longCommentsPostID)"]
        XCTAssertTrue(post.waitForExistence(timeout: 8))
        tapPost(post)

        let firstComment = app.buttons["comments.comment.48346154"]
        XCTAssertTrue(firstComment.waitForExistence(timeout: 5))
        dragCustomBrowserCommentsUp(count: 1)
        let sheetHandle = app.otherElements["Comments sheet handle"].firstMatch
        XCTAssertTrue(sheetHandle.waitForExistence(timeout: 5))
        let scrollStart = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.65))
        let scrollEnd = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.25))
        scrollStart.press(forDuration: 0.05, thenDragTo: scrollEnd)

        let titlePill = app.buttons["Cloudflare Turnstile requiring fingerprintable WebGL"]
        XCTAssertTrue(titlePill.waitForExistence(timeout: 5))
        let titlePillFrame = titlePill.frame
        XCTAssertTrue(app.frame.contains(titlePillFrame))
        XCTAssertLessThan(titlePillFrame.maxY, 120)
        XCTAssertLessThan(sheetHandle.frame.maxY, 120)
        tapAbsolutePoint(x: titlePillFrame.maxX - 12, y: titlePillFrame.midY)

        waitForFrameMinY(of: sheetHandle, greaterThan: app.frame.midY, timeout: 5)
        let postTapScreenshot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        postTapScreenshot.lifetime = .keepAlways
        add(postTapScreenshot)
        XCTAssertTrue(app.staticTexts["Fixture article loaded from the UI-test Hacker News Active snapshot."].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["HACKTIVIS.ME"].firstMatch.waitForExistence(timeout: 5))
    }

    func testCustomBrowserCollapsedHandleDragExpandsComments() throws {
        launchApp(linkBrowserMode: .custom)

        let post = app.buttons["feed.post.\(longCommentsPostID)"]
        XCTAssertTrue(post.waitForExistence(timeout: 8))
        tapPost(post)

        let sheetHandle = app.otherElements["Comments sheet handle"].firstMatch
        XCTAssertTrue(sheetHandle.waitForExistence(timeout: 5))
        XCTAssertLessThan(sheetHandle.frame.maxY, 120)
        let expandedHandle = app.coordinate(withNormalizedOffset: CGVector(
            dx: sheetHandle.frame.midX / app.frame.width,
            dy: sheetHandle.frame.midY / app.frame.height
        ))
        let collapsedPosition = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.82))
        expandedHandle.press(forDuration: 0.1, thenDragTo: collapsedPosition)
        waitForFrameMinY(of: sheetHandle, greaterThan: app.frame.midY, timeout: 5)

        let handle = app.coordinate(withNormalizedOffset: CGVector(
            dx: sheetHandle.frame.midX / app.frame.width,
            dy: sheetHandle.frame.midY / app.frame.height
        ))
        let expandedPosition = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.08))
        handle.press(forDuration: 0.1, thenDragTo: expandedPosition)

        waitForFrameMaxY(of: sheetHandle, lessThan: 120, timeout: 5)
        XCTAssertTrue(app.buttons["comments.comment.48346154"].waitForExistence(timeout: 5))
    }

    func testCustomBrowserPreservesCommentScrollPositionAcrossCollapse() throws {
        launchApp(linkBrowserMode: .custom)

        let post = app.buttons["feed.post.\(longCommentsPostID)"]
        XCTAssertTrue(post.waitForExistence(timeout: 8))
        tapPost(post)

        let lowerComment = app.buttons["comments.comment.48348985"]
        scrollCustomBrowserComments(untilVisible: lowerComment)
        XCTAssertTrue(app.frame.intersects(lowerComment.frame))
        let frameBeforeCollapse = lowerComment.frame

        let titlePill = app.buttons["Cloudflare Turnstile requiring fingerprintable WebGL"]
        XCTAssertTrue(titlePill.waitForExistence(timeout: 5))
        tapAbsolutePoint(x: titlePill.frame.midX, y: titlePill.frame.midY)

        let sheetHandle = app.otherElements["Comments sheet handle"].firstMatch
        waitForFrameMinY(of: sheetHandle, greaterThan: app.frame.midY, timeout: 5)
        tapAbsolutePoint(x: sheetHandle.frame.midX, y: sheetHandle.frame.maxY + 30)
        waitForFrameMaxY(of: sheetHandle, lessThan: 120, timeout: 5)

        XCTAssertTrue(lowerComment.waitForExistence(timeout: 5))
        XCTAssertEqual(lowerComment.frame.minY, frameBeforeCollapse.minY, accuracy: 1)
        let reexpandedTitlePill = app.buttons["Cloudflare Turnstile requiring fingerprintable WebGL"]
        XCTAssertTrue(reexpandedTitlePill.waitForExistence(timeout: 5))
        XCTAssertLessThan(reexpandedTitlePill.frame.maxY, 120)
        let screenshot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        screenshot.name = "Re-expanded comments preserve scroll position"
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }

    func testCustomBrowserHandleDragCollapsesExpandedComments() throws {
        launchApp(linkBrowserMode: .custom)

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

    func testCustomBrowserExpandedTopAreaDragCollapsesExpandedComments() throws {
        launchApp(linkBrowserMode: .custom)

        let post = app.buttons["feed.post.\(longCommentsPostID)"]
        XCTAssertTrue(post.waitForExistence(timeout: 8))
        tapPost(post)

        XCTAssertTrue(app.buttons["comments.comment.48346154"].waitForExistence(timeout: 5))

        let topTitleArea = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.18))
        let collapsedPosition = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.82))
        topTitleArea.press(forDuration: 0.1, thenDragTo: collapsedPosition)

        XCTAssertTrue(app.staticTexts["Fixture article loaded from the UI-test Hacker News Active snapshot."].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["HACKTIVIS.ME"].firstMatch.waitForExistence(timeout: 5))
    }

    func testCustomBrowserCommentsBodyDragAtTopCollapsesExpandedComments() throws {
        launchApp(linkBrowserMode: .custom)

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

    func testCustomBrowserCommentsReturnToTopRemainsResponsive() throws {
        launchApp(linkBrowserMode: .custom)

        let post = app.buttons["feed.post.\(longCommentsPostID)"]
        XCTAssertTrue(post.waitForExistence(timeout: 8))
        tapPost(post)

        let firstComment = app.buttons["comments.comment.48346154"]
        XCTAssertTrue(firstComment.waitForExistence(timeout: 5))

        let lowerComment = app.buttons["comments.comment.48348985"]
        scrollCustomBrowserComments(untilVisible: lowerComment)
        XCTAssertTrue(app.frame.intersects(lowerComment.frame))

        app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.01)).tap()

        XCTAssertTrue(firstComment.waitForExistence(timeout: 5))
        XCTAssertTrue(app.frame.intersects(firstComment.frame))

        let titlePill = app.buttons["Cloudflare Turnstile requiring fingerprintable WebGL"]
        XCTAssertTrue(titlePill.waitForExistence(timeout: 5))
        titlePill.tap()
        XCTAssertTrue(app.staticTexts["HACKTIVIS.ME"].firstMatch.waitForExistence(timeout: 5))
    }

    func testCustomBrowserLargeCommentsRemainResponsive() throws {
        launchApp(linkBrowserMode: .custom)

        let post = app.buttons["feed.post.\(largeCommentsPostID)"]
        XCTAssertTrue(post.waitForExistence(timeout: 8))
        tapPost(post)

        let firstComment = app.buttons["comments.comment.49000000"]
        XCTAssertTrue(firstComment.waitForExistence(timeout: 5))

        dragCustomBrowserCommentsUp(count: 12)
        XCTAssertFalse(firstComment.isHittable)

        app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.01)).tap()

        XCTAssertTrue(firstComment.waitForExistence(timeout: 5))
        XCTAssertTrue(app.frame.intersects(firstComment.frame))

        XCTAssertTrue(app.buttons["UI Test: Large Comments Performance Fixture"].waitForExistence(timeout: 5))
    }

    func testCustomBrowserLargeCommentBranchCollapsesAndExpands() throws {
        launchApp(linkBrowserMode: .custom)

        let post = app.buttons["feed.post.\(largeCommentsPostID)"]
        XCTAssertTrue(post.waitForExistence(timeout: 8))
        tapPost(post)

        let parent = app.buttons["comments.comment.49000003"]
        let firstChild = app.buttons["comments.comment.49000004"]
        XCTAssertTrue(firstChild.waitForExistence(timeout: 5))
        scrollCustomBrowserComments(untilVisible: firstChild)
        XCTAssertTrue(app.frame.intersects(parent.frame))
        XCTAssertTrue(app.frame.intersects(firstChild.frame))

        tapAbsolutePoint(x: parent.frame.minX + 8, y: parent.frame.minY + 8)

        waitForNonExistence(firstChild, timeout: 2)
        XCTAssertTrue(parent.waitForExistence(timeout: 2))

        parent.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()

        XCTAssertTrue(firstChild.waitForExistence(timeout: 2))
        XCTAssertTrue(app.frame.intersects(firstChild.frame))

        parent.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.75)).tap()

        waitForNonExistence(firstChild, timeout: 2)
        XCTAssertTrue(parent.waitForExistence(timeout: 2))

        parent.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        XCTAssertTrue(firstChild.waitForExistence(timeout: 2))

        tapAbsolutePoint(x: parent.frame.maxX - 8, y: parent.frame.minY + 8)

        waitForNonExistence(firstChild, timeout: 2)
        XCTAssertTrue(parent.waitForExistence(timeout: 2))
    }

    func testSystemBackSwipeFromCustomBrowserCollapsedComments() throws {
        launchApp(linkBrowserMode: .custom)

        let post = app.buttons["feed.post.\(screenshotPostID)"]
        XCTAssertTrue(post.waitForExistence(timeout: 8))
        tapPost(post)

        XCTAssertTrue(app.otherElements["browser.view"].waitForExistence(timeout: 5))
        edgeSwipeBack()

        XCTAssertTrue(app.collectionViews["feed.list"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.otherElements["browser.view"].exists)
    }

    func testSystemBackSwipeFromCustomBrowserExpandedComments() throws {
        launchApp(linkBrowserMode: .custom)

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
        launchApp(linkBrowserMode: .inApp)

        let post = app.buttons["feed.post.\(screenshotPostID)"]
        XCTAssertTrue(post.waitForExistence(timeout: 8))
        tapPost(post)

        XCTAssertTrue(commentsList.waitForExistence(timeout: 5))
        edgeSwipeBack()

        XCTAssertTrue(app.collectionViews["feed.list"].waitForExistence(timeout: 5))
        XCTAssertFalse(commentsList.exists)
    }

    func testOpenCommentsFromFeed() throws {
        launchApp(linkBrowserMode: .inApp)

        let post = app.buttons["feed.post.\(screenshotPostID)"]
        XCTAssertTrue(post.waitForExistence(timeout: 8))
        tapPost(post)

        XCTAssertTrue(commentsList.waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Swift 6.2 Released"].exists)
        XCTAssertTrue(app.staticTexts["manakov_dev"].exists)
        XCTAssertTrue(app.staticTexts["Tiny machines make sense when travel weight matters more than benchmark numbers, especially for light terminal and browser work."].exists)
    }

    func testCollapsePreservesRootCommentContext() throws {
        launchApp(linkBrowserMode: .inApp)

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
        launchApp()

        XCTAssertTrue(app.collectionViews["feed.list"].waitForExistence(timeout: 8))
        let searchButton = app.buttons["Search"]
        XCTAssertTrue(searchButton.waitForExistence(timeout: 5))
        XCTAssertTrue(searchButton.isHittable)
        searchButton.tap()

        let searchField = app.searchFields.firstMatch
        XCTAssertTrue(searchField.waitForExistence(timeout: 5))
        XCTAssertTrue(searchField.isHittable)
        searchField.tap()
        searchField.typeText("Swift")

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

    private func launchApp(linkBrowserMode: BrowserMode = .custom) {
        app = XCUIApplication(bundleIdentifier: "com.weiranzhang.Hackers")
        app.terminate()
        app.launchEnvironment["HACKERS_UI_TESTING"] = "1"
        app.launchEnvironment["HACKERS_UI_BROWSER_MODE"] = linkBrowserMode.rawValue
        app.launchEnvironment["HACKERS_UI_ROUTE"] = "feed"
        app.launch()
    }

    private var commentsList: XCUIElement {
        app.descendants(matching: .any)["comments.list"]
    }

    private func tapPost(_ post: XCUIElement) {
        post.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
    }

    private func tapAbsolutePoint(x: CGFloat, y: CGFloat) {
        app.coordinate(
            withNormalizedOffset: CGVector(
                dx: x / app.frame.width,
                dy: y / app.frame.height
            )
        ).tap()
    }

    private func scroll(_ container: XCUIElement, untilVisible element: XCUIElement, maxSwipes: Int = 6) {
        for _ in 0 ..< maxSwipes where !element.exists || !container.frame.intersects(element.frame) {
            container.swipeUp()
        }
    }

    private func scrollCustomBrowserComments(untilVisible element: XCUIElement, maxDrags: Int = 8) {
        let start = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.78))
        let end = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.28))
        for _ in 0 ..< maxDrags where !element.exists || !app.frame.intersects(element.frame) {
            start.press(forDuration: 0.05, thenDragTo: end)
        }
    }

    private func dragCustomBrowserCommentsUp(count: Int) {
        let start = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.78))
        let end = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.28))
        for _ in 0 ..< count {
            start.press(forDuration: 0.05, thenDragTo: end)
        }
    }

    private func waitForNonExistence(_ element: XCUIElement, timeout: TimeInterval) {
        let deadline = Date().addingTimeInterval(timeout)
        while element.exists && Date() < deadline {
            RunLoop.current.run(until: Date().addingTimeInterval(0.05))
        }
        XCTAssertFalse(element.exists)
    }

    private func waitForFrameMinY(of element: XCUIElement, greaterThan threshold: CGFloat, timeout: TimeInterval) {
        let deadline = Date().addingTimeInterval(timeout)
        while element.exists, element.frame.minY <= threshold, Date() < deadline {
            RunLoop.current.run(until: Date().addingTimeInterval(0.05))
        }
        XCTAssertTrue(element.exists)
        XCTAssertGreaterThan(element.frame.minY, threshold)
    }

    private func waitForFrameMaxY(of element: XCUIElement, lessThan threshold: CGFloat, timeout: TimeInterval) {
        let deadline = Date().addingTimeInterval(timeout)
        while element.exists, element.frame.maxY >= threshold, Date() < deadline {
            RunLoop.current.run(until: Date().addingTimeInterval(0.05))
        }
        XCTAssertTrue(element.exists)
        XCTAssertLessThan(element.frame.maxY, threshold)
    }

    private func edgeSwipeBack() {
        let start = app.coordinate(withNormalizedOffset: CGVector(dx: 0.01, dy: 0.5))
        let end = app.coordinate(withNormalizedOffset: CGVector(dx: 0.85, dy: 0.5))
        start.press(forDuration: 0.05, thenDragTo: end)
    }

}
