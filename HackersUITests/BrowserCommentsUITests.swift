import Domain
import Shared
import XCTest

@MainActor
final class BrowserCommentsUITests: HackersUITestCase {
    func testCustomBrowserCommentsSheetCollapsedPreview() throws {
        launchApp(linkBrowserMode: .customBrowser)

        let post = assertHittable(app.buttons[AccessibilityIdentifier.Feed.post(longCommentsPostID)], timeout: 8)
        tapPost(post)

        let browser = assertFullyContained(browserView, in: app)
        assertFixtureArticleLoaded()

        collapseCommentsByTappingTitle()
        assertHasVisibleIntersection(
            app.staticTexts["Fixture article loaded from the UI-test Hacker News Active snapshot."],
            in: browser
        )
        assertHasVisibleIntersection(app.staticTexts["366 comments"].firstMatch, in: collapsedCommentsHeader)
        assertHasVisibleIntersection(app.staticTexts["675"].firstMatch, in: collapsedCommentsHeader)
    }

    func testCustomBrowserExpandedCommentsChrome() throws {
        XCUIDevice.shared.orientation = .portrait
        launchApp(linkBrowserMode: .customBrowser)

        let post = assertHittable(app.buttons[AccessibilityIdentifier.Feed.post(longCommentsPostID)], timeout: 8)
        tapPost(post)

        assertFullyContained(browserView, in: app)
        assertHasVisibleIntersection(
            expandedCommentsTitle,
            in: app
        )
        assertHittable(app.buttons["Share"])
        let firstComment = assertHasVisibleIntersection(
            app.buttons[AccessibilityIdentifier.Comments.comment(UITestFixtureReference.firstLongCommentID)],
            in: app
        )
        XCTAssertEqual(firstComment.frame.minX, 0, accuracy: 1)
        XCTAssertEqual(firstComment.frame.width, app.frame.width, accuracy: 1)

        collapseCommentsByTappingTitle()
        let reloadButton = assertHittable(app.buttons["Reload"])
        assertHittable(app.buttons["Open in Safari"])
        reloadButton.tap()
        assertFixtureArticleLoaded()
        assertHasVisibleIntersection(
            app.staticTexts["Fixture article loaded from the UI-test Hacker News Active snapshot."],
            in: browserView
        )
        let sheetHandle = assertHasVisibleIntersection(commentsSheetHandle, in: app)
        waitForFrameMinY(of: sheetHandle, greaterThan: app.frame.midY, timeout: 5)
        tapAbsolutePoint(x: sheetHandle.frame.midX, y: sheetHandle.frame.maxY + 30)
        waitForFrameMaxY(of: sheetHandle, lessThan: 120, timeout: 5)
        assertHasVisibleIntersection(expandedCommentsTitle, in: app)
        assertNotVisible(app.buttons["Reload"], in: app)
        assertNotVisible(app.buttons["Open in Safari"], in: app)
    }

    func testCustomBrowserTitlePillTapCollapsesExpandedComments() throws {
        launchApp(linkBrowserMode: .customBrowser)

        let post = assertHittable(app.buttons[AccessibilityIdentifier.Feed.post(longCommentsPostID)], timeout: 8)
        tapPost(post)

        _ = assertHasVisibleIntersection(
            app.buttons[AccessibilityIdentifier.Comments.comment(UITestFixtureReference.firstLongCommentID)],
            in: app
        )
        dragCustomBrowserCommentsUp(count: 1)
        let scrollStart = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.65))
        let scrollEnd = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.25))
        scrollStart.press(forDuration: 0.05, thenDragTo: scrollEnd)

        let titlePill = assertHasVisibleIntersection(expandedCommentsTitle, in: app)
        let titlePillFrame = titlePill.frame
        assertFullyContained(titlePill, in: app)
        XCTAssertLessThan(titlePillFrame.maxY, 120)
        tapAbsolutePoint(x: titlePillFrame.maxX - 12, y: titlePillFrame.midY)

        assertHasVisibleIntersection(collapsedCommentsHeader, in: app)
        let sheetHandle = assertHasVisibleIntersection(commentsSheetHandle, in: app)
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

        let post = assertHittable(app.buttons[AccessibilityIdentifier.Feed.post(longCommentsPostID)], timeout: 8)
        tapPost(post)

        let titlePill = assertHasVisibleIntersection(expandedCommentsTitle, in: app)
        let titleFrame = titlePill.frame
        let dragStart = app.coordinate(withNormalizedOffset: CGVector(
            dx: titleFrame.midX / app.frame.width,
            dy: titleFrame.midY / app.frame.height
        ))
        let collapsedPosition = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.72))
        dragStart.press(forDuration: 0.1, thenDragTo: collapsedPosition)

        assertHasVisibleIntersection(collapsedCommentsHeader, in: app)
        let collapsedHandle = assertHasVisibleIntersection(commentsSheetHandle, in: app)
        waitForFrameMinY(of: collapsedHandle, greaterThan: app.frame.midY, timeout: 5)
    }

    func testCustomBrowserTopChromeDragCollapsesExpandedComments() throws {
        launchApp(linkBrowserMode: .customBrowser)

        let post = assertHittable(app.buttons[AccessibilityIdentifier.Feed.post(longCommentsPostID)], timeout: 8)
        tapPost(post)
        assertHasVisibleIntersection(expandedCommentsTitle, in: app)

        let chromeStart = app.coordinate(withNormalizedOffset: CGVector(dx: 0.25, dy: 0.08))
        let collapsedPosition = app.coordinate(withNormalizedOffset: CGVector(dx: 0.25, dy: 0.72))
        chromeStart.press(forDuration: 0.1, thenDragTo: collapsedPosition)

        assertHasVisibleIntersection(collapsedCommentsHeader, in: app)
        let collapsedHandle = assertHasVisibleIntersection(commentsSheetHandle, in: app)
        waitForFrameMinY(of: collapsedHandle, greaterThan: app.frame.midY, timeout: 5)
    }

    func testCustomBrowserSheetContentDragCollapsesExpandedComments() throws {
        launchApp(linkBrowserMode: .customBrowser)

        let post = assertHittable(app.buttons[AccessibilityIdentifier.Feed.post(longCommentsPostID)], timeout: 8)
        tapPost(post)

        let firstComment = assertHasVisibleIntersection(
            app.buttons[AccessibilityIdentifier.Comments.comment(UITestFixtureReference.firstLongCommentID)],
            in: app
        )
        let start = app.coordinate(withNormalizedOffset: CGVector(
            dx: firstComment.frame.midX / app.frame.width,
            dy: firstComment.frame.midY / app.frame.height
        ))
        let collapsedPosition = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.82))
        start.press(forDuration: 0.1, thenDragTo: collapsedPosition)

        assertHasVisibleIntersection(collapsedCommentsHeader, in: app)
        let collapsedHandle = assertHasVisibleIntersection(commentsSheetHandle, in: app)
        waitForFrameMinY(of: collapsedHandle, greaterThan: app.frame.midY, timeout: 5)
    }

    func testCustomBrowserCollapsedHandleDragExpandsComments() throws {
        launchApp(linkBrowserMode: .customBrowser)

        let post = assertHittable(app.buttons[AccessibilityIdentifier.Feed.post(longCommentsPostID)], timeout: 8)
        tapPost(post)

        collapseCommentsByTappingTitle()
        let sheetHandle = assertHasVisibleIntersection(commentsSheetHandle, in: app)
        XCTAssertGreaterThan(sheetHandle.frame.minY, app.frame.midY)

        let handle = app.coordinate(withNormalizedOffset: CGVector(
            dx: sheetHandle.frame.midX / app.frame.width,
            dy: sheetHandle.frame.midY / app.frame.height
        ))
        let expandedPosition = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.08))
        handle.press(forDuration: 0.1, thenDragTo: expandedPosition)

        assertFullyContained(app.buttons[AccessibilityIdentifier.Comments.comment(UITestFixtureReference.firstLongCommentID)], in: app)
        let expandedTitle = assertHasVisibleIntersection(expandedCommentsTitle, in: app)
        XCTAssertLessThan(expandedTitle.frame.maxY, 120)
    }

    func testCustomBrowserPreservesCommentScrollPositionAcrossCollapse() throws {
        launchApp(linkBrowserMode: .customBrowser)

        let post = assertHittable(app.buttons[AccessibilityIdentifier.Feed.post(longCommentsPostID)], timeout: 8)
        tapPost(post)

        let lowerComment = app.buttons[AccessibilityIdentifier.Comments.comment(UITestFixtureReference.collapsibleRootCommentID)]
        scrollCustomBrowserComments(untilVisible: lowerComment)
        let visibleLowerComment = assertHasVisibleIntersection(lowerComment, in: app)
        let frameBeforeCollapse = visibleLowerComment.frame

        for _ in 0 ..< 3 {
            let titlePill = assertHasVisibleIntersection(expandedCommentsTitle, in: app)
            tapAbsolutePoint(x: titlePill.frame.maxX - 12, y: titlePill.frame.midY)

            assertHasVisibleIntersection(collapsedCommentsHeader, in: app)
            let sheetHandle = assertHasVisibleIntersection(commentsSheetHandle, in: app)
            waitForFrameMinY(of: sheetHandle, greaterThan: app.frame.midY, timeout: 5)
            tapAbsolutePoint(x: sheetHandle.frame.midX, y: sheetHandle.frame.maxY + 30)
            waitForFrameMaxY(of: sheetHandle, lessThan: 120, timeout: 5)
            assertHasVisibleIntersection(expandedCommentsTitle, in: app)

            let restoredComment = assertHasVisibleIntersection(lowerComment, in: app)
            XCTAssertEqual(restoredComment.frame.minY, frameBeforeCollapse.minY, accuracy: 4)
            let restoredTitle = assertHasVisibleIntersection(expandedCommentsTitle, in: app)
            XCTAssertLessThan(restoredTitle.frame.maxY, 120)
        }
        let screenshot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        screenshot.name = "Repeatedly re-expanded comments preserve pill and scroll position"
        screenshot.lifetime = .deleteOnSuccess
        add(screenshot)
    }

    func testCustomBrowserCommentsReturnToTopAfterLongScroll() throws {
        launchApp(linkBrowserMode: .customBrowser)

        let post = assertHittable(app.buttons[AccessibilityIdentifier.Feed.post(longCommentsPostID)], timeout: 8)
        tapPost(post)

        let firstComment = app.buttons[AccessibilityIdentifier.Comments.comment(UITestFixtureReference.firstLongCommentID)]
        assertHasVisibleIntersection(firstComment, in: app)

        let lowerComment = app.buttons[AccessibilityIdentifier.Comments.comment(UITestFixtureReference.collapsibleRootCommentID)]
        scrollCustomBrowserComments(untilVisible: lowerComment)
        assertHasVisibleIntersection(lowerComment, in: app)

        app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.01)).tap()

        assertHasVisibleIntersection(firstComment, in: app, timeout: 12)

        let titlePill = assertHasVisibleIntersection(expandedCommentsTitle, in: app)
        tapAbsolutePoint(x: titlePill.frame.maxX - 12, y: titlePill.frame.midY)
        assertHasVisibleIntersection(collapsedCommentsHeader, in: app)
    }

    func testCustomBrowserLargeCommentListReturnsToTopAfterLongScroll() throws {
        launchApp(configuration: UITestLaunchConfiguration(
            browserMode: .customBrowser,
            fixtureProfile: .stress
        ))

        let post = assertHittable(app.buttons[AccessibilityIdentifier.Feed.post(largeCommentsPostID)], timeout: 8)
        tapPost(post)

        let firstComment = app.buttons[AccessibilityIdentifier.Comments.comment(UITestFixtureReference.firstLargeCommentID)]
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

        let post = assertHittable(app.buttons[AccessibilityIdentifier.Feed.post(largeCommentsPostID)], timeout: 8)
        tapPost(post)

        var parent = app.buttons[AccessibilityIdentifier.Comments.comment(UITestFixtureReference.largeCollapsibleRootCommentID)]
        let firstChild = app.buttons[AccessibilityIdentifier.Comments.comment(UITestFixtureReference.largeCollapsibleChildCommentID)]
        XCTAssertTrue(firstChild.waitForExistence(timeout: 5))
        scrollCustomBrowserComments(untilVisible: firstChild)
        parent = assertHasVisibleIntersection(parent, in: app)
        assertHasVisibleIntersection(firstChild, in: app)

        tapAbsolutePoint(x: parent.frame.minX + 8, y: parent.frame.minY + 8)

        waitForNonExistence(firstChild, timeout: 2)
        assertHasVisibleIntersection(parent, in: app, timeout: 2)

        parent = assertHasVisibleIntersection(parent, in: app, timeout: 2)
        parent.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()

        XCTAssertTrue(firstChild.waitForExistence(timeout: 2))
        assertHasVisibleIntersection(firstChild, in: app)

        parent = assertHasVisibleIntersection(parent, in: app, timeout: 2)
        parent.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.75)).tap()

        waitForNonExistence(firstChild, timeout: 2)
        assertHasVisibleIntersection(parent, in: app, timeout: 2)

        parent = assertHasVisibleIntersection(parent, in: app, timeout: 2)
        parent.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        XCTAssertTrue(firstChild.waitForExistence(timeout: 2))
        assertHasVisibleIntersection(parent, in: app, timeout: 2)

        parent = assertHasVisibleIntersection(parent, in: app, timeout: 2)
        tapAbsolutePoint(x: parent.frame.maxX - 8, y: parent.frame.minY + 8)

        waitForNonExistence(firstChild, timeout: 2)
        assertHasVisibleIntersection(parent, in: app, timeout: 2)
    }

    func testCustomBrowserExpandedCommentPreservesScrollPosition() throws {
        launchApp(configuration: UITestLaunchConfiguration(
            browserMode: .customBrowser,
            route: .story(postID: largeCommentsPostID, presentation: .expandedComments),
            fixtureProfile: .stress
        ))

        var parent = app.buttons[
            AccessibilityIdentifier.Comments.comment(UITestFixtureReference.largeCollapsibleRootCommentID)
        ]
        let firstChild = app.buttons[
            AccessibilityIdentifier.Comments.comment(UITestFixtureReference.largeCollapsibleChildCommentID)
        ]
        let scrollDownStart = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.78))
        let scrollDownEnd = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.28))
        for _ in 0 ..< 8 {
            if parent.exists, parent.frame.minY < 650 { break }
            scrollDownStart.press(forDuration: 0.05, thenDragTo: scrollDownEnd)
        }
        let scrollBackStart = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.45))
        let scrollBackEnd = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.65))
        for _ in 0 ..< 4 where parent.exists && parent.frame.minY < 400 {
            scrollBackStart.press(forDuration: 0.05, thenDragTo: scrollBackEnd)
        }
        XCTAssertTrue(parent.exists)
        XCTAssertGreaterThanOrEqual(parent.frame.minY, 400)
        XCTAssertLessThan(parent.frame.minY, 650)

        let perturbStart = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.65))
        let perturbEnd = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.45))
        perturbStart.press(forDuration: 0.05, thenDragTo: perturbEnd)
        scrollBackStart.press(forDuration: 0.05, thenDragTo: scrollBackEnd)

        guard let frameBeforeCollapse = waitForStableFrame(of: parent, timeout: 5, condition: { _ in true }) else {
            return XCTFail("Expected the parent comment frame to settle after returning to it")
        }
        tapAbsolutePoint(x: parent.frame.minX + 8, y: parent.frame.minY + 8)

        waitForNonExistence(firstChild, timeout: 2)
        guard let collapsedFrame = waitForStableFrame(of: parent, timeout: 5, condition: {
            $0.height < frameBeforeCollapse.height - 40
        }) else {
            return XCTFail("Expected the parent comment to collapse")
        }
        parent = assertHasVisibleIntersection(parent, in: app)
        XCTAssertEqual(collapsedFrame.minY, frameBeforeCollapse.minY, accuracy: 4)

        parent.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()

        let expansionDeadline = Date().addingTimeInterval(0.6)
        var expansionMinYs: [CGFloat] = []
        while Date() < expansionDeadline {
            if parent.exists {
                expansionMinYs.append(parent.frame.minY)
            }
            RunLoop.current.run(until: Date().addingTimeInterval(0.01))
        }

        guard let expandedFrame = waitForStableFrame(of: parent, timeout: 5, condition: {
            $0.height > collapsedFrame.height + 40
        }) else {
            return XCTFail("Expected the parent comment to expand without leaving the viewport")
        }
        XCTAssertEqual(expandedFrame.minY, collapsedFrame.minY, accuracy: 4)
        let maximumExpansionDisplacement = expansionMinYs
            .map { abs($0 - collapsedFrame.minY) }
            .max() ?? 0
        XCTAssertLessThanOrEqual(
            maximumExpansionDisplacement,
            4,
            "Expansion moved the comment viewport: \(expansionMinYs)"
        )
        let screenshot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        screenshot.name = "Expanded comment preserves scroll position"
        screenshot.lifetime = .deleteOnSuccess
        add(screenshot)
    }
}
