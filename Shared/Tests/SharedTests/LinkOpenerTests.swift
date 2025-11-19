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
        var capturedFactoryInput: (URL, SFSafariViewController.Configuration)?
        var stubSafari: StubSafariViewController?

        LinkOpener.setEnvironmentForTesting(
            settings: { settings },
            openURL: { _ in Issue.record("Should not open system browser when presenter exists") },
            presenter: { StubPresenter() },
            presentSafari: { presenter, safari in
                capturedPresented = (presenter, safari)
            },
            safariControllerFactory: { url, configuration in
                capturedFactoryInput = (url, configuration)
                let controller = StubSafariViewController(url: url, configuration: configuration)
                stubSafari = controller
                return controller
            }
        )

        defer { LinkOpener.resetEnvironment() }

        let url = URL(string: "https://news.ycombinator.com")!
        LinkOpener.openURL(url)

        guard let factoryInput = capturedFactoryInput else {
            Issue.record("Expected safariControllerFactory to be invoked")
            return
        }

        #expect(factoryInput.0 == url)
        #expect(factoryInput.1.entersReaderIfAvailable)

        guard let (presenter, safariController) = capturedPresented else {
            Issue.record("Expected Safari to be presented")
            return
        }

        #expect(presenter is StubPresenter)
        #expect(safariController === stubSafari)
        #expect(stubSafari?.capturedURL == url)
        #expect(stubSafari?.capturedConfiguration.entersReaderIfAvailable == true)
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
    var showThumbnails: Bool = true
    var rememberFeedCategory: Bool = false
    var lastFeedCategory: PostType?
    var textSize: TextSize
    var compactFeedDesign: Bool = false

    init(safariReaderMode: Bool = false, openInDefaultBrowser: Bool = false, textSize: TextSize = .medium) {
        self.safariReaderMode = safariReaderMode
        self.openInDefaultBrowser = openInDefaultBrowser
        self.textSize = textSize
    }

    func clearCache() {}
    func cacheUsageBytes() async -> Int64 { 0 }
}

private final class StubPresenter: UIViewController {}

private final class StubSafariViewController: SFSafariViewController {
    let capturedURL: URL
    let capturedConfiguration: SFSafariViewController.Configuration

    override init(url: URL, configuration: SFSafariViewController.Configuration) {
        capturedURL = url
        capturedConfiguration = configuration
        super.init(url: url, configuration: configuration)
    }

    @available(*, unavailable)
    override required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
