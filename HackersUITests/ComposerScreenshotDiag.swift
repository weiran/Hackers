import Shared
import XCTest

@MainActor
final class ComposerScreenshotDiag: HackersUITestCase {
    private func snap(_ name: String) {
        let png = XCUIScreen.main.screenshot().pngRepresentation
        try? png.write(to: URL(fileURLWithPath: "/tmp/composer_\(name).png"))
    }

    func testCaptureComposerStates() {
        launchApp(configuration: UITestLaunchConfiguration(
            route: .comments(postID: screenshotPostID),
            authenticated: true,
            commentingEnabled: true
        ))
        _ = assertHasVisibleIntersection(commentsList, in: app)
        sleep(1)
        snap("1_collapsed")

        let composer = app.buttons.matching(identifier: AccessibilityIdentifier.Comments.composerCollapsed).firstMatch
        XCTAssertTrue(composer.waitForExistence(timeout: 5))
        composer.tap()
        sleep(2)
        snap("2_expanded_keyboard")

        let editor = app.descendants(matching: .any)
            .matching(identifier: AccessibilityIdentifier.Comments.composerEditor)
            .firstMatch
        if editor.exists {
            editor.tap()
            editor.typeText("Typing a multi-line draft.\nSecond line for the screenshot.")
            sleep(1)
            snap("3_typed")
        } else {
            snap("3_no_editor_found")
        }
    }

    func testCaptureComposerStatesInBrowserSheet() {
        launchApp(configuration: UITestLaunchConfiguration(
            authenticated: true,
            commentingEnabled: true
        ))

        let post = assertHittable(app.buttons[AccessibilityIdentifier.Feed.post(longCommentsPostID)], timeout: 8)
        tapPost(post)
        assertFullyContained(browserView, in: app)

        _ = assertHasVisibleIntersection(commentsList, in: app)
        sleep(1)
        snap("4_sheet_collapsed_pill")

        let composer = app.buttons.matching(identifier: AccessibilityIdentifier.Comments.composerCollapsed).firstMatch
        XCTAssertTrue(composer.waitForExistence(timeout: 5))
        composer.tap()
        sleep(2)
        snap("5_sheet_expanded_keyboard")

        let editor = app.descendants(matching: .any)
            .matching(identifier: AccessibilityIdentifier.Comments.composerEditor)
            .firstMatch
        if editor.exists, editor.isHittable {
            editor.tap()
            editor.typeText("Draft in the browser sheet.")
            sleep(1)
            snap("6_sheet_typed")
        } else {
            snap("6_sheet_editor_unhittable")
        }
    }
}
