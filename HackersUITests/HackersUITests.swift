import Domain
import Shared
import XCTest

@MainActor
final class HackersUITests: XCTestCase {
    private let screenshotPostID = 48_350_598
    private let longCommentsPostID = 48_345_840
    private let largeCommentsPostID = 48_399_999
    private let searchOnlyPostID = 48_400_101
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
        launchApp(linkBrowserMode: .customBrowser)

        let post = app.buttons["feed.post.\(screenshotPostID)"]
        assertHittable(post, timeout: 8)
        tapPost(post)

        let browser = browserView
        assertFullyContained(browser, in: app)
        assertHasVisibleIntersection(
            app.staticTexts["Fixture article loaded from the UI-test Hacker News Active snapshot."],
            in: browser
        )
        let titlePill = expandedCommentsTitle
        assertHasVisibleIntersection(titlePill, in: app)
        assertFullyContained(titlePill, in: app)
        XCTAssertLessThan(titlePill.frame.width, app.frame.width - 176)
    }

    func testCustomBrowserCommentsSheetCollapsedPreview() throws {
        launchApp(linkBrowserMode: .customBrowser)

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
        launchApp(linkBrowserMode: .customBrowser)

        let post = app.buttons["feed.post.\(longCommentsPostID)"]
        assertHittable(post, timeout: 8)
        tapPost(post)

        assertFullyContained(browserView, in: app)
        assertHasVisibleIntersection(
            expandedCommentsTitle,
            in: app
        )
        assertHittable(app.buttons["Share"])
        let firstComment = app.buttons["comments.comment.48346154"]
        assertHasVisibleIntersection(firstComment, in: app)
        XCTAssertEqual(firstComment.frame.minX, 0, accuracy: 1)
        XCTAssertEqual(firstComment.frame.width, app.frame.width, accuracy: 1)

        collapseCommentsByTappingTitle()
        assertHittable(app.buttons["Reload"])
        assertHittable(app.buttons["Open in Safari"])
        let sheetHandle = commentsSheetHandle
        waitForFrameMinY(of: sheetHandle, greaterThan: app.frame.midY, timeout: 5)
        tapAbsolutePoint(x: sheetHandle.frame.midX, y: sheetHandle.frame.maxY + 30)
        waitForFrameMaxY(of: sheetHandle, lessThan: 120, timeout: 5)
        assertHasVisibleIntersection(expandedCommentsTitle, in: app)
        assertNotVisible(app.buttons["Reload"], in: app)
        assertNotVisible(app.buttons["Open in Safari"], in: app)
    }

    func testCustomBrowserTitlePillTapCollapsesExpandedComments() throws {
        launchApp(linkBrowserMode: .customBrowser)

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
        postTapScreenshot.name = "Collapsed comments sheet"
        postTapScreenshot.lifetime = .deleteOnSuccess
        add(postTapScreenshot)
        assertHasVisibleIntersection(
            app.staticTexts["Fixture article loaded from the UI-test Hacker News Active snapshot."],
            in: app
        )
        assertHasVisibleIntersection(collapsedCommentsHeader, in: app)
    }

    func testCustomBrowserTitlePillDragCollapsesExpandedComments() throws {
        launchApp(linkBrowserMode: .customBrowser)

        let post = app.buttons["feed.post.\(longCommentsPostID)"]
        assertHittable(post, timeout: 8)
        tapPost(post)

        let titlePill = expandedCommentsTitle
        assertHasVisibleIntersection(titlePill, in: app)
        let titleFrame = titlePill.frame
        let dragStart = app.coordinate(withNormalizedOffset: CGVector(
            dx: titleFrame.midX / app.frame.width,
            dy: titleFrame.midY / app.frame.height
        ))
        let collapsedPosition = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.72))
        dragStart.press(forDuration: 0.1, thenDragTo: collapsedPosition)

        assertHasVisibleIntersection(collapsedCommentsHeader, in: app)
        waitForFrameMinY(of: commentsSheetHandle, greaterThan: app.frame.midY, timeout: 5)
    }

    func testCustomBrowserTopChromeDragCollapsesExpandedComments() throws {
        launchApp(linkBrowserMode: .customBrowser)

        let post = app.buttons["feed.post.\(longCommentsPostID)"]
        assertHittable(post, timeout: 8)
        tapPost(post)
        assertHasVisibleIntersection(expandedCommentsTitle, in: app)

        let chromeStart = app.coordinate(withNormalizedOffset: CGVector(dx: 0.25, dy: 0.08))
        let collapsedPosition = app.coordinate(withNormalizedOffset: CGVector(dx: 0.25, dy: 0.72))
        chromeStart.press(forDuration: 0.1, thenDragTo: collapsedPosition)

        assertHasVisibleIntersection(collapsedCommentsHeader, in: app)
        waitForFrameMinY(of: commentsSheetHandle, greaterThan: app.frame.midY, timeout: 5)
    }

    func testCustomBrowserSheetContentDragCollapsesExpandedComments() throws {
        launchApp(linkBrowserMode: .customBrowser)

        let post = app.buttons["feed.post.\(longCommentsPostID)"]
        assertHittable(post, timeout: 8)
        tapPost(post)

        let firstComment = app.buttons["comments.comment.48346154"]
        assertHasVisibleIntersection(firstComment, in: app)
        let start = app.coordinate(withNormalizedOffset: CGVector(
            dx: firstComment.frame.midX / app.frame.width,
            dy: firstComment.frame.midY / app.frame.height
        ))
        let collapsedPosition = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.82))
        start.press(forDuration: 0.1, thenDragTo: collapsedPosition)

        assertHasVisibleIntersection(collapsedCommentsHeader, in: app)
        waitForFrameMinY(of: commentsSheetHandle, greaterThan: app.frame.midY, timeout: 5)
    }

    func testCustomBrowserCollapsedHandleDragExpandsComments() throws {
        launchApp(linkBrowserMode: .customBrowser)

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
        launchApp(linkBrowserMode: .customBrowser)

        let post = app.buttons["feed.post.\(longCommentsPostID)"]
        assertHittable(post, timeout: 8)
        tapPost(post)

        let lowerComment = app.buttons["comments.comment.48348985"]
        scrollCustomBrowserComments(untilVisible: lowerComment)
        assertHasVisibleIntersection(lowerComment, in: app)
        let frameBeforeCollapse = lowerComment.frame

        for _ in 0 ..< 3 {
            let titlePill = expandedCommentsTitle
            assertHasVisibleIntersection(titlePill, in: app)
            tapAbsolutePoint(x: titlePill.frame.maxX - 12, y: titlePill.frame.midY)

            assertHasVisibleIntersection(collapsedCommentsHeader, in: app)
            let sheetHandle = commentsSheetHandle
            waitForFrameMinY(of: sheetHandle, greaterThan: app.frame.midY, timeout: 5)
            tapAbsolutePoint(x: sheetHandle.frame.midX, y: sheetHandle.frame.maxY + 30)
            waitForFrameMaxY(of: sheetHandle, lessThan: 120, timeout: 5)
            assertHasVisibleIntersection(expandedCommentsTitle, in: app)

            assertHasVisibleIntersection(lowerComment, in: app)
            XCTAssertEqual(lowerComment.frame.minY, frameBeforeCollapse.minY, accuracy: 4)
            assertHasVisibleIntersection(expandedCommentsTitle, in: app)
            XCTAssertLessThan(expandedCommentsTitle.frame.maxY, 120)
        }
        let screenshot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        screenshot.name = "Repeatedly re-expanded comments preserve pill and scroll position"
        screenshot.lifetime = .deleteOnSuccess
        add(screenshot)
    }

    func testCustomBrowserCommentsReturnToTopAfterLongScroll() throws {
        launchApp(linkBrowserMode: .customBrowser)

        let post = app.buttons["feed.post.\(longCommentsPostID)"]
        assertHittable(post, timeout: 8)
        tapPost(post)

        let firstComment = app.buttons["comments.comment.48346154"]
        assertHasVisibleIntersection(firstComment, in: app)

        let lowerComment = app.buttons["comments.comment.48348985"]
        scrollCustomBrowserComments(untilVisible: lowerComment)
        assertHasVisibleIntersection(lowerComment, in: app)

        app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.01)).tap()

        assertHasVisibleIntersection(firstComment, in: app, timeout: 12)

        let titlePill = expandedCommentsTitle
        assertHasVisibleIntersection(titlePill, in: app)
        tapAbsolutePoint(x: titlePill.frame.maxX - 12, y: titlePill.frame.midY)
        assertHasVisibleIntersection(collapsedCommentsHeader, in: app)
    }

    func testCustomBrowserLargeCommentListReturnsToTopAfterLongScroll() throws {
        launchApp(configuration: UITestLaunchConfiguration(
            browserMode: .customBrowser,
            fixtureProfile: .stress
        ))

        let post = app.buttons["feed.post.\(largeCommentsPostID)"]
        assertHittable(post, timeout: 8)
        tapPost(post)

        let firstComment = app.buttons["comments.comment.49000000"]
        assertHasVisibleIntersection(firstComment, in: app)

        dragCustomBrowserCommentsUp(count: 4)
        XCTAssertFalse(hasVisibleIntersection(firstComment, in: app))

        app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.01)).tap()

        assertHasVisibleIntersection(firstComment, in: app)

        assertHasVisibleIntersection(app.buttons["UI Test: Large Comments Stress Fixture"], in: app)
    }

    func testCustomBrowserLargeCommentBranchCollapsesAndExpands() throws {
        launchApp(configuration: UITestLaunchConfiguration(
            browserMode: .customBrowser,
            fixtureProfile: .stress
        ))

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
        assertHasVisibleIntersection(parent, in: app, timeout: 2)

        parent.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()

        XCTAssertTrue(firstChild.waitForExistence(timeout: 2))
        assertHasVisibleIntersection(firstChild, in: app)

        parent.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.75)).tap()

        waitForNonExistence(firstChild, timeout: 2)
        assertHasVisibleIntersection(parent, in: app, timeout: 2)

        parent.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        XCTAssertTrue(firstChild.waitForExistence(timeout: 2))
        assertHasVisibleIntersection(parent, in: app, timeout: 2)

        tapAbsolutePoint(x: parent.frame.maxX - 8, y: parent.frame.minY + 8)

        waitForNonExistence(firstChild, timeout: 2)
        assertHasVisibleIntersection(parent, in: app, timeout: 2)
    }

    func testSystemBackSwipeFromCustomBrowserCollapsedComments() throws {
        launchApp(linkBrowserMode: .customBrowser)

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
        launchApp(linkBrowserMode: .customBrowser)

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
        launchApp(linkBrowserMode: .inAppBrowser)

        let post = app.buttons["feed.post.\(screenshotPostID)"]
        assertHittable(post, timeout: 8)
        tapPost(post)

        assertFullyContained(commentsList, in: app)
        edgeSwipeBack()

        assertFullyContained(app.collectionViews["feed.list"], in: app)
        assertAbsent(commentsList)
    }

    func testOpenCommentsFromFeed() throws {
        launchApp(linkBrowserMode: .inAppBrowser)

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

    func testLaunchesDirectCommentsRoute() throws {
        launchApp(configuration: UITestLaunchConfiguration(
            browserMode: .inAppBrowser,
            route: .comments(postID: screenshotPostID)
        ))

        assertFullyContained(commentsList, in: app, timeout: 8)
        assertHasVisibleIntersection(app.staticTexts["Swift 6.2 Released"], in: commentsList)
        assertHasVisibleIntersection(app.staticTexts["manakov_dev"], in: commentsList)
    }

    func testLaunchesDirectCollapsedStoryRoute() throws {
        launchApp(configuration: UITestLaunchConfiguration(
            browserMode: .customBrowser,
            route: .story(postID: screenshotPostID, presentation: .collapsedBrowser)
        ))

        assertHasVisibleIntersection(browserView, in: app, timeout: 8)
        assertHasVisibleIntersection(app.webViews["browser.fixtureArticle"], in: browserView)
        assertHasVisibleIntersection(app.staticTexts["Swift 6.2 Released"], in: browserView)
        assertHasVisibleIntersection(collapsedCommentsHeader, in: app)
    }

    func testLaunchesDirectExpandedStoryRoute() throws {
        launchApp(configuration: UITestLaunchConfiguration(
            browserMode: .customBrowser,
            route: .story(postID: longCommentsPostID, presentation: .expandedComments)
        ))

        assertFullyContained(browserView, in: app, timeout: 8)
        assertHasVisibleIntersection(expandedCommentsTitle, in: app)
        assertHasVisibleIntersection(app.buttons["comments.comment.48346154"], in: app)
    }

    func testNextCommentButtonStartsAtFirstCommentThenAdvances() throws {
        launchApp(configuration: UITestLaunchConfiguration(
            browserMode: .customBrowser,
            route: .story(postID: longCommentsPostID, presentation: .expandedComments)
        ))

        let nextCommentButton = app.buttons["comments.nextCommentButton"]
        let firstComment = app.buttons["comments.comment.48346154"]
        let secondComment = app.buttons["comments.comment.48354612"]
        assertHittable(nextCommentButton, timeout: 8)
        assertHasVisibleIntersection(firstComment, in: app)
        assertHasVisibleIntersection(secondComment, in: app)

        let initialFirstMinY = firstComment.frame.minY
        tapAbsolutePoint(x: nextCommentButton.frame.midX, y: nextCommentButton.frame.midY)
        let firstTargetFrame = waitForStableFrame(of: firstComment, timeout: 5) {
            $0.minY < initialFirstMinY - 40
        }
        XCTAssertNotNil(firstTargetFrame, "The first press should align the first comment")
        assertFullyContained(firstComment, in: app)

        let initialSecondMinY = secondComment.frame.minY
        tapAbsolutePoint(x: nextCommentButton.frame.midX, y: nextCommentButton.frame.midY)
        let secondTargetFrame = waitForStableFrame(of: secondComment, timeout: 5) {
            $0.minY < initialSecondMinY - 40
        }
        XCTAssertNotNil(secondTargetFrame, "The next press should advance to the second comment")
    }

    func testCollapsingCommentKeepsRootContextAvailable() throws {
        launchApp(linkBrowserMode: .inAppBrowser)

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
        searchField.typeText("Migration Guide")

        let searchResults = app.collectionViews["search.results"]
        assertFullyContained(searchResults, in: app, timeout: 8)
        assertHasVisibleIntersection(app.buttons["feed.post.\(searchOnlyPostID)"], in: searchResults)
        assertHasVisibleIntersection(app.staticTexts["Swift 6.2 Migration Guide"], in: searchResults)
        assertAbsent(app.staticTexts["Searching..."])
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

    private func launchApp(linkBrowserMode: LinkBrowserMode = .customBrowser) {
        launchApp(configuration: UITestLaunchConfiguration(browserMode: linkBrowserMode))
    }

    private func launchApp(configuration: UITestLaunchConfiguration) {
        app = XCUIApplication(bundleIdentifier: "com.weiranzhang.Hackers")
        app.terminate()
        for (key, value) in configuration.environment {
            app.launchEnvironment[key] = value
        }
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
        guard let visiblePost = waitForStableRenderedCandidate(
            matching: post,
            in: app,
            timeout: 2,
            requiresHittable: true
        ) else {
            XCTFail("Expected a visible post candidate before tapping: \(post)")
            return
        }
        let frame = visiblePost.frame
        tapAbsolutePoint(x: frame.midX, y: frame.midY)
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
        guard waitForStableRenderedCandidate(
            matching: element,
            in: app,
            timeout: timeout,
            requiresHittable: true
        ) != nil else {
            XCTFail("Expected element to become visibly hittable: \(element)", file: file, line: line)
            return
        }
    }

    private func assertFullyContained(
        _ element: XCUIElement,
        in container: XCUIElement,
        timeout: TimeInterval = 5,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        guard waitForStableRenderedCandidate(
            matching: element,
            in: container,
            timeout: timeout,
            requiresFullContainment: true
        ) != nil else {
            XCTFail(
                "Expected element to become stably contained in \(container): \(element)",
                file: file,
                line: line
            )
            return
        }
    }

    private func assertHasVisibleIntersection(
        _ element: XCUIElement,
        in container: XCUIElement,
        timeout: TimeInterval = 5,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        guard waitForStableRenderedCandidate(
            matching: element,
            in: container,
            timeout: timeout
        ) != nil else {
            XCTFail(
                "Expected element to become meaningfully visible in \(container): \(element)",
                file: file,
                line: line
            )
            return
        }
    }

    private func assertAbsent(
        _ element: XCUIElement,
        timeout: TimeInterval = 3,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        waitForNonExistence(element, timeout: timeout, file: file, line: line)
    }

    private func assertNotVisible(
        _ element: XCUIElement,
        in container: XCUIElement,
        timeout: TimeInterval = 3,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let deadline = Date().addingTimeInterval(timeout)
        var stableSamples = 0
        repeat {
            if !hasVisibleIntersection(element, in: container) {
                stableSamples += 1
                if stableSamples >= 3 { return }
            } else {
                stableSamples = 0
            }
            guard Date() < deadline else { break }
            RunLoop.current.run(until: Date().addingTimeInterval(0.05))
        } while true
        XCTFail("Expected element not to be meaningfully visible: \(element)", file: file, line: line)
    }

    private func hasVisibleIntersection(_ element: XCUIElement, in container: XCUIElement) -> Bool {
        guard element.exists, container.exists else { return false }
        return isMeaningfullyVisible(element.frame, in: container.frame)
    }

    private func scroll(_ container: XCUIElement, untilVisible element: XCUIElement, maxSwipes: Int = 6) {
        for _ in 0 ..< maxSwipes where !hasVisibleIntersection(element, in: container) {
            container.swipeUp()
            waitForFrameToSettle(element, timeout: 1)
        }
    }

    private func scrollCustomBrowserComments(untilVisible element: XCUIElement, maxDrags: Int = 8) {
        let start = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.78))
        let end = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.28))
        for _ in 0 ..< maxDrags where !hasVisibleIntersection(element, in: app) {
            start.press(forDuration: 0.05, thenDragTo: end)
            waitForFrameToSettle(element, timeout: 1)
        }
    }

    private func dragCustomBrowserCommentsUp(count: Int) {
        let start = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.78))
        let end = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.28))
        for _ in 0 ..< count {
            start.press(forDuration: 0.05, thenDragTo: end)
        }
        waitForFrameToSettle(commentsList, timeout: 2)
    }

    private func waitForNonExistence(
        _ element: XCUIElement,
        timeout: TimeInterval,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let deadline = Date().addingTimeInterval(timeout)
        while element.exists && Date() < deadline {
            RunLoop.current.run(until: Date().addingTimeInterval(0.05))
        }
        XCTAssertFalse(element.exists, "Expected element to disappear: \(element)", file: file, line: line)
    }

    private func waitForFrameMinY(of element: XCUIElement, greaterThan threshold: CGFloat, timeout: TimeInterval) {
        let frame = waitForStableFrame(of: element, timeout: timeout) { $0.minY > threshold }
        XCTAssertNotNil(frame, "Expected a stable frame below \(threshold): \(element)")
    }

    private func waitForFrameMaxY(of element: XCUIElement, lessThan threshold: CGFloat, timeout: TimeInterval) {
        let frame = waitForStableFrame(of: element, timeout: timeout) { $0.maxY < threshold }
        XCTAssertNotNil(frame, "Expected a stable frame above \(threshold): \(element)")
    }

    private func waitForFrameToSettle(_ element: XCUIElement, timeout: TimeInterval) {
        _ = waitForStableFrame(of: element, timeout: timeout) { _ in true }
    }

    private func waitForStableRenderedCandidate(
        matching element: XCUIElement,
        in container: XCUIElement,
        timeout: TimeInterval,
        requiresHittable: Bool = false,
        requiresFullContainment: Bool = false
    ) -> XCUIElement? {
        let deadline = Date().addingTimeInterval(timeout)
        var previousFrame: CGRect?
        var stableSampleCount = 0

        repeat {
            let candidates: [XCUIElement]
            if element.exists, !element.identifier.isEmpty {
                let matches = app.descendants(matching: .any)
                    .matching(identifier: element.identifier)
                    .allElementsBoundByIndex
                candidates = matches.isEmpty ? [element] : matches
            } else {
                candidates = [element]
            }

            if container.exists,
               let candidate = candidates.first(where: { candidate in
                   guard candidate.exists else { return false }
                   if requiresHittable, !candidate.isHittable { return false }
                   let frame = candidate.frame
                   guard !frame.isEmpty, !frame.isNull else { return false }
                   let containerFrame = container.frame
                   if requiresFullContainment {
                       return containerFrame.insetBy(dx: -1, dy: -1).contains(frame)
                   }
                   return isMeaningfullyVisible(frame, in: containerFrame)
               }) {
                let frame = candidate.frame
                if let previousFrame, framesAreStable(previousFrame, frame) {
                    stableSampleCount += 1
                } else {
                    stableSampleCount = 1
                }
                previousFrame = frame
                if stableSampleCount >= 3 {
                    return candidate
                }
            } else {
                previousFrame = nil
                stableSampleCount = 0
            }

            guard Date() < deadline else { break }
            RunLoop.current.run(until: Date().addingTimeInterval(0.05))
        } while true

        return nil
    }

    private func waitForStableFrame(
        of element: XCUIElement,
        timeout: TimeInterval,
        condition: (CGRect) -> Bool
    ) -> CGRect? {
        let deadline = Date().addingTimeInterval(timeout)
        var previousFrame: CGRect?
        var stableSampleCount = 0

        repeat {
            if element.exists {
                let frame = element.frame
                if !frame.isEmpty, !frame.isNull, condition(frame) {
                    if let previousFrame, framesAreStable(previousFrame, frame) {
                        stableSampleCount += 1
                    } else {
                        stableSampleCount = 1
                    }
                    previousFrame = frame
                    if stableSampleCount >= 3 {
                        return frame
                    }
                } else {
                    previousFrame = nil
                    stableSampleCount = 0
                }
            } else {
                previousFrame = nil
                stableSampleCount = 0
            }

            guard Date() < deadline else { break }
            RunLoop.current.run(until: Date().addingTimeInterval(0.05))
        } while true

        return nil
    }

    private func isMeaningfullyVisible(_ frame: CGRect, in containerFrame: CGRect) -> Bool {
        guard !frame.isEmpty, !frame.isNull, !containerFrame.isEmpty, !containerFrame.isNull else {
            return false
        }
        let intersection = frame.intersection(containerFrame)
        guard !intersection.isNull, !intersection.isEmpty else { return false }
        let visibleFraction = (intersection.width * intersection.height) / (frame.width * frame.height)
        return intersection.width >= min(frame.width, 20)
            && intersection.height >= min(frame.height, 20)
            && visibleFraction >= 0.2
    }

    private func framesAreStable(_ lhs: CGRect, _ rhs: CGRect) -> Bool {
        abs(lhs.minX - rhs.minX) <= 1
            && abs(lhs.minY - rhs.minY) <= 1
            && abs(lhs.width - rhs.width) <= 1
            && abs(lhs.height - rhs.height) <= 1
    }

    private func edgeSwipeBack() {
        let start = app.coordinate(withNormalizedOffset: CGVector(dx: 0.01, dy: 0.5))
        let end = app.coordinate(withNormalizedOffset: CGVector(dx: 0.85, dy: 0.5))
        start.press(forDuration: 0.05, thenDragTo: end)
    }

}
