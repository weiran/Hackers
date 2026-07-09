//
//  EmbeddedWebView.swift
//  Hackers
//
//  Created by Codex on 2025-09-18.
//

import DesignSystem
import Domain
import Foundation
import Shared
import SwiftUI
import UIKit
import WebKit

struct PageHeaderBlurTint: Equatable {
    let red: Double
    let green: Double
    let blue: Double
    let alpha: Double

    var color: Color {
        Color(red: red, green: green, blue: blue, opacity: alpha)
    }

    init?(_ uiColor: UIColor?) {
        guard let uiColor else { return nil }
        let resolvedColor = uiColor.resolvedColor(with: UITraitCollection.current)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        if resolvedColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha) {
            self.init(red: red, green: green, blue: blue, alpha: alpha)
            return
        }

        var white: CGFloat = 0
        if resolvedColor.getWhite(&white, alpha: &alpha) {
            self.init(red: white, green: white, blue: white, alpha: alpha)
            return
        }

        return nil
    }

    private init(red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) {
        self.red = Self.rounded(red)
        self.green = Self.rounded(green)
        self.blue = Self.rounded(blue)
        self.alpha = Self.rounded(alpha)
    }

    private static func rounded(_ value: CGFloat) -> Double {
        (Double(value) * 1000).rounded() / 1000
    }
}

@MainActor
final class BrowserController: ObservableObject {
    @Published var currentURL: URL?
    @Published var currentTitle: String?
    @Published var canGoBack = false
    @Published var canGoForward = false
    @Published var isLoading = false
    @Published private(set) var pageHeaderBlurTint: PageHeaderBlurTint?
    var fallbackURL: URL?
    let webView: WKWebView
    private var navigationDelegate: BrowserNavigationDelegate?
    private var observations: [NSKeyValueObservation] = []
    private var pageHeaderBlurTintURL: URL?

    init() {
        let configuration = WKWebViewConfiguration()
        // Some app-shell sites gate rendering on Safari UA tokens; keep the browser identified as Mobile Safari.
        configuration.applicationNameForUserAgent = Self.safariApplicationNameForUserAgent
        webView = WKWebView(frame: .zero, configuration: configuration)

        let navigationDelegate = BrowserNavigationDelegate(controller: self)
        self.navigationDelegate = navigationDelegate
        webView.navigationDelegate = navigationDelegate
        installStateObservers()
        updateState()
    }

    func load(_ target: URL) {
        fallbackURL = target
        guard currentURL != target else { return }
        currentURL = target
        webView.load(URLRequest(url: target))
        updateState()
    }

    func updateState() {
        let updatedURL = webView.url ?? currentURL ?? fallbackURL
        if pageHeaderBlurTintURL != updatedURL {
            pageHeaderBlurTint = nil
            pageHeaderBlurTintURL = nil
        }
        currentURL = updatedURL
        currentTitle = webView.title
        canGoBack = webView.canGoBack
        canGoForward = webView.canGoForward
        isLoading = webView.isLoading
    }

    func reload() {
        resetHeaderBlurTint()
        webView.reload()
        updateState()
    }

    func stopLoading() {
        webView.stopLoading()
        updateState()
    }

    func goBack() {
        guard webView.canGoBack else { return }
        resetHeaderBlurTint()
        webView.goBack()
        updateState()
    }

    func goForward() {
        guard webView.canGoForward else { return }
        resetHeaderBlurTint()
        webView.goForward()
        updateState()
    }

    func applyBottomChromeInset(_ bottomInset: CGFloat) {
        let inset = max(bottomInset, 0)
        applyObscuredBottomInset(inset)
        applyScrollViewBottomInset(inset)
    }

    private func applyObscuredBottomInset(_ inset: CGFloat) {
        guard abs(webView.obscuredContentInsets.bottom - inset) > 0.5 else { return }

        var obscuredContentInsets = webView.obscuredContentInsets
        obscuredContentInsets.bottom = inset
        webView.obscuredContentInsets = obscuredContentInsets
    }

    private func applyScrollViewBottomInset(_ bottomInset: CGFloat) {
        let scrollView = webView.scrollView
        let automaticBottomInset = max(
            scrollView.adjustedContentInset.bottom - scrollView.contentInset.bottom,
            0
        )
        let inset = max(bottomInset - automaticBottomInset, 0)

        if abs(scrollView.contentInset.bottom - inset) > 0.5 {
            var contentInset = scrollView.contentInset
            contentInset.bottom = inset
            scrollView.contentInset = contentInset
        }

        if abs(scrollView.verticalScrollIndicatorInsets.bottom - inset) > 0.5 {
            var indicatorInsets = scrollView.verticalScrollIndicatorInsets
            indicatorInsets.bottom = inset
            scrollView.verticalScrollIndicatorInsets = indicatorInsets
        }
    }

    private func resetHeaderBlurTint() {
        pageHeaderBlurTint = nil
        pageHeaderBlurTintURL = nil
    }

    private func installStateObservers() {
        observations = [
            webView.observe(\.url, options: [.new]) { [weak self] _, _ in
                Task { @MainActor [weak self] in self?.updateState() }
            },
            webView.observe(\.title, options: [.new]) { [weak self] _, _ in
                Task { @MainActor [weak self] in self?.updateState() }
            },
            webView.observe(\.canGoBack, options: [.new]) { [weak self] _, _ in
                Task { @MainActor [weak self] in self?.updateState() }
            },
            webView.observe(\.canGoForward, options: [.new]) { [weak self] _, _ in
                Task { @MainActor [weak self] in self?.updateState() }
            },
            webView.observe(\.isLoading, options: [.new]) { [weak self] _, _ in
                Task { @MainActor [weak self] in self?.updateState() }
            },
            webView.observe(\.underPageBackgroundColor, options: [.initial, .new]) { [weak self] _, _ in
                Task { @MainActor [weak self] in self?.updateHeaderTintFromPageBackground() }
            }
        ]
    }

    func updateHeaderTintFromPageBackground() {
        guard let updatedTint = PageHeaderBlurTint(webView.underPageBackgroundColor) else { return }
        if pageHeaderBlurTint != updatedTint {
            pageHeaderBlurTint = updatedTint
        }
        pageHeaderBlurTintURL = currentURL
    }

    private static var safariApplicationNameForUserAgent: String {
        "Version/\(UIDevice.current.systemVersion) Mobile/15E148 Safari/604.1"
    }
}

private final class BrowserNavigationDelegate: NSObject, WKNavigationDelegate {
    weak var controller: BrowserController?

    init(controller: BrowserController) {
        self.controller = controller
    }

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        updateState()
    }

    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        updateState()
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        updateState(refreshesHeaderTint: true)
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        updateState()
    }

    func webView(
        _ webView: WKWebView,
        didFailProvisionalNavigation navigation: WKNavigation!,
        withError error: Error
    ) {
        updateState()
    }

    private func updateState(refreshesHeaderTint: Bool = false) {
        Task { @MainActor [weak controller] in
            controller?.updateState()
            if refreshesHeaderTint {
                controller?.updateHeaderTintFromPageBackground()
            }
        }
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
    private static let statusBarBlurFadeExtension: CGFloat = 0

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
                .overlay(alignment: .top) {
                    headerBlur
                }
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
        .toolbarBackground(.hidden, for: .navigationBar)
    }

    private var headerBlur: some View {
        GeometryReader { proxy in
            ProgressiveHeaderBlurBackground(
                height: proxy.safeAreaInsets.top,
                fadeExtension: Self.statusBarBlurFadeExtension,
                tintMiddleLocation: 0.45,
                tint: controller.pageHeaderBlurTint?.color
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .animation(.easeInOut(duration: 0.2), value: controller.pageHeaderBlurTint)
        .allowsHitTesting(false)
    }

    @ViewBuilder
    private var content: some View {
        #if DEBUG
        if let article = UITestArticleFixtures.article(for: url) {
            UITestArticleView(article: article)
                .accessibilityIdentifier("browser.mockArticle")
        } else {
            webView
        }
        #else
        webView
        #endif
    }

    private var webView: some View {
        BrowserWebView(
            controller: controller,
            url: url,
            obscuredBottomInset: obscuredBottomInset
        )
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

private struct BrowserWebView: UIViewRepresentable {
    let controller: BrowserController
    let url: URL
    let obscuredBottomInset: CGFloat

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> WKWebView {
        context.coordinator.requestedURL = url
        controller.applyBottomChromeInset(obscuredBottomInset)
        context.coordinator.scheduleLoad(controller: controller, url: url)
        return controller.webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        controller.applyBottomChromeInset(obscuredBottomInset)
        guard context.coordinator.requestedURL != url else { return }
        context.coordinator.requestedURL = url
        context.coordinator.scheduleLoad(controller: controller, url: url)
    }

    @MainActor
    final class Coordinator {
        var requestedURL: URL?
        private var loadTask: Task<Void, Never>?

        func scheduleLoad(controller: BrowserController, url: URL) {
            loadTask?.cancel()
            loadTask = Task { @MainActor [weak controller] in
                await Task.yield()
                guard !Task.isCancelled else { return }
                controller?.load(url)
            }
        }

        deinit {
            loadTask?.cancel()
        }
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
        .toolbarBackground(.hidden, for: .navigationBar)
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
