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

    private var composerExpanded: XCUIElement {
        app.descendants(matching: .any)
            .matching(identifier: AccessibilityIdentifier.Comments.composerExpanded)
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

    func testEmptyCollapsedComposerShowsCommentIconAndPlaceholder() {
        launchComments(authenticated: true, commenting: true)

        let icon = app.images["Add comment icon"]
        XCTAssertTrue(icon.waitForExistence(timeout: 5), "An empty collapsed composer should show its comment icon")

        let placeholder = app.staticTexts["Add a comment…"]
        XCTAssertTrue(placeholder.waitForExistence(timeout: 5), "An empty collapsed composer should retain its placeholder")
    }

    func testCollapsedComposerUsesTwentyFourPointScreenMargins() {
        launchComments(authenticated: true, commenting: true)

        let composer = assertHittable(composerCollapsed)
        let nextButton = assertHittable(nextCommentButton)
        let gapBelowComposer = app.frame.maxY - composer.frame.maxY

        XCTAssertEqual(composer.frame.minX, 24, accuracy: 4)
        XCTAssertEqual(app.frame.maxX - nextButton.frame.maxX, 24, accuracy: 4)

        XCTAssertEqual(
            gapBelowComposer,
            24,
            accuracy: 4,
            "The collapsed composer should keep 24pt screen margins. Bottom gap: \(gapBelowComposer)"
        )
    }

    func testExpandedComposerRestoresOriginalKeyboardMargin() {
        launchComments(authenticated: true, commenting: true)

        assertHittable(composerCollapsed).tap()

        let composer = assertHasVisibleIntersection(composerExpanded, in: app)
        let keyboard = app.keyboards.firstMatch
        XCTAssertTrue(keyboard.waitForExistence(timeout: 5), "The software keyboard should be visible while editing")
        XCTAssertEqual(
            keyboard.frame.minY - composer.frame.maxY,
            52,
            accuracy: 4,
            "The expanded composer should preserve its original keyboard margin"
        )
    }

    func testComposerKeyboardUsesReturnKey() {
        launchComments(authenticated: true, commenting: true)

        assertHittable(composerCollapsed).tap()
        let keyboard = app.keyboards.firstMatch
        XCTAssertTrue(keyboard.waitForExistence(timeout: 5))

        let returnKey = keyboard.buttons.matching(
            NSPredicate(format: "label ==[c] %@", "Return")
        ).firstMatch
        XCTAssertTrue(returnKey.waitForExistence(timeout: 5), "The comment composer should use the standard Return key")
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

    func testCollapsedReplyLabelKeepsCardTopInset() {
        launchComments(authenticated: true, commenting: true)

        let reply = replyButton(commentID: UITestFixtureReference.firstScreenshotCommentID)
        scroll(commentsList, untilVisible: reply)
        assertHittable(reply).tap()

        let replyLabel = app.descendants(matching: .any)
            .matching(identifier: AccessibilityIdentifier.Comments.composerReplyLabel)
            .firstMatch
        XCTAssertTrue(replyLabel.waitForExistence(timeout: 5))

        let targetRow = app.descendants(matching: .any)
            .matching(identifier: AccessibilityIdentifier.Comments.comment(UITestFixtureReference.firstScreenshotCommentID))
            .firstMatch
        assertHittable(targetRow).tap()

        let collapsedComposer = assertHittable(composerCollapsed)
        XCTAssertGreaterThanOrEqual(
            replyLabel.frame.minY - collapsedComposer.frame.minY,
            6,
            "A collapsed reply label should retain the card's top inset"
        )
        XCTAssertLessThanOrEqual(
            composerEditor.frame.minY - replyLabel.frame.maxY,
            8,
            "A collapsed reply label should stay visually paired with its editor"
        )
        XCTAssertLessThanOrEqual(
            collapsedComposer.frame.maxY - composerEditor.frame.maxY,
            8,
            "A collapsed reply editor should retain the card's bottom inset"
        )
    }

    func testDirtyReplySwitchPreservesDraftWithoutConfirmation() {
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

        let switchedLabel = app.descendants(matching: .any)
            .matching(identifier: AccessibilityIdentifier.Comments.composerReplyLabel)
            .firstMatch
        XCTAssertTrue(switchedLabel.waitForExistence(timeout: 5))
        XCTAssertTrue(
            switchedLabel.label.contains("lexicality"),
            "Switching replies should immediately retarget the composer, got: \(switchedLabel.label)"
        )
        let preservedDraft = composerEditor.value as? String ?? ""
        XCTAssertTrue(preservedDraft.contains("precious draft"), "Switching replies should preserve the text, got: \(preservedDraft)")
        XCTAssertFalse(
            app.alerts.firstMatch.waitForExistence(timeout: 1),
            "Switching replies with a draft should not show a confirmation dialog"
        )
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

    func testDelayedPostingCollapsesComposerAndKeyboard() {
        launchComments(authenticated: true, commenting: true, submission: .delayedSuccess)
        let composer = assertHittable(composerCollapsed)
        composer.tap()

        let editor = assertHittable(composerEditor)
        editor.tap()
        editor.typeText("Draft whose keyboard must leave after posting.")

        let post = app.buttons.matching(identifier: AccessibilityIdentifier.Comments.composerPost).firstMatch
        XCTAssertTrue(post.waitForExistence(timeout: 5))
        post.tap()

        XCTAssertTrue(
            composerCollapsed.waitForExistence(timeout: 15),
            "The composer should collapse after a successful post"
        )
        // Give the keyboard-hide animation plenty of room to finish; a wedged
        // focus state keeps the keyboard up indefinitely after the collapse.
        RunLoop.current.run(until: Date().addingTimeInterval(3))
        XCTAssertFalse(
            app.keyboards.firstMatch.exists,
            "The keyboard should be dismissed after the composer collapses"
        )
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

    func testCustomBrowserCollapsedComposerUsesTwentyFourPointScreenMargins() throws {
        XCUIDevice.shared.orientation = .portrait
        launchApp(configuration: UITestLaunchConfiguration(
            authenticated: true,
            commentingEnabled: true
        ))

        let post = assertHittable(app.buttons[AccessibilityIdentifier.Feed.post(longCommentsPostID)], timeout: 8)
        tapPost(post)

        assertFullyContained(browserView, in: app)
        let composer = assertHittable(composerCollapsed)
        let nextButton = assertHittable(nextCommentButton)
        let gapBelowComposer = app.frame.maxY - composer.frame.maxY

        XCTAssertEqual(composer.frame.minX, 24, accuracy: 4)
        XCTAssertEqual(app.frame.maxX - nextButton.frame.maxX, 24, accuracy: 4)

        XCTAssertEqual(
            gapBelowComposer,
            24,
            accuracy: 4,
            "The browser-sheet composer should keep 24pt screen margins. Bottom gap: \(gapBelowComposer)"
        )
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

        let composer = assertHasVisibleIntersection(composerExpanded, in: app)
        let postButton = app.buttons.matching(identifier: AccessibilityIdentifier.Comments.composerPost).firstMatch
        let keyboard = app.keyboards.firstMatch
        XCTAssertTrue(keyboard.waitForExistence(timeout: 5), "The software keyboard should be visible while editing")
        XCTAssertTrue(editor.isHittable, "The browser composer editor should remain visible above the keyboard")
        XCTAssertTrue(postButton.isHittable, "The browser Post action should remain visible above the keyboard")
        XCTAssertEqual(
            keyboard.frame.minY - composer.frame.maxY,
            52,
            accuracy: 4,
            "The browser composer should preserve its original keyboard margin"
        )
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
