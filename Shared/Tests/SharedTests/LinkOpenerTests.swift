//
//  LinkOpenerTests.swift
//  SharedTests
//
//  Copyright © 2025 Weiran Zhang. All rights reserved.
//

@testable import Domain
import SafariServices
@testable import Shared
import Testing
import UIKit

@Suite("LinkOpener Behaviour")
struct LinkOpenerTests {
    @MainActor
    @Test("System browser preference forwards URL to opener")
    func prefersSystemBrowser() {
        let settings = StubSettingsUseCase(openInDefaultBrowser: true)
        var openedURLs: [URL] = []

        LinkOpener.setEnvironmentForTesting(
            settings: { settings },
            openURL: { url in openedURLs.append(url) },
            presenter: { StubPresenter() },
            presentSafari: { _, _ in Issue.record("Should not present Safari when system browser preferred") }
        )

        let url = URL(string: "https://example.com")!
        LinkOpener.openURL(url)

        #expect(openedURLs == [url])
        LinkOpener.resetEnvironment()
    }

    @MainActor
    @Test("In-app browser presents Safari with reader mode setting")
    func presentsSafariViewController() {
        let settings = StubSettingsUseCase(safariReaderMode: true, openInDefaultBrowser: false)
        var capturedPresented: (UIViewController, SFSafariViewController)?

        LinkOpener.setEnvironmentForTesting(
            settings: { settings },
            openURL: { _ in Issue.record("Should not open system browser when presenter exists") },
            presenter: { StubPresenter() },
            presentSafari: { presenter, safari in
                capturedPresented = (presenter, safari)
            }
        )

        let url = URL(string: "https://news.ycombinator.com")!
        LinkOpener.openURL(url)

        guard let (_, safariController) = capturedPresented else {
            Issue.record("Expected Safari to be presented")
            return
        }

        #expect(safariController.initialURL == url)
        #expect(safariController.resolvedConfiguration.entersReaderIfAvailable)
        LinkOpener.resetEnvironment()
    }

    @MainActor
    @Test("Missing presenter falls back to system opener")
    func missingPresenterFallsBack() {
        let settings = StubSettingsUseCase(openInDefaultBrowser: false)
        var openedURLs: [URL] = []

        LinkOpener.setEnvironmentForTesting(
            settings: { settings },
            openURL: { url in openedURLs.append(url) },
            presenter: { nil },
            presentSafari: { _, _ in Issue.record("Should not present without presenter") }
        )

        let url = URL(string: "https://example.com")!
        LinkOpener.openURL(url)

        #expect(openedURLs == [url])
        LinkOpener.resetEnvironment()
    }

    @MainActor
    @Test("Non-web schemes always use system opener")
    func nonWebSchemesUseSystemOpener() {
        let settings = StubSettingsUseCase(openInDefaultBrowser: false)
        var openedURLs: [URL] = []

        LinkOpener.setEnvironmentForTesting(
            settings: { settings },
            openURL: { url in openedURLs.append(url) },
            presenter: { StubPresenter() },
            presentSafari: { _, _ in Issue.record("Non-web URLs should not present Safari") }
        )

        let telURL = URL(string: "tel:+123456789")!
        LinkOpener.openURL(telURL)

        #expect(openedURLs == [telURL])
        LinkOpener.resetEnvironment()
    }
}

// MARK: - Test Support

private final class StubSettingsUseCase: SettingsUseCase, @unchecked Sendable {
    var safariReaderMode: Bool
    var openInDefaultBrowser: Bool
    var textSize: TextSize

    init(safariReaderMode: Bool = false, openInDefaultBrowser: Bool = false, textSize: TextSize = .medium) {
        self.safariReaderMode = safariReaderMode
        self.openInDefaultBrowser = openInDefaultBrowser
        self.textSize = textSize
    }

    func clearCache() {}
    func cacheUsageBytes() async -> Int64 { 0 }
}

private final class StubPresenter: UIViewController {}

private extension SFSafariViewController {
    var initialURL: URL {
        // SFSafariViewController exposes the initial URL through private API, but we can rely on the
        // view controller's `value(forKey:)` for testing purposes in the test bundle.
        value(forKey: "URL") as? URL ?? URL(string: "about:blank")!
    }

    var resolvedConfiguration: SFSafariViewController.Configuration {
        (value(forKey: "configuration") as? SFSafariViewController.Configuration)
            ?? SFSafariViewController.Configuration()
    }
}
