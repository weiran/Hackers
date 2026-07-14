import Domain
import Shared
import XCTest

@MainActor
final class HackersScreenshotTests: XCTestCase {
    private let screenshotPostID = 48_350_598
    private let dimmedPostID = 48_345_840
    private let firstScreenshotCommentID = 48_354_262
    private let laterScreenshotCommentID = 48_354_553
    private let searchOnlyPostID = 48_400_101
    private let screenshotPostTitle = "Swift 6.2 Released"
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testAppStoreScreenshots() throws {
        launchApp(configuration: marketingConfiguration(browserMode: .inAppBrowser))

        waitForVisible(app.collectionViews["feed.list"], in: app, timeout: 8)
        _ = waitForVisiblePost(id: screenshotPostID, in: app)
        snapshot("01-feed-built-for-reading")

        relaunch(configuration: marketingConfiguration(
            browserMode: .customBrowser,
            route: .story(postID: screenshotPostID, presentation: .collapsedBrowser)
        ))
        waitForFixtureArticleContent()
        snapshot("02-open-stories-inside-hackers")

        relaunch(configuration: marketingConfiguration(
            browserMode: .inAppBrowser,
            route: .comments(postID: screenshotPostID)
        ))
        waitForScreenshotComments()
        snapshot("03-read-comments-alongside-story")

        relaunch(configuration: marketingConfiguration(browserMode: .inAppBrowser))
        waitForVisible(app.collectionViews["feed.list"], in: app, timeout: 8)
        tapBottomBarSearchButton()

        let searchField = app.searchFields.firstMatch
        waitForHittable(searchField)
        searchField.tap()
        searchField.typeText("Swift")
        dismissSearchKeyboard()
        let searchResults = app.collectionViews["search.results"]
        waitForVisible(searchResults, in: app, timeout: 8)
        _ = waitForVisiblePost(id: searchOnlyPostID, in: searchResults)
        waitForHittable(app.buttons["search.sort.menu"])
        waitForHittable(app.buttons["search.date.menu"])
        snapshot("04-search-by-popular-recent-date")

        relaunch(configuration: marketingConfiguration(
            browserMode: .inAppBrowser,
            readPostIDs: [48_345_248, 48_347_354, dimmedPostID]
        ))
        let dimmedPost = waitForVisiblePost(id: dimmedPostID, in: app, timeout: 8)
        XCTAssertEqual(dimmedPost.value as? String, "read, dimmed")
        snapshot("05-dim-read-posts-across-devices")

        relaunch(configuration: marketingConfiguration(
            browserMode: .inAppBrowser,
            route: .comments(postID: screenshotPostID)
        ))
        waitForScreenshotComments()
        scrollCommentsToDeepThread()
        snapshot("06-vote-reply-follow-deep-threads")
    }

    private func marketingConfiguration(
        browserMode: LinkBrowserMode,
        route: UITestLaunchConfiguration.Route = .feed,
        readPostIDs: Set<Int> = []
    ) -> UITestLaunchConfiguration {
        UITestLaunchConfiguration(
            browserMode: browserMode,
            route: route,
            articleSource: .fixture,
            fixtureProfile: .marketing,
            readPostIDs: readPostIDs,
            dimReadPosts: true,
            showThumbnails: true
        )
    }

    private func launchApp(configuration: UITestLaunchConfiguration) {
        app = XCUIApplication(bundleIdentifier: "com.weiranzhang.Hackers")
        setupSnapshot(app)
        configureApp(configuration)
        app.launch()
    }

    private func relaunch(configuration: UITestLaunchConfiguration) {
        app.terminate()
        configureApp(configuration)
        app.launch()
    }

    private func configureApp(_ configuration: UITestLaunchConfiguration) {
        for key in UITestLaunchConfiguration.EnvironmentKey.allCases {
            app.launchEnvironment.removeValue(forKey: key.rawValue)
        }
        for (key, value) in configuration.environment {
            app.launchEnvironment[key] = value
        }
    }

    private func tapBottomBarSearchButton() {
        let searchButton = waitForVisibleButton(named: "Search")
        searchButton.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
    }

    private func dismissSearchKeyboard(timeout: TimeInterval = 5) {
        let keyboard = app.keyboards.firstMatch
        guard keyboard.exists else { return }

        let searchKey = keyboard.buttons["Search"]
        waitForHittable(searchKey, timeout: timeout)
        searchKey.tap()

        let deadline = Date().addingTimeInterval(timeout)
        while keyboard.exists, Date() < deadline {
            RunLoop.current.run(until: Date().addingTimeInterval(0.05))
        }
        XCTAssertFalse(keyboard.exists, "Expected the search keyboard to be dismissed before capture")
    }

    private func waitForVisibleButton(
        named name: String,
        timeout: TimeInterval = 5
    ) -> XCUIElement {
        let predicate = NSPredicate(format: "identifier == %@ OR label == %@", name, name)
        let query = app.buttons.matching(predicate)
        let deadline = Date().addingTimeInterval(timeout)
        var previousFrame: CGRect?
        var stableSamples = 0

        repeat {
            if let candidate = query.allElementsBoundByIndex.first(where: {
                isMeaningfullyVisible($0, in: app)
            }) {
                let frame = candidate.frame
                if let previousFrame,
                   abs(previousFrame.minX - frame.minX) <= 1,
                   abs(previousFrame.minY - frame.minY) <= 1,
                   abs(previousFrame.width - frame.width) <= 1,
                   abs(previousFrame.height - frame.height) <= 1 {
                    stableSamples += 1
                } else {
                    stableSamples = 1
                }
                previousFrame = frame
                if stableSamples >= 3 {
                    return candidate
                }
            } else {
                previousFrame = nil
                stableSamples = 0
            }

            guard Date() < deadline else { break }
            RunLoop.current.run(until: Date().addingTimeInterval(0.05))
        } while true

        XCTFail("Expected screenshot button \(name) to become meaningfully visible")
        return query.firstMatch
    }

    private func scrollCommentsToDeepThread() {
        let commentsList = app.descendants(matching: .any)["comments.list"]
        waitForVisible(commentsList, in: app, timeout: 10)
        let firstComment = app.buttons["comments.comment.\(firstScreenshotCommentID)"]
        let laterComment = app.buttons["comments.comment.\(laterScreenshotCommentID)"]
        waitForVisible(firstComment, in: commentsList)

        for _ in 0 ..< 8 where !isMeaningfullyVisible(laterComment, in: commentsList) {
            commentsList.swipeUp()
        }

        waitForVisible(laterComment, in: commentsList)
        XCTAssertFalse(
            isMeaningfullyVisible(firstComment, in: commentsList),
            "Expected the initial comment to be outside the captured viewport"
        )
    }

    private func waitForScreenshotComments() {
        let commentsList = app.descendants(matching: .any)["comments.list"]
        waitForVisible(commentsList, in: app, timeout: 10)
        let firstComment = app.buttons["comments.comment.\(firstScreenshotCommentID)"]
        for _ in 0 ..< 8 where !isMeaningfullyVisible(firstComment, in: commentsList) {
            commentsList.swipeDown()
        }
        waitForVisible(firstComment, in: commentsList)
        waitForVisible(app.staticTexts["manakov_dev"], in: commentsList)
    }

    private func waitForFixtureArticleContent() {
        let webView = app.webViews["browser.fixtureArticle"]
        waitForVisible(webView, in: app, timeout: 20)
        waitForVisible(webView.staticTexts[screenshotPostTitle], in: webView, timeout: 20)
        let collapsedHeader = app.descendants(matching: .any)
            .matching(identifier: "browser.commentsSheet.collapsedHeader")
            .firstMatch
        waitForVisible(collapsedHeader, in: app, timeout: 10)
    }

    private func waitForHittable(_ element: XCUIElement, timeout: TimeInterval = 5) {
        let deadline = Date().addingTimeInterval(timeout)
        repeat {
            if element.exists, element.isHittable, isMeaningfullyVisible(element, in: app) {
                return
            }
            guard Date() < deadline else { break }
            RunLoop.current.run(until: Date().addingTimeInterval(0.05))
        } while true
        XCTFail("Expected screenshot control to become visibly hittable: \(element)")
    }

    private func waitForVisible(
        _ element: XCUIElement,
        in container: XCUIElement,
        timeout: TimeInterval = 5
    ) {
        let deadline = Date().addingTimeInterval(timeout)
        var previousFrame: CGRect?
        var stableSamples = 0
        repeat {
            if isMeaningfullyVisible(element, in: container) {
                let frame = element.frame
                if let previousFrame,
                   abs(previousFrame.minX - frame.minX) <= 1,
                   abs(previousFrame.minY - frame.minY) <= 1,
                   abs(previousFrame.width - frame.width) <= 1,
                   abs(previousFrame.height - frame.height) <= 1 {
                    stableSamples += 1
                } else {
                    stableSamples = 1
                }
                previousFrame = frame
                if stableSamples >= 3 {
                    return
                }
            } else {
                previousFrame = nil
                stableSamples = 0
            }
            guard Date() < deadline else { break }
            RunLoop.current.run(until: Date().addingTimeInterval(0.05))
        } while true
        XCTFail("Expected screenshot content to become meaningfully visible: \(element)")
    }

    private func waitForVisiblePost(
        id: Int,
        in container: XCUIElement,
        timeout: TimeInterval = 5
    ) -> XCUIElement {
        let query = app.descendants(matching: .any).matching(identifier: "feed.post.\(id)")
        let deadline = Date().addingTimeInterval(timeout)
        var previousFrame: CGRect?
        var stableSamples = 0

        repeat {
            if let candidate = query.allElementsBoundByIndex.first(where: {
                isMeaningfullyVisible($0, in: container)
            }) {
                let frame = candidate.frame
                if let previousFrame,
                   abs(previousFrame.minX - frame.minX) <= 1,
                   abs(previousFrame.minY - frame.minY) <= 1,
                   abs(previousFrame.width - frame.width) <= 1,
                   abs(previousFrame.height - frame.height) <= 1 {
                    stableSamples += 1
                } else {
                    stableSamples = 1
                }
                previousFrame = frame
                if stableSamples >= 3 {
                    return candidate
                }
            } else {
                previousFrame = nil
                stableSamples = 0
            }

            guard Date() < deadline else { break }
            RunLoop.current.run(until: Date().addingTimeInterval(0.05))
        } while true

        XCTFail("Expected feed post \(id) to become meaningfully visible")
        return query.firstMatch
    }

    private func isMeaningfullyVisible(_ element: XCUIElement, in container: XCUIElement) -> Bool {
        guard element.exists, container.exists else { return false }
        let frame = element.frame
        let containerFrame = container.frame
        guard !frame.isEmpty, !frame.isNull, !containerFrame.isEmpty, !containerFrame.isNull else {
            return false
        }
        let intersection = frame.intersection(containerFrame)
        guard !intersection.isNull, !intersection.isEmpty else { return false }
        let visibleFraction = (intersection.width * intersection.height) / (frame.width * frame.height)
        return intersection.width >= min(frame.width, 20)
            && intersection.height >= min(frame.height, 20)
            && visibleFraction >= 0.2
    }
}
