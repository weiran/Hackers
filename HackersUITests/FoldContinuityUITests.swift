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

    func testWideStoryUsesDetailBrowserAndNativeSidebar() throws {
        launchApp(configuration: UITestLaunchConfiguration(
            browserMode: .customBrowser,
            route: .story(postID: screenshotPostID, presentation: .collapsedBrowser)
        ))
        guard let window = app.windows.allElementsBoundByIndex.first(where: { $0.frame.width >= 800 }) else {
            throw XCTSkip("Requires an open landscape Duo or a wide iPad window")
        }
        assertFixtureArticleLoaded()
        let post = window.buttons[AccessibilityIdentifier.Feed.post(screenshotPostID)]
        assertHittable(post)
        XCTAssertFalse(collapsedCommentsHeader.exists)
        XCTAssertFalse(commentsSheetHandle.exists)

        let article = window.webViews[AccessibilityIdentifier.Browser.fixtureArticle]
        let expandedWidth = article.frame.width
        let title = article.staticTexts["Swift 6.2 Released"]
        func assertViewportTitleFits() {
            XCTAssertNotNil(waitForStableFrame(of: title, timeout: 5) {
                $0.minX >= article.frame.minX + 8 && $0.maxX <= article.frame.maxX - 8
            }, "A viewport-width heading must remain inside the readable browser column")
        }
        assertViewportTitleFits()
        let note = assertHittable(article.textFields["Reader note"])
        note.tap()
        note.typeText("Keep this page when hiding the feed")
        article.staticTexts["Swift 6.2 Released"].tap()
        attachScreenshot("Wide native browser with sidebar")

        let sidebarButton = window.buttons.matching(NSPredicate(
            format: "identifier CONTAINS[c] 'sidebar' OR label CONTAINS[c] 'sidebar'"
        )).firstMatch
        assertHittable(sidebarButton).tap()
        XCTAssertTrue(waitForStableFrame(of: article, timeout: 5) {
            $0.width > expandedWidth + 100
        } != nil)
        XCTAssertFalse(post.isHittable)
        XCTAssertTrue((note.value as? String)?.contains("Keep this page") == true)
        attachScreenshot("Wide native browser with sidebar hidden")

        assertHittable(sidebarButton).tap()
        let feed = window.descendants(matching: .any)
            .matching(identifier: AccessibilityIdentifier.Feed.list).firstMatch
        assertHasVisibleIntersection(feed, in: window)
        assertHittable(window.buttons[AccessibilityIdentifier.Feed.settingsButton])
        XCTAssertTrue((note.value as? String)?.contains("Keep this page") == true)
        attachScreenshot("Wide native browser sidebar restored")
        assertViewportTitleFits()

        // Repeating the transition catches stale native insets on cached web views.
        assertHittable(sidebarButton).tap()
        XCTAssertNotNil(waitForStableFrame(of: article, timeout: 5) { $0.width > expandedWidth + 100 })
        assertViewportTitleFits()
        assertHittable(sidebarButton).tap()
        XCTAssertNotNil(waitForStableFrame(of: article, timeout: 5) { abs($0.width - expandedWidth) < 2 })
        attachScreenshot("Wide viewport after repeated sidebar transition")
        assertViewportTitleFits()
    }

    func testWideCommentsUseDetailWithoutCustomSheet() throws {
        launchApp(configuration: UITestLaunchConfiguration(
            browserMode: .customBrowser,
            route: .story(postID: screenshotPostID, presentation: .expandedComments)
        ))
        guard let window = app.windows.allElementsBoundByIndex.first(where: { $0.frame.width >= 800 }) else {
            throw XCTSkip("Requires an open landscape Duo or a wide iPad window")
        }
        assertHittable(window.buttons[AccessibilityIdentifier.Feed.post(screenshotPostID)])
        assertHasVisibleIntersection(commentsList, in: app)
        XCTAssertFalse(commentsSheetHandle.exists)
        XCTAssertFalse(collapsedCommentsHeader.exists)
        assertWideToolbarButton("Show Article", in: window)
        XCTAssertFalse(window.buttons["Refresh"].exists)
        assertWideToolbarButton("Share", in: window)
        attachScreenshot("Wide comments in native detail")
    }

    // Failure modes: missing/inaccessible toggle, wrong post's comments, custom sheet
    // returning in wide layout, lost browser form state, or duplicate toolbar controls.
    func testWideBrowserSwitchesToCommentsAndPreservesPage() throws {
        launchApp(configuration: UITestLaunchConfiguration(
            browserMode: .customBrowser,
            route: .story(postID: screenshotPostID, presentation: .collapsedBrowser)
        ))
        guard let window = app.windows.allElementsBoundByIndex.first(where: { $0.frame.width >= 800 }) else {
            throw XCTSkip("Requires an open landscape Duo or a wide iPad window")
        }
        assertFixtureArticleLoaded()
        let article = window.webViews[AccessibilityIdentifier.Browser.fixtureArticle]
        let note = assertHittable(article.textFields["Reader note"])
        note.tap()
        note.typeText("Preserve this page through comments")
        article.staticTexts["Swift 6.2 Released"].tap()
        assertWideToolbarButton("Show Comments", in: window).tap()
        assertHasVisibleIntersection(commentsList, in: window)
        XCTAssertFalse(commentsSheetHandle.exists)
        XCTAssertFalse(collapsedCommentsHeader.exists)
        XCTAssertEqual(window.buttons.matching(NSPredicate(format: "label == 'Show Article'")).count, 1)
        attachScreenshot("Wide toolbar switched to comments")
        assertWideToolbarButton("Show Article", in: window).tap()
        assertFixtureArticleLoaded()
        XCTAssertTrue((assertHittable(article.textFields["Reader note"]).value as? String)?
            .contains("Preserve this page through comments") == true)
        assertWideToolbarButton("Show Comments", in: window)
        attachScreenshot("Wide toolbar restored browser page")
    }

    // Failure modes: search remains in the detail rail, duplicate search controls,
    // activation searches the wrong column, or opening search loses the article.
    func testWideSearchStaysInFeedHeader() throws {
        launchApp(configuration: UITestLaunchConfiguration(
            browserMode: .customBrowser,
            route: .story(postID: screenshotPostID, presentation: .collapsedBrowser)
        ))
        guard let window = app.windows.allElementsBoundByIndex.first(where: { $0.frame.width >= 800 }) else {
            throw XCTSkip("Requires an open landscape Duo or a wide iPad window")
        }
        assertFixtureArticleLoaded()
        let feed = window.descendants(matching: .any)
            .matching(identifier: AccessibilityIdentifier.Feed.list).firstMatch
        assertHasVisibleIntersection(feed, in: window)
        let feedFrame = feed.frame
        let search = assertWideToolbarButton("Search", in: window)
        XCTAssertEqual(window.buttons.matching(NSPredicate(format: "label == 'Search'")).count, 1)
        XCTAssertLessThanOrEqual(search.frame.maxX, feedFrame.maxX + 1)
        let settings = window.buttons[AccessibilityIdentifier.Feed.settingsButton]
        XCTAssertLessThanOrEqual(abs(search.frame.midY - settings.frame.midY), 1)
        // Search should have its own chrome to the left of Settings; inspect the
        // retained screenshot for separate groups as well as checking their order.
        XCTAssertLessThan(search.frame.maxX, settings.frame.minX)
        attachScreenshot("Duo search in feed header with article open")
        search.tap()
        let field = window.searchFields.firstMatch
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        XCTAssertTrue(field.isHittable)
        field.tap()
        field.typeText("Migration Guide")
        let result = window.buttons[AccessibilityIdentifier.Feed.post(searchOnlyPostID)]
        assertHasVisibleIntersection(result, in: window, timeout: 8)
        XCTAssertLessThanOrEqual(result.frame.maxX, feedFrame.maxX + 1)
        XCTAssertTrue(window.webViews[AccessibilityIdentifier.Browser.fixtureArticle].exists)
        attachScreenshot("Duo feed search results with article retained")
    }

    // MARK: - Helpers

    /// Duo's application frame can describe the inactive outer display. Toolbar buttons
    /// on the inner display must be checked against the actual wide window instead.
    @discardableResult
    private func assertWideToolbarButton(_ title: String, in window: XCUIElement) -> XCUIElement {
        let button = window.buttons[title]
        XCTAssertTrue(button.waitForExistence(timeout: 5))
        assertHasVisibleIntersection(button, in: window)
        XCTAssertTrue(button.isHittable)
        return button
    }

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
                if self.app.webViews[AccessibilityIdentifier.Browser.fixtureArticle].exists {
                    return !self.commentsSheetHandle.exists
                }
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
