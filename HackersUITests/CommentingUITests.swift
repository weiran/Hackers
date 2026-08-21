import Shared
import XCTest

@MainActor
final class CommentingUITests: HackersUITestCase {
    private var composerCollapsed: XCUIElement {
        app.buttons.matching(identifier: AccessibilityIdentifier.Comments.composerCollapsed).firstMatch
    }

    private var composerEditor: XCUIElement {
        // A vertical-axis TextField surfaces as a text view in the
        // accessibility hierarchy, so match by identifier across types.
        app.descendants(matching: .any)
            .matching(identifier: AccessibilityIdentifier.Comments.composerEditor)
            .firstMatch
    }

    private var composerError: XCUIElement {
        app.staticTexts.matching(identifier: AccessibilityIdentifier.Comments.composerError).firstMatch
    }

    private var nextCommentButton: XCUIElement {
        app.buttons.matching(identifier: AccessibilityIdentifier.Comments.nextCommentButton).firstMatch
    }

    private func replyButton(commentID: Int) -> XCUIElement {
        app.buttons.matching(identifier: AccessibilityIdentifier.Comments.reply(commentID)).firstMatch
    }

    private func submittedCommentRow() -> XCUIElement {
        app.descendants(matching: .any)
            .matching(identifier: AccessibilityIdentifier.Comments.comment(UITestFixtureReference.submittedCommentID))
            .firstMatch
    }

    private func launchComments(
        authenticated: Bool,
        commenting: Bool,
        submission: UITestLaunchConfiguration.CommentSubmissionFixture = .success
    ) {
        launchApp(configuration: UITestLaunchConfiguration(
            route: .comments(postID: screenshotPostID),
            authenticated: authenticated,
            commentingEnabled: commenting,
            commentSubmission: submission
        ))
    }

    func testCommentingHiddenWhenFeatureDisabledAndAuthenticated() {
        launchComments(authenticated: true, commenting: false)
        assertHasVisibleIntersection(commentsList, in: app)

        assertAbsent(composerCollapsed)
        assertAbsent(replyButton(commentID: UITestFixtureReference.firstScreenshotCommentID))
        XCTAssertTrue(nextCommentButton.waitForExistence(timeout: 5), "Next-comment control stays available")
    }

    func testCommentingHiddenWhenEnabledAndLoggedOut() {
        launchComments(authenticated: false, commenting: true)
        assertHasVisibleIntersection(commentsList, in: app)

        assertAbsent(composerCollapsed)
        assertAbsent(replyButton(commentID: UITestFixtureReference.firstScreenshotCommentID))
    }

    func testComposerAndReplyVisibleWhenEnabledAndAuthenticated() {
        launchComments(authenticated: true, commenting: true)
        assertHasVisibleIntersection(commentsList, in: app)

        let composer = assertHittable(composerCollapsed)
        XCTAssertTrue(composer.isHittable, "The collapsed composer should be tappable")

        let reply = replyButton(commentID: UITestFixtureReference.firstScreenshotCommentID)
        scroll(commentsList, untilVisible: reply)
        XCTAssertTrue(reply.waitForExistence(timeout: 5), "Real comments should offer an inline reply action")
    }

    func testPostingFlowWithSuccessFixture() {
        launchComments(authenticated: true, commenting: true)
        let composer = assertHittable(composerCollapsed)
        composer.tap()

        let editor = assertHittable(composerEditor)
        editor.tap()
        editor.typeText("Fixture draft from the UI test.")

        let post = app.buttons.matching(identifier: AccessibilityIdentifier.Comments.composerPost).firstMatch
        XCTAssertTrue(post.waitForExistence(timeout: 5))
        post.tap()

        // Success inserts the server-confirmed comment and collapses the
        // composer back to its resting state. Lazy rows only exist once
        // scrolled into view, so look for the new comment from the bottom.
        XCTAssertTrue(
            composerCollapsed.waitForExistence(timeout: 10),
            "The composer should collapse after a successful post"
        )
        let submittedRow = submittedCommentRow()
        scroll(commentsList, untilVisible: submittedRow, maxSwipes: 30)
        XCTAssertTrue(
            submittedRow.waitForExistence(timeout: 10),
            "The server-confirmed comment should be inserted into the tree"
        )
    }

    func testPostingFailureKeepsDraft() {
        launchComments(authenticated: true, commenting: true, submission: .failure)
        let composer = assertHittable(composerCollapsed)
        composer.tap()

        let editor = assertHittable(composerEditor)
        editor.tap()
        editor.typeText("Draft that will fail.")

        let post = app.buttons.matching(identifier: AccessibilityIdentifier.Comments.composerPost).firstMatch
        XCTAssertTrue(post.waitForExistence(timeout: 5))
        post.tap()

        XCTAssertTrue(
            composerError.waitForExistence(timeout: 10),
            "A definite failure should show an inline error"
        )
        XCTAssertTrue(composerEditor.exists, "The composer stays expanded with the draft")
        assertAbsent(submittedCommentRow())
    }
}
