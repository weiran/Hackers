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
}
