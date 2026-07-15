import Domain
import Shared
import XCTest

@MainActor
final class HackersScreenshotTests: XCTestCase {
    private let screenshotPostID = 48_350_598
    private let dimmedPostID = 48_345_840
    private let firstScreenshotCommentID = 48_354_262
    private let laterScreenshotCommentID = 48_354_415
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

        let searchField = waitForHittable(app.searchFields.firstMatch, timeout: 10)
        searchField.tap()
        searchField.typeText("Swift")
        dismissSearchKeyboard()
        let searchResults = app.collectionViews["search.results"]
        waitForVisible(searchResults, in: app, timeout: 8)
        _ = waitForVisiblePost(id: searchOnlyPostID, in: searchResults)
        _ = waitForHittable(app.buttons["search.sort.menu"])
        _ = waitForHittable(app.buttons["search.date.menu"])
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

        let searchKey = waitForHittable(keyboard.buttons["Search"], timeout: timeout)
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
        var previousCandidateIndex: Int?
        var stableSamples = 0

        repeat {
            if let match = query.allElementsBoundByIndex.enumerated().first(where: {
                $0.element.isHittable && isMeaningfullyVisible($0.element, in: app)
            }) {
                let candidate = match.element
                let frame = candidate.frame
                if previousCandidateIndex == match.offset,
                   let previousFrame,
                   abs(previousFrame.minX - frame.minX) <= 1,
                   abs(previousFrame.minY - frame.minY) <= 1,
                   abs(previousFrame.width - frame.width) <= 1,
                   abs(previousFrame.height - frame.height) <= 1 {
                    stableSamples += 1
                } else {
                    stableSamples = 1
                }
                previousFrame = frame
                previousCandidateIndex = match.offset
                if stableSamples >= 3 {
                    return candidate
                }
            } else {
                previousFrame = nil
                previousCandidateIndex = nil
                stableSamples = 0
            }

            guard Date() < deadline else { break }
            RunLoop.current.run(until: Date().addingTimeInterval(0.05))
        } while true

        XCTFail("Expected screenshot button \(name) to become visibly hittable")
        return query.firstMatch
    }

    private func scrollCommentsToDeepThread() {
        let commentsList = waitForVisible(
            app.descendants(matching: .any)["comments.list"],
            in: app,
            timeout: 10
        )
        let firstComment = app.buttons["comments.comment.\(firstScreenshotCommentID)"]
        let laterComment = app.buttons["comments.comment.\(laterScreenshotCommentID)"]
        for _ in 0 ..< 8 where !hasCandidate(matching: laterComment, in: commentsList, satisfying: {
            isFullyContained($0, in: commentsList) && isInCentralCaptureBand($0, in: commentsList)
        }) {
            commentsList.swipeUp()
        }

        _ = waitForStableCandidate(
            matching: laterComment,
            in: commentsList,
            timeout: 5,
            description: "deep-thread comment to settle in the central capture band"
        ) {
            self.isFullyContained($0, in: commentsList)
                && self.isInCentralCaptureBand($0, in: commentsList)
        }
        waitForEveryCandidateOutside(
            firstComment,
            container: commentsList,
            timeout: 5
        )
    }

    private func waitForScreenshotComments() {
        let commentsList = waitForVisible(
            app.descendants(matching: .any)["comments.list"],
            in: app,
            timeout: 10
        )
        let firstComment = app.buttons["comments.comment.\(firstScreenshotCommentID)"]
        for _ in 0 ..< 8 where !hasCandidate(
            matching: firstComment,
            in: commentsList,
            satisfying: { self.isFullyContained($0, in: commentsList) }
        ) {
            commentsList.swipeDown()
        }
        _ = waitForFullyContained(firstComment, in: commentsList)
        _ = waitForFullyContained(app.staticTexts["manakov_dev"], in: commentsList)
    }

    private func waitForFixtureArticleContent() {
        let webView = waitForVisible(app.webViews["browser.fixtureArticle"], in: app, timeout: 20)
        _ = waitForFullyContained(webView.staticTexts[screenshotPostTitle], in: webView, timeout: 20)
        let collapsedHeader = app.descendants(matching: .any)
            .matching(identifier: "browser.commentsSheet.collapsedHeader")
            .firstMatch
        let visibleHeader = waitForFullyContained(collapsedHeader, in: app, timeout: 10)
        XCTAssertGreaterThan(
            visibleHeader.frame.minY,
            app.frame.midY,
            "Expected the collapsed comments sheet below the article capture area"
        )
    }

    private func waitForHittable(_ element: XCUIElement, timeout: TimeInterval = 5) -> XCUIElement {
        waitForStableCandidate(
            matching: element,
            in: app,
            timeout: timeout,
            description: "screenshot control to become visibly hittable"
        ) {
            $0.isHittable && self.isMeaningfullyVisible($0, in: self.app)
        }
    }

    @discardableResult
    private func waitForVisible(
        _ element: XCUIElement,
        in container: XCUIElement,
        timeout: TimeInterval = 5
    ) -> XCUIElement {
        waitForStableCandidate(
            matching: element,
            in: container,
            timeout: timeout,
            description: "screenshot content to become meaningfully visible"
        ) {
            self.isMeaningfullyVisible($0, in: container)
        }
    }

    private func waitForFullyContained(
        _ element: XCUIElement,
        in container: XCUIElement,
        timeout: TimeInterval = 5
    ) -> XCUIElement {
        waitForStableCandidate(
            matching: element,
            in: container,
            timeout: timeout,
            description: "screenshot content to become fully contained"
        ) {
            self.isFullyContained($0, in: container)
        }
    }

    private func waitForStableCandidate(
        matching element: XCUIElement,
        in container: XCUIElement,
        timeout: TimeInterval,
        description: String,
        satisfying condition: (XCUIElement) -> Bool
    ) -> XCUIElement {
        let deadline = Date().addingTimeInterval(timeout)
        var previousFrame: CGRect?
        var previousCandidateIndex: Int?
        var stableSamples = 0

        repeat {
            let matchingCandidates = candidates(matching: element, in: container)
            if container.exists,
               let match = matchingCandidates.enumerated().first(where: { condition($0.element) }) {
                let frame = match.element.frame
                if previousCandidateIndex == match.offset,
                   let previousFrame,
                   abs(previousFrame.minX - frame.minX) <= 1,
                   abs(previousFrame.minY - frame.minY) <= 1,
                   abs(previousFrame.width - frame.width) <= 1,
                   abs(previousFrame.height - frame.height) <= 1 {
                    stableSamples += 1
                } else {
                    stableSamples = 1
                }
                previousFrame = frame
                previousCandidateIndex = match.offset
                if stableSamples >= 3 {
                    return match.element
                }
            } else {
                previousFrame = nil
                previousCandidateIndex = nil
                stableSamples = 0
            }
            guard Date() < deadline else { break }
            RunLoop.current.run(until: Date().addingTimeInterval(0.05))
        } while true

        XCTFail("Expected \(description): \(element)")
        return element
    }

    private func waitForVisiblePost(
        id: Int,
        in container: XCUIElement,
        timeout: TimeInterval = 5
    ) -> XCUIElement {
        waitForStableCandidate(
            matching: app.descendants(matching: .any).matching(identifier: "feed.post.\(id)").firstMatch,
            in: container,
            timeout: timeout,
            description: "feed post \(id) to become meaningfully visible"
        ) {
            self.isMeaningfullyVisible($0, in: container)
        }
    }

    private func candidates(matching element: XCUIElement, in container: XCUIElement) -> [XCUIElement] {
        guard element.exists else { return [element] }
        let identifier = element.identifier
        guard !identifier.isEmpty else { return [element] }
        var matches = container.descendants(matching: .any)
            .matching(identifier: identifier)
            .allElementsBoundByIndex
        if container.identifier == identifier {
            matches.insert(container, at: 0)
        }
        let elementType = element.elementType
        let typeMatches = matches.filter { $0.elementType == elementType }
        if !typeMatches.isEmpty {
            matches = typeMatches
        }
        return matches.isEmpty ? [element] : matches
    }

    private func hasCandidate(
        matching element: XCUIElement,
        in container: XCUIElement,
        satisfying condition: (XCUIElement) -> Bool
    ) -> Bool {
        candidates(matching: element, in: container).contains(where: condition)
    }

    private func waitForEveryCandidateOutside(
        _ element: XCUIElement,
        container: XCUIElement,
        timeout: TimeInterval
    ) {
        let deadline = Date().addingTimeInterval(timeout)
        var stableSamples = 0
        repeat {
            let allOutside = candidates(matching: element, in: container).allSatisfy {
                !$0.exists || $0.frame.intersection(container.frame).isNull || $0.frame.intersection(container.frame).isEmpty
            }
            if allOutside {
                stableSamples += 1
                if stableSamples >= 3 { return }
            } else {
                stableSamples = 0
            }
            guard Date() < deadline else { break }
            RunLoop.current.run(until: Date().addingTimeInterval(0.05))
        } while true
        XCTFail("Expected every initial-comment candidate outside the captured viewport")
    }

    private func isFullyContained(_ element: XCUIElement, in container: XCUIElement) -> Bool {
        guard element.exists, container.exists else { return false }
        let frame = element.frame
        let containerFrame = container.frame
        guard !frame.isEmpty, !frame.isNull, !containerFrame.isEmpty, !containerFrame.isNull else {
            return false
        }
        return containerFrame.insetBy(dx: -1, dy: -1).contains(frame)
    }

    private func isInCentralCaptureBand(_ element: XCUIElement, in container: XCUIElement) -> Bool {
        let frame = element.frame
        let containerFrame = container.frame
        let band = containerFrame.insetBy(dx: 0, dy: containerFrame.height * 0.25)
        return band.contains(CGPoint(x: frame.midX, y: frame.midY))
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
