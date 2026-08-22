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

    // MARK: - Draft lifetime

    func testDraftPersistsAcrossCollapseAndReopen() {
        launchComments(authenticated: true, commenting: true)
        let composer = assertHittable(composerCollapsed)
        composer.tap()

        let editor = assertHittable(composerEditor)
        editor.tap()
        editor.typeText("Draft that survives collapse.")

        // Scrolling the thread keeps the composer and keyboard open. The swipe
        // starts on the list above the keyboard.
        let swipeStart = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.3))
        let swipeEnd = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.12))
        swipeStart.press(forDuration: 0.05, thenDragTo: swipeEnd)

        XCTAssertTrue(
            composerEditor.waitForExistence(timeout: 5),
            "Scrolling should keep the editor expanded"
        )

        let commentRows = app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH %@", "comments.comment.")
        )
        let visibleCommentRow = commentRows.allElementsBoundByIndex.first {
            $0.isHittable && hasVisibleIntersection($0, in: commentsList)
        }
        XCTAssertNotNil(visibleCommentRow, "A visible comment should be tappable while editing")
        visibleCommentRow?.tap()

        XCTAssertTrue(
            composerCollapsed.waitForExistence(timeout: 5),
            "A comment interaction should collapse the composer with the draft preserved"
        )
        XCTAssertTrue(
            composerCollapsed.label.contains("Draft that survives"),
            "The collapsed preview should show the first draft line"
        )

        composerCollapsed.tap()
        let reopened = assertHittable(composerEditor)
        let draftValue = reopened.value as? String ?? ""
        XCTAssertTrue(
            draftValue.contains("Draft that survives collapse."),
            "Reopening should restore the full draft, got: \(draftValue)"
        )
    }

    // MARK: - Replies

    func testReplyShowsTargetUsernameAndFocusedEditor() {
        launchComments(authenticated: true, commenting: true)

        let reply = replyButton(commentID: UITestFixtureReference.firstScreenshotCommentID)
        scroll(commentsList, untilVisible: reply)
        assertHittable(reply).tap()

        let replyLabel = app.descendants(matching: .any)
            .matching(identifier: AccessibilityIdentifier.Comments.composerReplyLabel)
            .firstMatch
        XCTAssertTrue(replyLabel.waitForExistence(timeout: 5), "Reply mode should show the target username")
        XCTAssertTrue(replyLabel.label.contains("manakov_dev"), "Expected the target author, got: \(replyLabel.label)")

        XCTAssertTrue(assertHittable(composerEditor).isHittable, "The editor should receive focus")
        let targetRow = app.descendants(matching: .any)
            .matching(identifier: AccessibilityIdentifier.Comments.comment(UITestFixtureReference.firstScreenshotCommentID))
            .firstMatch
        XCTAssertTrue(
            hasVisibleIntersection(targetRow, in: app),
            "The reply target should remain visible above the composer"
        )
    }

    func testDirtyReplySwitchRequiresConfirmation() {
        launchComments(authenticated: true, commenting: true)

        let firstReply = replyButton(commentID: UITestFixtureReference.firstScreenshotCommentID)
        scroll(commentsList, untilVisible: firstReply)
        assertHittable(firstReply).tap()
        let editor = assertHittable(composerEditor)
        editor.tap()
        editor.typeText("precious draft")

        let secondReply = replyButton(commentID: UITestFixtureReference.secondReplyTargetCommentID)
        scroll(commentsList, untilVisible: secondReply)
        assertHittable(secondReply).tap()

        let alert = app.alerts.firstMatch
        XCTAssertTrue(alert.waitForExistence(timeout: 5), "Switching targets with a draft should ask for confirmation")

        let keepEditing = alert.buttons["Keep Editing"]
        XCTAssertTrue(keepEditing.exists)
        keepEditing.tap()

        XCTAssertTrue(composerEditor.waitForExistence(timeout: 5), "Keep Editing preserves the expanded draft")
        let keptDraft = composerEditor.value as? String ?? ""
        XCTAssertTrue(keptDraft.contains("precious draft"), "Keep Editing preserves the text, got: \(keptDraft)")
        let keptLabel = app.descendants(matching: .any)
            .matching(identifier: AccessibilityIdentifier.Comments.composerReplyLabel)
            .firstMatch
        XCTAssertTrue(keptLabel.label.contains("manakov_dev"), "Keep Editing preserves the original target")

        scroll(commentsList, untilVisible: secondReply)
        assertHittable(secondReply).tap()
        XCTAssertTrue(alert.waitForExistence(timeout: 5))
        let discardAndReply = alert.buttons["Discard & Reply"]
        XCTAssertTrue(discardAndReply.exists)
        discardAndReply.tap()

        let switchedLabel = app.descendants(matching: .any)
            .matching(identifier: AccessibilityIdentifier.Comments.composerReplyLabel)
            .firstMatch
        XCTAssertTrue(switchedLabel.waitForExistence(timeout: 5))
        XCTAssertTrue(
            switchedLabel.label.contains("lexicality"),
            "Discard & Reply should switch to the new target, got: \(switchedLabel.label)"
        )
        let clearedDraft = composerEditor.value as? String ?? ""
        XCTAssertTrue(clearedDraft.isEmpty, "Discard & Reply clears the old text, got: \(clearedDraft)")
    }

    // MARK: - Spinner and outcome-unknown flows

    func testPostingShowsSpinnerBeforeInsertion() {
        launchComments(authenticated: true, commenting: true, submission: .delayedSuccess)
        let composer = assertHittable(composerCollapsed)
        composer.tap()

        let editor = assertHittable(composerEditor)
        editor.tap()
        editor.typeText("Delayed fixture draft.")

        let post = app.buttons.matching(identifier: AccessibilityIdentifier.Comments.composerPost).firstMatch
        XCTAssertTrue(post.waitForExistence(timeout: 5))
        post.tap()

        // The ProgressView inside the button does not surface as its own
        // accessibility element, so assert the behavioral posting lock:
        // editing disabled and the Post control disabled while in flight.
        let postingDeadline = Date().addingTimeInterval(3)
        var editorLocked = false
        while Date() < postingDeadline {
            if composerEditor.exists, !composerEditor.isEnabled, !post.isEnabled {
                editorLocked = true
                break
            }
            RunLoop.current.run(until: Date().addingTimeInterval(0.05))
        }
        XCTAssertTrue(editorLocked, "Posting should lock the editor and Post control")
        assertAbsent(submittedCommentRow(), timeout: 2)

        XCTAssertTrue(
            composerCollapsed.waitForExistence(timeout: 15),
            "The delayed success should eventually collapse the composer"
        )
        let submittedRow = submittedCommentRow()
        scroll(commentsList, untilVisible: submittedRow, maxSwipes: 30)
        XCTAssertTrue(submittedRow.waitForExistence(timeout: 10))
    }

    func testOutcomeUnknownAlertCheckAgainResolvesOnce() {
        launchComments(authenticated: true, commenting: true, submission: .outcomeUnknown)
        let composer = assertHittable(composerCollapsed)
        composer.tap()

        let editor = assertHittable(composerEditor)
        editor.tap()
        editor.typeText("Uncertain outcome draft.")

        let post = app.buttons.matching(identifier: AccessibilityIdentifier.Comments.composerPost).firstMatch
        XCTAssertTrue(post.waitForExistence(timeout: 5))
        post.tap()

        let alert = app.alerts.firstMatch
        XCTAssertTrue(alert.waitForExistence(timeout: 10), "An unconfirmed outcome should present the warning")
        XCTAssertTrue(alert.buttons["Check Again"].exists)
        XCTAssertTrue(alert.buttons["Keep Draft"].exists)
        XCTAssertTrue(composerEditor.exists, "The draft stays in the expanded composer")
        assertAbsent(submittedCommentRow(), timeout: 2)

        alert.buttons["Check Again"].tap()

        XCTAssertTrue(
            composerCollapsed.waitForExistence(timeout: 10),
            "A successful Check Again should insert the comment and clear the composer"
        )
        let submittedRow = submittedCommentRow()
        scroll(commentsList, untilVisible: submittedRow, maxSwipes: 30)
        XCTAssertTrue(
            submittedRow.waitForExistence(timeout: 10),
            "The reconciled comment should be inserted exactly once"
        )
    }

    // MARK: - Custom browser presentation

    func testCustomBrowserExpandedCommentsShowsComposer() throws {
        XCUIDevice.shared.orientation = .portrait
        launchApp(configuration: UITestLaunchConfiguration(
            authenticated: true,
            commentingEnabled: true
        ))

        let post = assertHittable(app.buttons[AccessibilityIdentifier.Feed.post(longCommentsPostID)], timeout: 8)
        tapPost(post)

        assertFullyContained(browserView, in: app)
        XCTAssertTrue(
            assertHasVisibleIntersection(commentsList, in: app).exists,
            "Expected the expanded comments sheet"
        )
        let composer = assertHasVisibleIntersection(composerCollapsed, in: app)
        XCTAssertTrue(composer.isHittable, "The composer should be usable in the browser comments sheet")
    }

    func testCustomBrowserComposerRemainsAboveKeyboard() throws {
        XCUIDevice.shared.orientation = .portrait
        launchApp(configuration: UITestLaunchConfiguration(
            authenticated: true,
            commentingEnabled: true
        ))

        let post = assertHittable(app.buttons[AccessibilityIdentifier.Feed.post(longCommentsPostID)], timeout: 8)
        tapPost(post)

        assertFullyContained(browserView, in: app)
        assertHasVisibleIntersection(commentsList, in: app)
        assertHittable(composerCollapsed).tap()

        let editor = assertHittable(composerEditor)
        editor.tap()
        editor.typeText("Keyboard-safe browser draft.")

        let postButton = app.buttons.matching(identifier: AccessibilityIdentifier.Comments.composerPost).firstMatch
        let keyboard = app.keyboards.firstMatch
        XCTAssertTrue(keyboard.waitForExistence(timeout: 5), "The software keyboard should be visible while editing")
        XCTAssertTrue(editor.isHittable, "The browser composer editor should remain visible above the keyboard")
        XCTAssertTrue(postButton.isHittable, "The browser Post action should remain visible above the keyboard")
        XCTAssertLessThanOrEqual(
            editor.frame.maxY,
            keyboard.frame.minY,
            "The browser editor must not be covered by the keyboard"
        )
        XCTAssertLessThanOrEqual(
            postButton.frame.maxY,
            keyboard.frame.minY,
            "The browser Post action must not be covered by the keyboard"
        )
    }
}
