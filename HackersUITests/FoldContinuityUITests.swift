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

        setHorizontalSizeClass(regular: true)
        assertHasVisibleIntersection(element(reference.identifier), in: app)
        let unfolded = try XCTUnwrap(waitForStableFrame(of: element(reference.identifier), timeout: 3) { _ in true })
        attachScreenshot("Comments unfolded")
        XCTAssertLessThanOrEqual(
            abs(unfolded.minY - reference.minY),
            maxShift,
            "Comment \(reference.identifier) moved from \(reference.minY) to \(unfolded.minY) when unfolding"
        )

        setHorizontalSizeClass(regular: false)
        assertHasVisibleIntersection(commentsList, in: app)
        let refolded = try XCTUnwrap(waitForStableFrame(of: element(reference.identifier), timeout: 3) { _ in true })
        attachScreenshot("Comments folded again")
        XCTAssertLessThanOrEqual(
            abs(refolded.minY - reference.minY),
            maxShift,
            "Comment \(reference.identifier) moved from \(reference.minY) to \(refolded.minY) when folding"
        )
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
