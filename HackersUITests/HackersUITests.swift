import Domain
import Shared
import XCTest

@MainActor
final class FeedAndSettingsUITests: HackersUITestCase {
    func testSmokeLaunchFeedAndSettings() throws {
        launchApp()

        let feed = app.collectionViews[AccessibilityIdentifier.Feed.list]
        assertFullyContained(feed, in: app, timeout: 8)
        assertHasVisibleIntersection(app.staticTexts["Swift 6.2 Released"], in: feed)
        assertHasVisibleIntersection(app.staticTexts["Cloudflare Turnstile requiring fingerprintable WebGL"], in: feed)
        assertHasVisibleIntersection(
            app.staticTexts["United Airlines 767 returns to Newark after Bluetooth name sparks alert"],
            in: feed
        )

        let settingsButton = assertHittable(app.buttons[AccessibilityIdentifier.Feed.settingsButton])
        settingsButton.tap()

        let settingsForm = app.collectionViews[AccessibilityIdentifier.Settings.form]
        assertFullyContained(settingsForm, in: app)
        assertHasVisibleIntersection(app.staticTexts["Settings"], in: app)
        assertHittable(app.switches[AccessibilityIdentifier.Settings.showThumbnails])
        assertHittable(app.switches[AccessibilityIdentifier.Settings.compactFeed])
        assertHasVisibleIntersection(
            app.staticTexts.containing(NSPredicate(format: "label BEGINSWITH %@", "Version")).firstMatch,
            in: settingsForm
        )
    }

    func testSmokeOpenCustomBrowserFromFeed() throws {
        launchApp(linkBrowserMode: .customBrowser)

        let post = assertHittable(app.buttons[AccessibilityIdentifier.Feed.post(screenshotPostID)], timeout: 8)
        tapPost(post)

        let browser = assertFullyContained(browserView, in: app)
        assertFixtureArticleLoaded()
        let titlePill = assertFullyContained(expandedCommentsTitle, in: app)
        XCTAssertLessThan(titlePill.frame.width, app.frame.width - 176)

        collapseCommentsByTappingTitle()
        assertHasVisibleIntersection(
            app.staticTexts["Fixture article loaded from the UI-test Hacker News Active snapshot."],
            in: browser
        )
    }

    func testSearchUsesMockedAlgoliaResults() throws {
        launchApp()

        assertFullyContained(app.collectionViews[AccessibilityIdentifier.Feed.list], in: app, timeout: 8)
        let searchButton = assertHittable(app.buttons["Search"])
        searchButton.tap()

        let searchField = assertHittable(app.searchFields.firstMatch)
        searchField.tap()
        searchField.typeText("Migration Guide")

        let searchResults = app.collectionViews[AccessibilityIdentifier.Feed.searchResults]
        assertFullyContained(searchResults, in: app, timeout: 8)
        let migrationResult = assertHasVisibleIntersection(
            app.buttons[AccessibilityIdentifier.Feed.post(searchOnlyPostID)],
            in: searchResults
        )
        assertHasVisibleIntersection(app.staticTexts["Swift 6.2 Migration Guide"], in: searchResults)
        assertAbsent(app.staticTexts["Searching..."])
        assertAbsent(app.staticTexts["United Airlines 767 returns to Newark after Bluetooth name sparks alert"])

        tapPost(migrationResult)
        let browser = assertFullyContained(browserView, in: app, timeout: 8)
        XCTAssertTrue(
            browser.staticTexts["Swift 6.2 Migration Guide"].waitForExistence(timeout: 8),
            "Expected the exact article fixture for the search-only post to load"
        )
        collapseCommentsByTappingTitle()
        assertHasVisibleIntersection(app.staticTexts["Swift 6.2 Migration Guide"], in: browser)
    }

    func testCategoryMenuUsesMockedFeeds() throws {
        launchApp()

        assertFullyContained(app.collectionViews[AccessibilityIdentifier.Feed.list], in: app, timeout: 8)
        let categoryMenu = assertHittable(app.navigationBars.buttons["Top"])
        categoryMenu.tap()
        let askButton = assertHittable(app.buttons["Ask"])
        askButton.tap()

        assertHasVisibleIntersection(
            app.staticTexts["Ask HN: What are you using for iOS UI testing in 2026?"],
            in: app
        )
        let askPost = assertHittable(app.buttons[AccessibilityIdentifier.Feed.post(UITestFixtureReference.askPostID)])
        tapPost(askPost)
        let comments = assertFullyContained(commentsList, in: app, timeout: 8)
        assertHasVisibleIntersection(
            app.staticTexts["Ask HN: What are you using for iOS UI testing in 2026?"],
            in: comments
        )
    }

    func testLoginFailureAndSuccessUseMockedAuthentication() throws {
        launchApp()

        assertFullyContained(app.collectionViews[AccessibilityIdentifier.Feed.list], in: app, timeout: 8)
        let settingsButton = assertHittable(app.buttons[AccessibilityIdentifier.Feed.settingsButton])
        settingsButton.tap()
        assertFullyContained(app.collectionViews[AccessibilityIdentifier.Settings.form], in: app)
        let loginButton = assertHittable(app.buttons["Login"])
        loginButton.tap()

        let username = assertHittable(app.textFields[AccessibilityIdentifier.Login.username])
        let password = assertHittable(app.secureTextFields[AccessibilityIdentifier.Login.password])
        username.tap()
        username.typeText("ui-user")
        password.tap()
        password.typeText("wrong")
        assertHittable(app.buttons[AccessibilityIdentifier.Login.signIn]).tap()
        let loginFailure = assertFullyContained(app.alerts["Login Failed"], in: app)
        assertHittable(loginFailure.buttons["OK"]).tap()

        password.tap()
        password.typeText("password")
        assertHittable(app.buttons[AccessibilityIdentifier.Login.signIn]).tap()

        assertHasVisibleIntersection(app.staticTexts["Logged in as ui-user"], in: app)
    }
}
