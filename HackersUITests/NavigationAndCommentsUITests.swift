import Domain
import Shared
import XCTest

@MainActor
final class NavigationAndCommentsUITests: HackersUITestCase {
    func testSystemBackSwipeFromCustomBrowserCollapsedComments() throws {
        launchApp(linkBrowserMode: .customBrowser)

        let post = assertHittable(app.buttons[AccessibilityIdentifier.Feed.post(screenshotPostID)], timeout: 8)
        tapPost(post)

        assertFullyContained(app.otherElements[AccessibilityIdentifier.Browser.view], in: app)
        collapseCommentsByTappingTitle()
        assertHasVisibleIntersection(collapsedCommentsHeader, in: app)
        edgeSwipeBack()

        assertFullyContained(app.collectionViews[AccessibilityIdentifier.Feed.list], in: app)
        assertAbsent(browserView)
    }

    func testSystemBackSwipeFromCustomBrowserExpandedComments() throws {
        launchApp(linkBrowserMode: .customBrowser)

        let post = assertHittable(app.buttons[AccessibilityIdentifier.Feed.post(longCommentsPostID)], timeout: 8)
        tapPost(post)

        assertFullyContained(browserView, in: app)
        assertHasVisibleIntersection(app.buttons[AccessibilityIdentifier.Comments.comment(UITestFixtureReference.firstLongCommentID)], in: app)

        edgeSwipeBack()

        assertFullyContained(app.collectionViews[AccessibilityIdentifier.Feed.list], in: app)
        assertAbsent(browserView)
    }

    func testSystemBackSwipeFromComments() throws {
        launchApp(linkBrowserMode: .inAppBrowser)

        let post = assertHittable(app.buttons[AccessibilityIdentifier.Feed.post(screenshotPostID)], timeout: 8)
        tapPost(post)

        assertFullyContained(commentsList, in: app)
        edgeSwipeBack()

        assertFullyContained(app.collectionViews[AccessibilityIdentifier.Feed.list], in: app)
        assertAbsent(commentsList)
    }

    func testOpenCommentsFromFeed() throws {
        launchApp(linkBrowserMode: .inAppBrowser)

        let post = assertHittable(app.buttons[AccessibilityIdentifier.Feed.post(screenshotPostID)], timeout: 8)
        tapPost(post)

        assertFullyContained(commentsList, in: app)
        assertHasVisibleIntersection(app.staticTexts["Swift 6.2 Released"], in: commentsList)
        assertHasVisibleIntersection(app.staticTexts["manakov_dev"], in: commentsList)
        assertHasVisibleIntersection(
            app.staticTexts["Swift 6.2 feels focused on making concurrency diagnostics more practical without giving up the safety model."],
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
        assertHasVisibleIntersection(app.webViews[AccessibilityIdentifier.Browser.fixtureArticle], in: browserView)
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
        assertHasVisibleIntersection(app.buttons[AccessibilityIdentifier.Comments.comment(UITestFixtureReference.firstLongCommentID)], in: app)
    }

    func testNextCommentButtonStartsAtFirstCommentThenAdvances() throws {
        launchApp(configuration: UITestLaunchConfiguration(
            browserMode: .customBrowser,
            route: .story(postID: longCommentsPostID, presentation: .expandedComments)
        ))

        let nextCommentButton = assertHittable(app.buttons[AccessibilityIdentifier.Comments.nextCommentButton], timeout: 8)
        let firstComment = assertHasVisibleIntersection(
            app.buttons[AccessibilityIdentifier.Comments.comment(UITestFixtureReference.firstLongCommentID)],
            in: app
        )
        let secondComment = assertHasVisibleIntersection(
            app.buttons[AccessibilityIdentifier.Comments.comment(UITestFixtureReference.secondLongRootCommentID)],
            in: app
        )

        let initialFirstMinY = firstComment.frame.minY
        nextCommentButton.tap()
        let firstTargetFrame = waitForStableFrame(of: firstComment, timeout: 5) {
            $0.minY < initialFirstMinY - 40
        }
        XCTAssertNotNil(firstTargetFrame, "The first press should align the first comment")
        assertFullyContained(firstComment, in: app)

        let initialSecondMinY = secondComment.frame.minY
        nextCommentButton.tap()
        let secondTargetFrame = waitForStableFrame(of: secondComment, timeout: 5) {
            $0.minY < initialSecondMinY - 40
        }
        XCTAssertNotNil(secondTargetFrame, "The next press should advance to the second comment")
    }

    func testCollapsingCommentKeepsRootContextAvailable() throws {
        launchApp(linkBrowserMode: .inAppBrowser)

        let post = assertHittable(app.buttons[AccessibilityIdentifier.Feed.post(longCommentsPostID)], timeout: 8)
        tapPost(post)

        let list = commentsList
        assertHasVisibleIntersection(list, in: app)

        var rootComment = app.buttons[AccessibilityIdentifier.Comments.comment(UITestFixtureReference.collapsibleRootCommentID)]
        let childComment = app.buttons[AccessibilityIdentifier.Comments.comment(UITestFixtureReference.collapsibleChildCommentID)]
        scroll(list, untilVisible: rootComment)
        rootComment = assertHasVisibleIntersection(rootComment, in: list)
        XCTAssertTrue(childComment.exists)

        rootComment.tap()
        waitForNonExistence(childComment, timeout: 2)
        rootComment = assertHasVisibleIntersection(rootComment, in: list)

        rootComment.press(forDuration: 1)
        assertHittable(app.buttons["Copy"].firstMatch)
        assertHasVisibleIntersection(app.buttons["Share"].firstMatch, in: app)
    }

    func testSwipingCommentRowCollapsesThread() throws {
        launchApp(linkBrowserMode: .inAppBrowser)

        let post = assertHittable(app.buttons[AccessibilityIdentifier.Feed.post(longCommentsPostID)], timeout: 8)
        tapPost(post)

        let list = commentsList
        assertHasVisibleIntersection(list, in: app)

        let rootComment = app.buttons[
            AccessibilityIdentifier.Comments.comment(UITestFixtureReference.collapsibleRootCommentID)
        ]
        let childComment = app.buttons[
            AccessibilityIdentifier.Comments.comment(UITestFixtureReference.collapsibleChildCommentID)
        ]
        scroll(list, untilVisible: rootComment)

        guard let swipeFrame = positionCommentForSwipe(rootComment, in: list) else {
            addVisibilityFailureDiagnostics(for: rootComment, in: list)
            XCTFail("""
            Could not place the comment in the unobscured swipe area.
            row: \(rootComment.frame), list: \(list.frame), navigation bar: \(app.navigationBars.firstMatch.frame)
            """)
            return
        }
        XCTAssertTrue(rootComment.isHittable, "The comment must be hittable before swiping. row: \(swipeFrame)")
        XCTAssertTrue(childComment.exists)

        // Reveal the trailing action with a deliberate partial swipe. Keeping
        // the drag short and slow avoids making the full-swipe action an alternate
        // outcome of this test.
        rootComment.coordinate(withNormalizedOffset: CGVector(dx: 0.95, dy: 0.5))
            .press(
                forDuration: 0.1,
                thenDragTo: rootComment.coordinate(withNormalizedOffset: CGVector(dx: 0.6, dy: 0.5)),
                withVelocity: .slow,
                thenHoldForDuration: 0.2
            )

        // The revealed action's label is duplicated by the system ("Collapse
        // Thread, Collapse Thread"), so query by identifier instead.
        let collapseButton = app.buttons[
            AccessibilityIdentifier.Comments.collapseThreadAction(UITestFixtureReference.collapsibleRootCommentID)
        ]
        XCTAssertTrue(collapseButton.waitForExistence(timeout: 3), "Swipe should reveal the collapse action")
        XCTAssertTrue(collapseButton.isHittable, "The revealed collapse action should be hittable")
        collapseButton.tap()

        waitForNonExistence(childComment, timeout: 2)
        assertHasVisibleIntersection(rootComment, in: list)
        // The list extends under the top bar on Dynamic Island devices, where
        // scrolling aligns the row flush with the visible content area rather
        // than the raw list frame (older runtimes pushed it under the bar).
        // The collapsed root must be the topmost reachable row either way:
        // only the one content-adjacent row may remain hittable above it,
        // tucked under the bar. A mis-scrolled or clamped collapse leaves
        // several fully visible rows stacked above the root instead.
        let rootFrame = waitForStableFrame(of: rootComment, timeout: 3) { frame in
            self.hittableCommentRowsAbove(rootMinY: frame.minY).count <= 1
        }
        if rootFrame == nil {
            dumpCommentRowDiagnostics(relativeTo: rootComment.frame.minY)
        }
        XCTAssertNotNil(
            rootFrame,
            "Collapsing a thread should align its root comment with the top of the comments list. " +
                "root: \(rootComment.frame), list: \(list.frame)"
        )
    }

    private func positionCommentForSwipe(_ comment: XCUIElement, in list: XCUIElement) -> CGRect? {
        let listFrame = list.frame
        let navigationBar = app.navigationBars.firstMatch
        let minimumTop = listFrame.minY + 140
        let unobscuredTop = navigationBar.exists ? navigationBar.frame.maxY + 24 : minimumTop
        let safeTop = max(minimumTop, unobscuredTop)
        let safeBottom = listFrame.maxY - 120
        guard safeBottom > safeTop else { return nil }

        let swipeViewport = CGRect(
            x: listFrame.minX,
            y: safeTop,
            width: listFrame.width,
            height: safeBottom - safeTop
        )
        let targetY = swipeViewport.midY

        for _ in 0 ..< 8 {
            guard comment.exists else { return nil }
            let frame = comment.frame
            guard !frame.isEmpty, !frame.isNull else { return nil }

            if swipeViewport.contains(frame), abs(frame.midY - targetY) <= 48, comment.isHittable {
                if let stableFrame = waitForStableFrame(of: comment, timeout: 1, condition: { candidate in
                    swipeViewport.contains(candidate) && abs(candidate.midY - targetY) <= 48 && comment.isHittable
                }) {
                    return stableFrame
                }
            }

            let offset = frame.midY - targetY
            guard abs(offset) > 48 else {
                waitForFrameToSettle(comment, timeout: 1)
                continue
            }

            let dragDistance = min(abs(offset), swipeViewport.height * 0.25)
            let direction: CGFloat = offset > 0 ? -1 : 1
            let startY = targetY - direction * dragDistance / 2
            let endY = targetY + direction * dragDistance / 2
            let start = list.coordinate(withNormalizedOffset: CGVector(
                dx: 0.5,
                dy: (startY - listFrame.minY) / listFrame.height
            ))
            let end = list.coordinate(withNormalizedOffset: CGVector(
                dx: 0.5,
                dy: (endY - listFrame.minY) / listFrame.height
            ))
            start.press(forDuration: 0.05, thenDragTo: end, withVelocity: .slow, thenHoldForDuration: 0.1)
            waitForFrameToSettle(comment, timeout: 1)
        }

        return nil
    }

    private func hittableCommentRowsAbove(rootMinY: CGFloat, tolerance: CGFloat = 8) -> [XCUIElement] {
        let rows = app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH %@", "comments.comment.")
        ).allElementsBoundByIndex
        return rows.filter { row in
            row.exists
                && row.isHittable
                && row.frame.minY < rootMinY - tolerance
        }
    }

    private func dumpCommentRowDiagnostics(relativeTo rootMinY: CGFloat) {
        let rows = app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH %@", "comments.comment.")
        ).allElementsBoundByIndex
        let lines = rows.map { row -> String in
            let frame = row.exists ? row.frame : .null
            let hittable = (row.exists ? row.isHittable : false)
            return "\(row.identifier) frame=\(frame) hittable=\(hittable) above=\(frame.minY < rootMinY - 8)"
        }
        let dump = XCTAttachment(string: """
        rootMinY=\(rootMinY) list=\(commentsList.frame)
        \(lines.joined(separator: "\n"))
        """)
        dump.name = "Collapsed root row diagnostics"
        dump.lifetime = .keepAlways
        add(dump)
    }
}
