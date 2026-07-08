//
//  EmbeddedWebView.swift
//  Hackers
//
//  Created by Codex on 2025-09-18.
//

import Domain
import Foundation
import Shared
import SwiftUI
import UIKit
import WebKit

@MainActor
final class BrowserController: ObservableObject {
    @Published var currentURL: URL?
    @Published var currentTitle: String?
    @Published var canGoBack = false
    @Published var canGoForward = false
    @Published var isLoading = false
    var fallbackURL: URL?
    let page: WebPage
    private var navigationTask: Task<Void, Never>?

    init() {
        var configuration = WebPage.Configuration()
        // Some app-shell sites gate rendering on Safari UA tokens; keep the browser identified as Mobile Safari.
        configuration.applicationNameForUserAgent = Self.safariApplicationNameForUserAgent
        page = WebPage(configuration: configuration)
        observePageNavigation()
        updateState()
    }

    func load(_ target: URL) {
        fallbackURL = target
        guard currentURL != target else { return }
        currentURL = target
        page.load(URLRequest(url: target))
        updateState()
    }

    func updateState() {
        let updatedURL = page.url ?? currentURL ?? fallbackURL
        currentURL = updatedURL
        currentTitle = page.title.isEmpty ? nil : page.title
        canGoBack = !page.backForwardList.backList.isEmpty
        canGoForward = !page.backForwardList.forwardList.isEmpty
        isLoading = page.isLoading
    }

    func reload() {
        page.reload()
        updateState()
    }

    func stopLoading() {
        page.stopLoading()
        updateState()
    }

    func goBack() {
        guard let item = page.backForwardList.backList.last else { return }
        page.load(item)
        updateState()
    }

    func goForward() {
        guard let item = page.backForwardList.forwardList.first else { return }
        page.load(item)
        updateState()
    }

    func showFixture(url: URL, title: String) {
        fallbackURL = url
        currentURL = url
        currentTitle = title
        canGoBack = false
        canGoForward = false
        isLoading = false
    }

    private func observePageNavigation() {
        navigationTask = Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                for try await _ in page.navigations {
                    updateState()
                }
            } catch {
                updateState()
            }
        }
    }

    private static var safariApplicationNameForUserAgent: String {
        "Version/\(UIDevice.current.systemVersion) Mobile/15E148 Safari/604.1"
    }

    deinit {
        navigationTask?.cancel()
    }
}

enum WebViewAnimations {
    static let standard = Animation.easeInOut(duration: 0.25)
    static let fast = Animation.easeInOut(duration: 0.2)
    static let panelDuration: TimeInterval = 0.30
    static let panel = Animation.timingCurve(0.22, 1.0, 0.36, 1.0, duration: panelDuration)
    static let revealDelay: TimeInterval = 0.15
}

struct EmbeddedWebView: View {
    let url: URL
    let onDismiss: @MainActor () -> Void
    let showsCloseButton: Bool
    let showsToolbar: Bool
    let bottomWebViewInset: CGFloat
    let obscuredBottomInset: CGFloat
    @StateObject private var controller: BrowserController

    init(
        url: URL,
        onDismiss: @MainActor @escaping () -> Void,
        showsCloseButton: Bool,
        showsToolbar: Bool = true,
        bottomWebViewInset: CGFloat = 0,
        obscuredBottomInset: CGFloat = 0,
        controller: BrowserController? = nil
    ) {
        self.url = url
        self.onDismiss = onDismiss
        self.showsCloseButton = showsCloseButton
        self.showsToolbar = showsToolbar
        self.bottomWebViewInset = bottomWebViewInset
        self.obscuredBottomInset = obscuredBottomInset
        _controller = StateObject(wrappedValue: controller ?? BrowserController())
    }

    var body: some View {
        GeometryReader { proxy in
            content
                .frame(
                    width: proxy.size.width,
                    height: max(proxy.size.height - bottomPanelInsetHeight, 0),
                    alignment: .top
                )
                .frame(width: proxy.size.width, height: proxy.size.height, alignment: .top)
        }
        .toolbar {
            if showsToolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    shareButton
                }
                ToolbarItem(placement: .topBarTrailing) {
                    openInSafariButton
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if showsCloseButton {
                        closeButton
                    }
                }
                if isPadLayout {
                    ToolbarItemGroup(placement: .bottomBar) {
                        Button {
                            controller.goBack()
                        } label: {
                            Image(systemName: "chevron.backward")
                        }
                        .accessibilityLabel("Back")
                        .disabled(!controller.canGoBack)

                        Button {
                            controller.goForward()
                        } label: {
                            Image(systemName: "chevron.forward")
                        }
                        .accessibilityLabel("Forward")
                        .disabled(!controller.canGoForward)

                        reloadButton
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        #if DEBUG
        if let article = UITestArticleFixtures.article(for: url) {
            UITestArticleView(article: article)
                .accessibilityIdentifier("browser.mockArticle")
                .onAppear {
                    controller.showFixture(url: url, title: article.title)
                }
        } else {
            webView
        }
        #else
        webView
        #endif
    }

    private var webView: some View {
        WebView(controller.page)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                Color.clear
                    .frame(height: max(obscuredBottomInset, 0))
                    .allowsHitTesting(false)
            }
            .task(id: url) {
                await Task.yield()
                controller.load(url)
            }
    }

    private var isPadLayout: Bool {
        #if targetEnvironment(macCatalyst)
            return true
        #else
            return UIDevice.current.userInterfaceIdiom == .pad || ProcessInfo.processInfo.isiOSAppOnMac
        #endif
    }

    private var bottomPanelInsetHeight: CGFloat {
        guard !showsToolbar else { return 0 }
        return bottomWebViewInset
    }

    private var shareButton: some View {
        Button {
            Task { @MainActor in
                let targetURL = controller.currentURL ?? url
                ContentSharePresenter.shared.shareURL(targetURL, title: controller.currentTitle)
            }
        } label: {
            Image(systemName: "square.and.arrow.up")
        }
        .accessibilityLabel("Share")
    }

    private var openInSafariButton: some View {
        Button {
            Task { @MainActor in
                let targetURL = controller.currentURL ?? url
                LinkOpener.openInSystemBrowser(targetURL)
            }
        } label: {
            Image(systemName: "safari")
        }
        .accessibilityLabel("Open in Safari")
    }

    private var closeButton: some View {
        Button {
            Task { @MainActor in onDismiss() }
        } label: {
            Image(systemName: "xmark")
        }
        .accessibilityLabel("Close")
    }

    private var reloadButton: some View {
        Button {
            if controller.isLoading {
                controller.stopLoading()
            } else {
                controller.reload()
            }
        } label: {
            Image(systemName: controller.isLoading ? "xmark" : "arrow.clockwise")
        }
        .accessibilityLabel(controller.isLoading ? "Stop" : "Reload")
    }

}

#if DEBUG
private struct UITestArticleView: View {
    let article: UITestArticleContent

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(article.title)
                    .font(.title2)
                    .bold()
                Text(article.body)
                    .font(.body)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
        }
    }
}
#endif

struct PostLinkBrowserView: View {
    @Environment(\.dismiss) private var dismiss
    let post: Post
    let presentation: PostLinkPresentation
    @State private var showingCommentsPane = false
    @State private var collapsedCommentsHeight = PostCommentsSheet.initialCollapsedHeight
    @State private var browserObscuredBottomInset = PostCommentsSheet.defaultCollapsedBrowserObscuredBottomInset
    @StateObject private var browserController = BrowserController()

    init(post: Post, presentation: PostLinkPresentation) {
        self.post = post
        self.presentation = presentation
        _showingCommentsPane = State(initialValue: presentation == .expandedComments)
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            EmbeddedWebView(
                url: post.url,
                onDismiss: { dismiss() },
                showsCloseButton: false,
                showsToolbar: false,
                bottomWebViewInset: browserBottomInset,
                obscuredBottomInset: browserObscuredBottomInset,
                controller: browserController
            )

            if showingCommentsPane {
                PostCommentsSheet(
                    post: post,
                    controller: browserController,
                    initialPresentation: presentation,
                    onDismiss: { dismiss() },
                    onCollapsedHeightChange: { collapsedCommentsHeight = $0 },
                    onBrowserObscuredBottomInsetChange: { browserObscuredBottomInset = $0 }
                )
                .transition(.move(edge: .bottom))
            }
        }
        .tint(.accentColor)
        .accessibilityIdentifier("browser.view")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            guard !showingCommentsPane else { return }
            withAnimation(WebViewAnimations.panel) {
                showingCommentsPane = true
            }
        }
    }

    private var browserBottomInset: CGFloat {
        max(collapsedCommentsHeight - PostCommentsSheet.collapsedTopCornerRadius, 0)
    }
}
