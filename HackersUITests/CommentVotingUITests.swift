import Domain
import Shared
import XCTest

@MainActor
final class CommentVotingUITests: HackersUITestCase {
    func testUpvotingCommentShowsUpvotedStateAfterVotingCompletes() throws {
        launchApp(configuration: UITestLaunchConfiguration(
            browserMode: .inAppBrowser,
            authenticated: true
        ))

        let post = assertHittable(app.buttons[AccessibilityIdentifier.Feed.post(screenshotPostID)], timeout: 8)
        tapPost(post)
        assertFullyContained(commentsList, in: app)
        // Wait for the fixture comments to load before touching rows; the target
        // comment is the first row, so no scrolling is needed.
        assertHasVisibleIntersection(app.staticTexts["manakov_dev"], in: commentsList, timeout: 8)

        let comment = assertHittable(
            app.buttons[AccessibilityIdentifier.Comments.comment(UITestFixtureReference.firstScreenshotCommentID)]
        )

        // The row's inline vote control is hidden inside a combined accessibility
        // element, so drive voting through the context menu, whose items are built
        // from the same rendered row state.
        openContextMenu(on: comment)
        hittableMenuButton(labeled: "Upvote").tap()

        // After the optimistic vote (and spinner) settles, the row must re-render
        // in the upvoted state, which the context menu exposes as an Unvote action.
        openContextMenu(on: comment)
        let unvote = hittableMenuButton(labeled: "Unvote", timeout: 5)
        assertHittable(unvote).tap() // dismiss the menu
    }

    /// Context menu actions share their label with the post header's vote button,
    /// which is covered (not hittable) while the menu is open; the menu item is
    /// the hittable match.
    private func hittableMenuButton(labeled label: String, timeout: TimeInterval = 3) -> XCUIElement {
        let matches = app.buttons.matching(NSPredicate(format: "label == %@", label))
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            let candidates = matches.allElementsBoundByIndex
            if let hittable = candidates.first(where: { $0.isHittable }) {
                return hittable
            }
            RunLoop.current.run(until: Date().addingTimeInterval(0.1))
        }
        print("MENU-BUTTONS: \(app.buttons.allElementsBoundByIndex.map(\.description))")
        XCTFail("Expected a hittable \(label) action while the comment context menu is open")
        return matches.firstMatch
    }

    private func openContextMenu(on element: XCUIElement) {
        element.press(forDuration: 1)
        XCTAssertTrue(
            app.buttons["Copy"].firstMatch.waitForExistence(timeout: 3),
            "Long-pressing a comment row should open its context menu"
        )
    }
}
