import XCTest

@MainActor
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

    func testSmokeLaunchFeedAndSettings() throws {
        launchApp()

        let feed = app.collectionViews["feed.list"]
        assertFullyContained(feed, in: app, timeout: 8)
        assertHasVisibleIntersection(app.staticTexts["Swift 6.2 Released"], in: feed)
        assertHasVisibleIntersection(app.staticTexts["Cloudflare Turnstile requiring fingerprintable WebGL"], in: feed)
        assertHasVisibleIntersection(
            app.staticTexts["United Airlines 767 returns to Newark after Bluetooth name sparks alert"],
            in: feed
        )

        let settingsButton = app.buttons["settings.button"]
        assertHittable(settingsButton)
        settingsButton.tap()

        let settingsForm = app.collectionViews["settings.form"]
        assertFullyContained(settingsForm, in: app)
        assertHasVisibleIntersection(app.staticTexts["Settings"], in: app)
        assertHittable(app.switches["settings.showThumbnails"])
        assertHittable(app.switches["settings.compactFeed"])
        assertHasVisibleIntersection(
            app.staticTexts.containing(NSPredicate(format: "label BEGINSWITH %@", "Version")).firstMatch,
            in: settingsForm
        )
    }

    func testSmokeOpenCustomBrowserFromFeed() throws {
        launchApp(linkBrowserMode: .custom)

        let post = app.buttons["feed.post.\(screenshotPostID)"]
        assertHittable(post, timeout: 8)
        tapPost(post)

        let browser = browserView
        assertFullyContained(browser, in: app)
        assertHasVisibleIntersection(
            app.staticTexts["Fixture article loaded from the UI-test Hacker News Active snapshot."],
            in: browser
        )
        let titlePill = app.buttons["Swift 6.2 Released"]
        assertHasVisibleIntersection(titlePill, in: app)
        assertFullyContained(titlePill, in: app)
        XCTAssertLessThan(titlePill.frame.width, app.frame.width - 176)
    }

    func testCustomBrowserCommentsSheetCollapsedPreview() throws {
        launchApp(linkBrowserMode: .custom)

        let post = app.buttons["feed.post.\(longCommentsPostID)"]
        assertHittable(post, timeout: 8)
        tapPost(post)

        let browser = browserView
        assertFullyContained(browser, in: app)
        assertHasVisibleIntersection(
            app.staticTexts["Fixture article loaded from the UI-test Hacker News Active snapshot."],
            in: browser
        )

        collapseCommentsByTappingTitle()
        assertHasVisibleIntersection(app.staticTexts["366 comments"].firstMatch, in: collapsedCommentsHeader)
        assertHasVisibleIntersection(app.staticTexts["675"].firstMatch, in: collapsedCommentsHeader)
    }

    func testCustomBrowserExpandedCommentsChrome() throws {
        XCUIDevice.shared.orientation = .portrait
        launchApp(linkBrowserMode: .custom)

        let post = app.buttons["feed.post.\(longCommentsPostID)"]
        assertHittable(post, timeout: 8)
        tapPost(post)

        assertFullyContained(browserView, in: app)
        assertHasVisibleIntersection(
            expandedCommentsTitle,
            in: app
        )
        assertAbsent(app.buttons["browser.commentsSheet.back"])
        assertHittable(app.buttons["Share"])
        assertAbsent(app.buttons["Reload"])
        assertAbsent(app.buttons["Open in Safari"])
        let firstComment = app.buttons["comments.comment.48346154"]
        assertHasVisibleIntersection(firstComment, in: app)
        XCTAssertEqual(firstComment.frame.minX, 0, accuracy: 1)
        XCTAssertEqual(firstComment.frame.width, app.frame.width, accuracy: 1)
    }

    func testCustomBrowserTitlePillTapCollapsesExpandedComments() throws {
        launchApp(linkBrowserMode: .custom)

        let post = app.buttons["feed.post.\(longCommentsPostID)"]
        assertHittable(post, timeout: 8)
        tapPost(post)

        let firstComment = app.buttons["comments.comment.48346154"]
        assertHasVisibleIntersection(firstComment, in: app)
        dragCustomBrowserCommentsUp(count: 1)
        let scrollStart = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.65))
        let scrollEnd = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.25))
        scrollStart.press(forDuration: 0.05, thenDragTo: scrollEnd)

        let titlePill = expandedCommentsTitle
        assertHasVisibleIntersection(titlePill, in: app)
        let titlePillFrame = titlePill.frame
        assertFullyContained(titlePill, in: app)
        XCTAssertLessThan(titlePillFrame.maxY, 120)
        tapAbsolutePoint(x: titlePillFrame.maxX - 12, y: titlePillFrame.midY)

        assertHasVisibleIntersection(collapsedCommentsHeader, in: app)
        let sheetHandle = commentsSheetHandle
        waitForFrameMinY(of: sheetHandle, greaterThan: app.frame.midY, timeout: 5)
        let postTapScreenshot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        postTapScreenshot.lifetime = .keepAlways
        add(postTapScreenshot)
        assertHasVisibleIntersection(
            app.staticTexts["Fixture article loaded from the UI-test Hacker News Active snapshot."],
            in: app
        )
        assertHasVisibleIntersection(collapsedCommentsHeader, in: app)
    }

    func testCustomBrowserCollapsedHandleDragExpandsComments() throws {
        launchApp(linkBrowserMode: .custom)

        let post = app.buttons["feed.post.\(longCommentsPostID)"]
        assertHittable(post, timeout: 8)
        tapPost(post)

        collapseCommentsByTappingTitle()
        let sheetHandle = commentsSheetHandle
        assertHasVisibleIntersection(sheetHandle, in: app)
        XCTAssertGreaterThan(sheetHandle.frame.minY, app.frame.midY)

        let handle = app.coordinate(withNormalizedOffset: CGVector(
            dx: sheetHandle.frame.midX / app.frame.width,
            dy: sheetHandle.frame.midY / app.frame.height
        ))
        let expandedPosition = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.08))
        handle.press(forDuration: 0.1, thenDragTo: expandedPosition)

        assertFullyContained(app.buttons["comments.comment.48346154"], in: app)
        assertHasVisibleIntersection(expandedCommentsTitle, in: app)
        XCTAssertLessThan(expandedCommentsTitle.frame.maxY, 120)
    }

    func testCustomBrowserPreservesCommentScrollPositionAcrossCollapse() throws {
        launchApp(linkBrowserMode: .custom)

        let post = app.buttons["feed.post.\(longCommentsPostID)"]
        assertHittable(post, timeout: 8)
        tapPost(post)

        let lowerComment = app.buttons["comments.comment.48348985"]
        scrollCustomBrowserComments(untilVisible: lowerComment)
        assertHasVisibleIntersection(lowerComment, in: app)
        let frameBeforeCollapse = lowerComment.frame

        let titlePill = expandedCommentsTitle
        assertHasVisibleIntersection(titlePill, in: app)
        tapAbsolutePoint(x: titlePill.frame.maxX - 12, y: titlePill.frame.midY)

        assertHasVisibleIntersection(collapsedCommentsHeader, in: app)
        let sheetHandle = commentsSheetHandle
        waitForFrameMinY(of: sheetHandle, greaterThan: app.frame.midY, timeout: 5)
        tapAbsolutePoint(x: sheetHandle.frame.midX, y: sheetHandle.frame.maxY + 30)
        waitForFrameMaxY(of: sheetHandle, lessThan: 120, timeout: 5)

        assertHasVisibleIntersection(lowerComment, in: app)
        XCTAssertEqual(lowerComment.frame.minY, frameBeforeCollapse.minY, accuracy: 1)
        let reexpandedTitlePill = expandedCommentsTitle
        assertHasVisibleIntersection(reexpandedTitlePill, in: app)
        XCTAssertLessThan(reexpandedTitlePill.frame.maxY, 120)
        let screenshot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        screenshot.name = "Re-expanded comments preserve scroll position"
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }

    func testCustomBrowserCommentsReturnToTopAfterLongScroll() throws {
        launchApp(linkBrowserMode: .custom)

        let post = app.buttons["feed.post.\(longCommentsPostID)"]
        assertHittable(post, timeout: 8)
        tapPost(post)

        let firstComment = app.buttons["comments.comment.48346154"]
        assertHasVisibleIntersection(firstComment, in: app)

        let lowerComment = app.buttons["comments.comment.48348985"]
        scrollCustomBrowserComments(untilVisible: lowerComment)
        assertHasVisibleIntersection(lowerComment, in: app)

        app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.01)).tap()

        assertHasVisibleIntersection(firstComment, in: app)

        let titlePill = expandedCommentsTitle
        assertHasVisibleIntersection(titlePill, in: app)
        tapAbsolutePoint(x: titlePill.frame.maxX - 12, y: titlePill.frame.midY)
        assertHasVisibleIntersection(collapsedCommentsHeader, in: app)
    }

    func testCustomBrowserLargeCommentListReturnsToTopAfterLongScroll() throws {
        launchApp(linkBrowserMode: .custom)

        let post = app.buttons["feed.post.\(largeCommentsPostID)"]
        assertHittable(post, timeout: 8)
        tapPost(post)

        let firstComment = app.buttons["comments.comment.49000000"]
        assertHasVisibleIntersection(firstComment, in: app)

        dragCustomBrowserCommentsUp(count: 12)
        XCTAssertFalse(hasVisibleIntersection(firstComment, in: app))

        app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.01)).tap()

        assertHasVisibleIntersection(firstComment, in: app)

        assertHasVisibleIntersection(app.buttons["UI Test: Large Comments Stress Fixture"], in: app)
    }

    func testCustomBrowserLargeCommentBranchCollapsesAndExpands() throws {
        launchApp(linkBrowserMode: .custom)

        let post = app.buttons["feed.post.\(largeCommentsPostID)"]
        assertHittable(post, timeout: 8)
        tapPost(post)

        let parent = app.buttons["comments.comment.49000003"]
        let firstChild = app.buttons["comments.comment.49000004"]
        XCTAssertTrue(firstChild.waitForExistence(timeout: 5))
        scrollCustomBrowserComments(untilVisible: firstChild)
        assertHasVisibleIntersection(parent, in: app)
        assertHasVisibleIntersection(firstChild, in: app)

        tapAbsolutePoint(x: parent.frame.minX + 8, y: parent.frame.minY + 8)

        waitForNonExistence(firstChild, timeout: 2)
        XCTAssertTrue(parent.waitForExistence(timeout: 2))

        parent.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()

        XCTAssertTrue(firstChild.waitForExistence(timeout: 2))
        assertHasVisibleIntersection(firstChild, in: app)

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
        assertHittable(post, timeout: 8)
        tapPost(post)

        assertFullyContained(app.otherElements["browser.view"], in: app)
        collapseCommentsByTappingTitle()
        assertHasVisibleIntersection(collapsedCommentsHeader, in: app)
        edgeSwipeBack()

        assertFullyContained(app.collectionViews["feed.list"], in: app)
        assertAbsent(browserView)
    }

    func testSystemBackSwipeFromCustomBrowserExpandedComments() throws {
        launchApp(linkBrowserMode: .custom)

        let post = app.buttons["feed.post.\(longCommentsPostID)"]
        assertHittable(post, timeout: 8)
        tapPost(post)

        assertFullyContained(browserView, in: app)
        assertHasVisibleIntersection(app.buttons["comments.comment.48346154"], in: app)

        edgeSwipeBack()

        assertFullyContained(app.collectionViews["feed.list"], in: app)
        assertAbsent(browserView)
    }

    func testSystemBackSwipeFromComments() throws {
        launchApp(linkBrowserMode: .inApp)

        let post = app.buttons["feed.post.\(screenshotPostID)"]
        assertHittable(post, timeout: 8)
        tapPost(post)

        assertFullyContained(commentsList, in: app)
        edgeSwipeBack()

        assertFullyContained(app.collectionViews["feed.list"], in: app)
        assertAbsent(commentsList)
    }

    func testOpenCommentsFromFeed() throws {
        launchApp(linkBrowserMode: .inApp)

        let post = app.buttons["feed.post.\(screenshotPostID)"]
        assertHittable(post, timeout: 8)
        tapPost(post)

        assertFullyContained(commentsList, in: app)
        assertHasVisibleIntersection(app.staticTexts["Swift 6.2 Released"], in: commentsList)
        assertHasVisibleIntersection(app.staticTexts["manakov_dev"], in: commentsList)
        assertHasVisibleIntersection(
            app.staticTexts["Tiny machines make sense when travel weight matters more than benchmark numbers, especially for light terminal and browser work."],
            in: commentsList
        )
    }

    func testCollapsingCommentKeepsRootContextAvailable() throws {
        launchApp(linkBrowserMode: .inApp)

        let post = app.buttons["feed.post.\(longCommentsPostID)"]
        assertHittable(post, timeout: 8)
        tapPost(post)

        let list = commentsList
        assertFullyContained(list, in: app)

        let rootComment = app.buttons["comments.comment.48348985"]
        let childComment = app.buttons["comments.comment.48349298"]
        scroll(list, untilVisible: rootComment)
        assertHasVisibleIntersection(rootComment, in: list)
        XCTAssertTrue(childComment.exists)

        rootComment.tap()
        waitForNonExistence(childComment, timeout: 2)
        assertHasVisibleIntersection(rootComment, in: list)

        rootComment.press(forDuration: 1)
        assertHittable(app.buttons["Copy"].firstMatch)
        assertHasVisibleIntersection(app.buttons["Share"].firstMatch, in: app)
    }

    func testSearchUsesMockedAlgoliaResults() throws {
        launchApp()

        assertFullyContained(app.collectionViews["feed.list"], in: app, timeout: 8)
        let searchButton = app.buttons["Search"]
        assertHittable(searchButton)
        searchButton.tap()

        let searchField = app.searchFields.firstMatch
        assertHittable(searchField)
        searchField.tap()
        searchField.typeText("Swift")

        assertHasVisibleIntersection(app.staticTexts["Swift 6.2 Released"], in: app, timeout: 8)
        assertAbsent(app.staticTexts["United Airlines 767 returns to Newark after Bluetooth name sparks alert"])
    }

    func testCategoryMenuUsesMockedFeeds() throws {
        launchApp()

        assertFullyContained(app.collectionViews["feed.list"], in: app, timeout: 8)
        let categoryMenu = app.navigationBars.buttons["Top"]
        assertHittable(categoryMenu)
        categoryMenu.tap()
        let askButton = app.buttons["Ask"]
        assertHittable(askButton)
        askButton.tap()

        assertHasVisibleIntersection(
            app.staticTexts["Ask HN: What are you using for iOS UI testing in 2026?"],
            in: app
        )
    }

    func testLoginFailureAndSuccessUseMockedAuthentication() throws {
        launchApp()

        assertFullyContained(app.collectionViews["feed.list"], in: app, timeout: 8)
        let settingsButton = app.buttons["settings.button"]
        assertHittable(settingsButton)
        settingsButton.tap()
        assertFullyContained(app.collectionViews["settings.form"], in: app)
        let loginButton = app.buttons["Login"]
        assertHittable(loginButton)
        loginButton.tap()

        let username = app.textFields["login.username"]
        let password = app.secureTextFields["login.password"]
        assertHittable(username)
        username.tap()
        username.typeText("ui-user")
        password.tap()
        password.typeText("wrong")
        app.buttons["login.signIn"].tap()
        assertFullyContained(app.alerts["Login Failed"], in: app)
        app.alerts["Login Failed"].buttons["OK"].tap()

        password.tap()
        password.typeText("password")
        app.buttons["login.signIn"].tap()

        assertHasVisibleIntersection(app.staticTexts["Welcome back, ui-user"].firstMatch, in: app)
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
        app.descendants(matching: .any).matching(identifier: "comments.list").firstMatch
    }

    private var collapsedCommentsHeader: XCUIElement {
        app.descendants(matching: .any)
            .matching(identifier: "browser.commentsSheet.collapsedHeader")
            .firstMatch
    }

    private var commentsSheetHandle: XCUIElement {
        app.descendants(matching: .any)
            .matching(identifier: "browser.commentsSheet.handle")
            .firstMatch
    }

    private var expandedCommentsTitle: XCUIElement {
        app.buttons.matching(identifier: "browser.commentsSheet.expandedTitle").firstMatch
    }

    private var browserView: XCUIElement {
        app.otherElements.matching(identifier: "browser.view").firstMatch
    }

    private func tapPost(_ post: XCUIElement) {
        post.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
    }

    private func collapseCommentsByTappingTitle() {
        assertHasVisibleIntersection(expandedCommentsTitle, in: app)
        tapAbsolutePoint(x: expandedCommentsTitle.frame.maxX - 12, y: expandedCommentsTitle.frame.midY)
        assertHasVisibleIntersection(collapsedCommentsHeader, in: app)
    }

    private func tapAbsolutePoint(x: CGFloat, y: CGFloat) {
        app.coordinate(
            withNormalizedOffset: CGVector(
                dx: x / app.frame.width,
                dy: y / app.frame.height
            )
        ).tap()
    }

    private func assertHittable(
        _ element: XCUIElement,
        timeout: TimeInterval = 5,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        if !element.isHittable {
            let expectation = XCTNSPredicateExpectation(
                predicate: NSPredicate(format: "hittable == true"),
                object: element
            )
            let result = XCTWaiter.wait(for: [expectation], timeout: timeout)
            XCTAssertEqual(result, .completed, "Expected element to become hittable: \(element)", file: file, line: line)
            guard result == .completed else { return }
        }
        assertHasVisibleIntersection(element, in: app, timeout: 0, file: file, line: line)
    }

    private func assertFullyContained(
        _ element: XCUIElement,
        in container: XCUIElement,
        timeout: TimeInterval = 5,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        guard element.exists || element.waitForExistence(timeout: timeout) else {
            XCTFail("Expected element to exist: \(element)", file: file, line: line)
            return
        }
        guard container.exists || container.waitForExistence(timeout: timeout) else {
            XCTFail("Expected container to exist: \(container)", file: file, line: line)
            return
        }

        let elementFrame = element.frame
        XCTAssertFalse(elementFrame.isEmpty, "Expected element to have a rendered frame", file: file, line: line)
        XCTAssertTrue(
            container.frame.contains(elementFrame),
            "Expected \(elementFrame) to be fully contained in \(container.frame)",
            file: file,
            line: line
        )
    }

    private func assertHasVisibleIntersection(
        _ element: XCUIElement,
        in container: XCUIElement,
        timeout: TimeInterval = 5,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        guard element.exists || element.waitForExistence(timeout: timeout) else {
            XCTFail("Expected element to exist: \(element)", file: file, line: line)
            return
        }
        guard container.exists || container.waitForExistence(timeout: timeout) else {
            XCTFail("Expected container to exist: \(container)", file: file, line: line)
            return
        }

        XCTAssertTrue(
            hasVisibleIntersection(element, in: container),
            "Expected \(element.frame) to visibly intersect \(container.frame)",
            file: file,
            line: line
        )
    }

    private func assertAbsent(
        _ element: XCUIElement,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertFalse(element.exists, "Expected element to be absent: \(element)", file: file, line: line)
    }

    private func hasVisibleIntersection(_ element: XCUIElement, in container: XCUIElement) -> Bool {
        guard element.exists, container.exists else { return false }
        let intersection = element.frame.intersection(container.frame)
        return !intersection.isNull && intersection.width > 1 && intersection.height > 1
    }

    private func scroll(_ container: XCUIElement, untilVisible element: XCUIElement, maxSwipes: Int = 6) {
        for _ in 0 ..< maxSwipes where !hasVisibleIntersection(element, in: container) {
            container.swipeUp()
        }
    }

    private func scrollCustomBrowserComments(untilVisible element: XCUIElement, maxDrags: Int = 8) {
        let start = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.78))
        let end = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.28))
        for _ in 0 ..< maxDrags where !hasVisibleIntersection(element, in: app) {
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
