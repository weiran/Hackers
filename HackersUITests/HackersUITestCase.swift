import Domain
import Shared
import XCTest

@MainActor
// swiftlint:disable:next type_body_length
class HackersUITestCase: XCTestCase {
    let screenshotPostID = UITestFixtureReference.screenshotPostID
    let longCommentsPostID = UITestFixtureReference.longCommentsPostID
    let largeCommentsPostID = UITestFixtureReference.largeCommentsPostID
    let searchOnlyPostID = UITestFixtureReference.searchOnlyPostID
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func launchApp(linkBrowserMode: LinkBrowserMode = .customBrowser) {
        launchApp(configuration: UITestLaunchConfiguration(browserMode: linkBrowserMode))
    }

    func launchApp(configuration: UITestLaunchConfiguration) {
        app = XCUIApplication(bundleIdentifier: "com.weiranzhang.Hackers")
        app.terminate()
        for (key, value) in configuration.environment {
            app.launchEnvironment[key] = value
        }
        app.launch()
    }

    var commentsList: XCUIElement {
        app.descendants(matching: .any).matching(identifier: AccessibilityIdentifier.Comments.list).firstMatch
    }

    var collapsedCommentsHeader: XCUIElement {
        app.descendants(matching: .any)
            .matching(identifier: AccessibilityIdentifier.Browser.collapsedCommentsHeader)
            .firstMatch
    }

    var commentsSheetHandle: XCUIElement {
        app.descendants(matching: .any)
            .matching(identifier: AccessibilityIdentifier.Browser.commentsSheetHandle)
            .firstMatch
    }

    var expandedCommentsTitle: XCUIElement {
        app.buttons.matching(identifier: AccessibilityIdentifier.Browser.expandedCommentsTitle).firstMatch
    }

    var browserView: XCUIElement {
        app.otherElements.matching(identifier: AccessibilityIdentifier.Browser.view).firstMatch
    }

    func tapPost(_ post: XCUIElement) {
        let frame = post.frame
        tapAbsolutePoint(x: frame.midX, y: frame.midY)
    }

    func collapseCommentsByTappingTitle() {
        let title = assertHasVisibleIntersection(expandedCommentsTitle, in: app)
        tapAbsolutePoint(x: title.frame.maxX - 12, y: title.frame.midY)
        assertHasVisibleIntersection(collapsedCommentsHeader, in: app)
    }

    func assertFixtureArticleLoaded(timeout: TimeInterval = 8) {
        let article = app.webViews[AccessibilityIdentifier.Browser.fixtureArticle]
        XCTAssertTrue(article.waitForExistence(timeout: timeout), "Expected the fixture article web view to load")
        XCTAssertTrue(
            article.staticTexts["Fixture article loaded from the UI-test Hacker News Active snapshot."]
                .waitForExistence(timeout: timeout),
            "Expected fixture article content in the accessibility hierarchy"
        )
    }

    func tapAbsolutePoint(x absoluteX: CGFloat, y absoluteY: CGFloat) {
        app.coordinate(
            withNormalizedOffset: CGVector(
                dx: absoluteX / app.frame.width,
                dy: absoluteY / app.frame.height
            )
        ).tap()
    }

    @discardableResult
    func assertHittable(
        _ element: XCUIElement,
        timeout: TimeInterval = 5,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> XCUIElement {
        guard let candidate = waitForRenderedCandidate(
            matching: element,
            in: app,
            timeout: timeout,
            requiresHittable: true
        ) else {
            addVisibilityFailureDiagnostics(for: element, in: app)
            XCTFail("Expected element to become visibly hittable: \(element)", file: file, line: line)
            return element
        }
        return candidate
    }

    @discardableResult
    func assertFullyContained(
        _ element: XCUIElement,
        in container: XCUIElement,
        timeout: TimeInterval = 5,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> XCUIElement {
        guard let candidate = waitForRenderedCandidate(
            matching: element,
            in: container,
            timeout: timeout,
            requiresFullContainment: true
        ) else {
            addVisibilityFailureDiagnostics(for: element, in: container)
            XCTFail(
                "Expected element to become contained in \(container): \(element)",
                file: file,
                line: line
            )
            return element
        }
        return candidate
    }

    @discardableResult
    func assertHasVisibleIntersection(
        _ element: XCUIElement,
        in container: XCUIElement,
        timeout: TimeInterval = 5,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> XCUIElement {
        guard let candidate = waitForRenderedCandidate(
            matching: element,
            in: container,
            timeout: timeout
        ) else {
            addVisibilityFailureDiagnostics(for: element, in: container)
            XCTFail(
                "Expected element to become meaningfully visible in \(container): \(element)",
                file: file,
                line: line
            )
            return element
        }
        return candidate
    }

    func assertAbsent(
        _ element: XCUIElement,
        timeout: TimeInterval = 3,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        waitForNonExistence(element, timeout: timeout, file: file, line: line)
    }

    func assertNotVisible(
        _ element: XCUIElement,
        in container: XCUIElement,
        timeout: TimeInterval = 3,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let deadline = Date().addingTimeInterval(timeout)
        var stableSamples = 0
        repeat {
            if !hasVisibleIntersection(element, in: container) {
                stableSamples += 1
                if stableSamples >= 3 { return }
            } else {
                stableSamples = 0
            }
            guard Date() < deadline else { break }
            RunLoop.current.run(until: Date().addingTimeInterval(0.05))
        } while true
        XCTFail("Expected element not to be meaningfully visible: \(element)", file: file, line: line)
    }

    func hasVisibleIntersection(_ element: XCUIElement, in container: XCUIElement) -> Bool {
        guard container.exists, element.exists else { return false }
        return isMeaningfullyVisible(element.frame, in: container.frame)
    }

    func scroll(_ container: XCUIElement, untilVisible element: XCUIElement, maxSwipes: Int = 6) {
        for _ in 0 ..< maxSwipes where !hasVisibleIntersection(element, in: container) {
            container.swipeUp()
            waitForFrameToSettle(element, timeout: 1)
        }
    }

    func scrollCustomBrowserComments(untilVisible element: XCUIElement, maxDrags: Int = 8) {
        let start = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.78))
        let end = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.28))
        for _ in 0 ..< maxDrags where !hasVisibleIntersection(element, in: app) {
            start.press(forDuration: 0.05, thenDragTo: end)
            waitForFrameToSettle(element, timeout: 1)
        }
    }

    func dragCustomBrowserCommentsUp(count: Int) {
        let start = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.78))
        let end = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.28))
        for _ in 0 ..< count {
            start.press(forDuration: 0.05, thenDragTo: end)
        }
        waitForFrameToSettle(commentsList, timeout: 2)
    }

    func waitForNonExistence(
        _ element: XCUIElement,
        timeout: TimeInterval,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let deadline = Date().addingTimeInterval(timeout)
        while element.exists, Date() < deadline {
            RunLoop.current.run(until: Date().addingTimeInterval(0.05))
        }
        XCTAssertFalse(
            element.exists,
            "Expected every matching element to disappear: \(element)",
            file: file,
            line: line
        )
    }

    func waitForFrameMinY(of element: XCUIElement, greaterThan threshold: CGFloat, timeout: TimeInterval) {
        let frame = waitForStableFrame(of: element, timeout: timeout) { $0.minY > threshold }
        XCTAssertNotNil(frame, "Expected a stable frame below \(threshold): \(element)")
    }

    func waitForFrameMaxY(of element: XCUIElement, lessThan threshold: CGFloat, timeout: TimeInterval) {
        let frame = waitForStableFrame(of: element, timeout: timeout) { $0.maxY < threshold }
        XCTAssertNotNil(frame, "Expected a stable frame above \(threshold): \(element)")
    }

    func waitForFrameToSettle(_ element: XCUIElement, timeout: TimeInterval) {
        _ = waitForStableFrame(of: element, timeout: timeout) { _ in true }
    }

    func waitForRenderedCandidate(
        matching element: XCUIElement,
        in container: XCUIElement,
        timeout: TimeInterval,
        requiresHittable: Bool = false,
        requiresFullContainment: Bool = false
    ) -> XCUIElement? {
        let deadline = Date().addingTimeInterval(timeout)

        repeat {
            if container.exists, element.exists {
                let frame = element.frame
                let containerFrame = container.frame
                let meetsVisibilityRequirement = if requiresFullContainment {
                    containerFrame.insetBy(dx: -1, dy: -1).contains(frame)
                } else {
                    isMeaningfullyVisible(frame, in: containerFrame)
                }

                if !frame.isEmpty,
                   !frame.isNull,
                   meetsVisibilityRequirement,
                   !requiresHittable || element.isHittable {
                    return element
                }
            }

            guard Date() < deadline else { break }
            RunLoop.current.run(until: Date().addingTimeInterval(0.05))
        } while true

        return nil
    }

    func addVisibilityFailureDiagnostics(for element: XCUIElement, in container: XCUIElement) {
        let screenshot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        screenshot.name = "Visibility assertion failure"
        screenshot.lifetime = .keepAlways
        add(screenshot)

        let details = XCTAttachment(string: "Element: \(element)\nContainer: \(container)")
        details.name = "Visibility assertion targets"
        details.lifetime = .keepAlways
        add(details)
    }

    func waitForStableFrame(
        of element: XCUIElement,
        timeout: TimeInterval,
        condition: (CGRect) -> Bool
    ) -> CGRect? {
        let deadline = Date().addingTimeInterval(timeout)
        var previousFrame: CGRect?
        var stableSampleCount = 0

        repeat {
            if element.exists {
                let frame = element.frame
                if !frame.isEmpty, !frame.isNull, condition(frame) {
                    if let previousFrame, framesAreStable(previousFrame, frame) {
                        stableSampleCount += 1
                    } else {
                        stableSampleCount = 1
                    }
                    previousFrame = frame
                    if stableSampleCount >= 2 {
                        return frame
                    }
                } else {
                    previousFrame = nil
                    stableSampleCount = 0
                }
            } else {
                previousFrame = nil
                stableSampleCount = 0
            }

            guard Date() < deadline else { break }
            RunLoop.current.run(until: Date().addingTimeInterval(0.05))
        } while true

        return nil
    }

    func isMeaningfullyVisible(_ frame: CGRect, in containerFrame: CGRect) -> Bool {
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

    func framesAreStable(_ lhs: CGRect, _ rhs: CGRect) -> Bool {
        abs(lhs.minX - rhs.minX) <= 1
            && abs(lhs.minY - rhs.minY) <= 1
            && abs(lhs.width - rhs.width) <= 1
            && abs(lhs.height - rhs.height) <= 1
    }

    func edgeSwipeBack() {
        let start = app.coordinate(withNormalizedOffset: CGVector(dx: 0, dy: 0.5))
        let end = app.coordinate(withNormalizedOffset: CGVector(dx: 0.75, dy: 0.5))
        start.press(
            forDuration: 0.1,
            thenDragTo: end,
            withVelocity: .slow,
            thenHoldForDuration: 0.1
        )
    }

}
