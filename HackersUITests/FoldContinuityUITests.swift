import CoreFoundation
import Domain
import Shared
import XCTest

/// Folding or unfolding an iPhone Duo changes the window's horizontal size class. Apple's
/// guidance is that standard containers keep the reader's place through that change, so these
/// tests check the feed and comments stay where they were. XCUITest can't fold the simulator,
/// so the app applies the same horizontal size-class trait change on request
/// (`UITestSizeClassNotification`).
@MainActor
final class FoldContinuityUITests: HackersUITestCase {
    /// Largest acceptable movement of the reference row. The system keeps content in place
    /// relative to the bars, so a change in bar height (up to ~60pt between the vertical rail
    /// and a top bar) can still move it; anything more means the scroll position was lost.
    private let maxShift: CGFloat = 80

    func testFeedKeepsScrollPositionAcrossSizeClassChanges() throws {
        launchApp(linkBrowserMode: .inAppBrowser)
        setHorizontalSizeClass(regular: false)
        let feedList = app.descendants(matching: .any)
            .matching(identifier: AccessibilityIdentifier.Feed.list).firstMatch
        assertHittable(app.buttons[AccessibilityIdentifier.Feed.post(screenshotPostID)], timeout: 8)

        dragUp(feedList, count: 3)
        let reference = try XCTUnwrap(topVisibleElement(prefix: "feed.post.", in: feedList))
        attachScreenshot("Feed before unfold")

        setHorizontalSizeClass(regular: true)
        let regularRow = element(reference.identifier)
        assertHasVisibleIntersection(regularRow, in: app)
        attachScreenshot("Feed unfolded")

        setHorizontalSizeClass(regular: false)
        let restored = try XCTUnwrap(waitForStableFrame(of: element(reference.identifier), timeout: 3) { _ in true })
        attachScreenshot("Feed folded again")
        XCTAssertLessThanOrEqual(
            abs(restored.minY - reference.minY),
            maxShift,
            "Feed row \(reference.identifier) moved from \(reference.minY) to \(restored.minY)"
        )
    }

    func testCommentsKeepScrollPositionAndScreenAcrossSizeClassChanges() throws {
        launchApp(configuration: UITestLaunchConfiguration(
            browserMode: .inAppBrowser,
            route: .comments(postID: longCommentsPostID)
        ))
        setHorizontalSizeClass(regular: false)
        assertHasVisibleIntersection(commentsList, in: app, timeout: 8)

        dragUp(commentsList, count: 3)
        let reference = try XCTUnwrap(topVisibleElement(prefix: "comments.comment.", in: commentsList))
        attachScreenshot("Comments before unfold")

        for cycle in 1...3 {
            setHorizontalSizeClass(regular: true)
            let unfolded = try XCTUnwrap(
                waitForStableFrame(of: element(reference.identifier), timeout: 3) { _ in true }
            )
            XCTAssertLessThanOrEqual(
                abs(unfolded.minY - reference.minY),
                maxShift,
                "Comment \(reference.identifier) drifted on unfold cycle \(cycle)"
            )

            setHorizontalSizeClass(regular: false)
            assertHasVisibleIntersection(commentsList, in: app)
            let refolded = try XCTUnwrap(
                waitForStableFrame(of: element(reference.identifier), timeout: 3) { _ in true }
            )
            XCTAssertLessThanOrEqual(
                abs(refolded.minY - reference.minY),
                maxShift,
                "Comment \(reference.identifier) accumulated drift by fold cycle \(cycle)"
            )
        }
        attachScreenshot("Comments after three fold cycles")
    }

    /// The persistent split detail must update the comments host when the bar changes axis;
    /// otherwise it can retain a hidden navigation bar and blank toolbar item slots.
    func testBrowserControlsSurviveSizeClassChanges() throws {
        launchApp(configuration: UITestLaunchConfiguration(
            browserMode: .customBrowser,
            route: .story(postID: screenshotPostID, presentation: .expandedComments)
        ))
        setHorizontalSizeClass(regular: false)
        assertHasVisibleIntersection(commentsList, in: app, timeout: 8)
        assertHittable(app.buttons["Show Article"])

        for _ in 0..<3 {
            setHorizontalSizeClass(regular: true)
            setHorizontalSizeClass(regular: false)
        }
        attachScreenshot("Browser controls after three fold cycles")
        assertHittable(app.buttons["Show Article"])
        assertHittable(
            app.buttons.matching(NSPredicate(format: "identifier == 'BackButton' OR label == 'Back'")).firstMatch
        )
    }

    func testBrowserFormStateSurvivesSizeClassChanges() throws {
        launchApp(configuration: UITestLaunchConfiguration(
            browserMode: .customBrowser,
            route: .story(postID: screenshotPostID, presentation: .collapsedBrowser)
        ))
        setHorizontalSizeClass(regular: false)
        assertFixtureArticleLoaded()

        let note = assertHittable(app.webViews.textFields["Reader note"])
        note.tap()
        note.typeText("Keep this browser state")
        XCTAssertTrue((note.value as? String)?.hasPrefix("Keep this") == true)
        app.webViews.staticTexts["Swift 6.2 Released"].tap()

        setHorizontalSizeClass(regular: true)
        setHorizontalSizeClass(regular: false)

        let restored = assertHittable(app.webViews.textFields["Reader note"])
        XCTAssertTrue((restored.value as? String)?.hasPrefix("Keep this") == true)
    }

    func testCommentDraftSurvivesSizeClassChanges() throws {
        launchApp(configuration: UITestLaunchConfiguration(
            browserMode: .inAppBrowser,
            route: .comments(postID: screenshotPostID),
            authenticated: true,
            commentingEnabled: true
        ))
        setHorizontalSizeClass(regular: false)
        assertHasVisibleIntersection(commentsList, in: app, timeout: 8)

        let collapsed = app.buttons
            .matching(identifier: AccessibilityIdentifier.Comments.composerCollapsed).firstMatch
        assertHittable(collapsed).tap()
        let editor = app.descendants(matching: .any)
            .matching(identifier: AccessibilityIdentifier.Comments.composerEditor).firstMatch
        assertHittable(editor).typeText("Draft survives a display transfer")

        let comment = app.buttons
            .matching(NSPredicate(format: "identifier BEGINSWITH %@", "comments.comment."))
            .allElementsBoundByIndex.first { $0.isHittable && hasVisibleIntersection($0, in: commentsList) }
        try XCTUnwrap(comment).tap()
        XCTAssertTrue(assertHittable(collapsed).label.contains("Draft survives"))

        for _ in 0..<2 {
            setHorizontalSizeClass(regular: true)
            setHorizontalSizeClass(regular: false)
        }

        XCTAssertTrue(assertHittable(collapsed).label.contains("Draft survives"))
        collapsed.tap()
        XCTAssertTrue((assertHittable(editor).value as? String)?.contains("Draft survives a display transfer") == true)
    }

    // MARK: - Helpers

    private func setHorizontalSizeClass(regular: Bool) {
        let name = regular ? UITestSizeClassNotification.regular : UITestSizeClassNotification.compact
        CFNotificationCenterPostNotification(
            CFNotificationCenterGetDarwinNotifyCenter(),
            CFNotificationName(name as CFString),
            nil,
            nil,
            true
        )
        // Regular width shows the split view's second column; compact width collapses it so
        // the visible column spans the window.
        let feed = app.descendants(matching: .any)
            .matching(identifier: AccessibilityIdentifier.Feed.list).firstMatch
        let layoutChanged = NSPredicate { _, _ in
            let windowWidth = self.app.frame.width
            if regular {
                // The split view shows its sidebar and detail columns together (side by side
                // on a wide display, or the sidebar over the detail on the narrow outer one).
                return feed.exists && feed.frame.width < windowWidth
                    && (self.app.staticTexts["Select a Post"].exists || self.commentsList.exists)
            }
            return [self.commentsList, feed].contains { $0.exists && $0.frame.width > windowWidth * 0.75 }
        }
        let expectation = XCTNSPredicateExpectation(predicate: layoutChanged, object: nil)
        let result = XCTWaiter().wait(for: [expectation], timeout: 5)
        if result != .completed {
            attachScreenshot("Layout switch to \(regular ? "regular" : "compact") failed")
        }
        XCTAssertEqual(
            result,
            .completed,
            "Layout didn't switch to \(regular ? "regular" : "compact") width"
        )
        // Let the size transition and any scroll adjustment finish.
        RunLoop.current.run(until: Date().addingTimeInterval(1.5))
    }

    private func element(_ identifier: String) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: identifier).firstMatch
    }

    private func dragUp(_ container: XCUIElement, count: Int) {
        let start = container.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.75))
        let end = container.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.35))
        for _ in 0 ..< count {
            start.press(forDuration: 0.01, thenDragTo: end, withVelocity: .default, thenHoldForDuration: 0.1)
        }
        RunLoop.current.run(until: Date().addingTimeInterval(1))
    }

    /// The highest row whose top edge sits inside the container, below its top 15%
    /// so it isn't hidden under the bars.
    private func topVisibleElement(
        prefix: String,
        in container: XCUIElement
    ) -> (identifier: String, minY: CGFloat)? {
        let containerFrame = container.frame
        let threshold = containerFrame.minY + containerFrame.height * 0.15
        let rows = app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier BEGINSWITH %@", prefix))
            .allElementsBoundByIndex
        return rows
            .map { ($0.identifier, $0.frame) }
            .filter { !$0.1.isEmpty && $0.1.minY >= threshold && $0.1.maxY <= containerFrame.maxY }
            .min { $0.1.minY < $1.1.minY }
            .map { ($0.0, $0.1.minY) }
    }

    /// iPhone Duo has two displays and only one is lit, so capture each screen.
    private func attachScreenshot(_ name: String) {
        for (index, screen) in XCUIScreen.screens.enumerated() {
            let attachment = XCTAttachment(screenshot: screen.screenshot())
            attachment.name = XCUIScreen.screens.count > 1 ? "\(name) (screen \(index))" : name
            attachment.lifetime = .keepAlways
            add(attachment)
        }
    }
}
