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

@MainActor
final class BrowserController: ObservableObject {
    @Published var currentURL: URL?
    @Published var currentTitle: String?
    @Published var canGoBack = false
    @Published var canGoForward = false
    @Published var isLoading = false
    var fallbackURL: URL?
    let webView: WKWebView
    private var navigationDelegate: BrowserNavigationDelegate?
    private var observations: [NSKeyValueObservation] = []
    private var reloadOverride: (() -> Void)?
    private var mediaPlaybackSuspended = false
    private var requestedMediaPlaybackSuspension = false
    private var mediaPlaybackSuspensionUpdateInFlight = false
    private var pendingMediaPlaybackAction: (() -> Void)?

    init(mediaPlaybackSuspended: Bool = false) {
        requestedMediaPlaybackSuspension = mediaPlaybackSuspended
        let configuration = WKWebViewConfiguration()
        // Some app-shell sites gate rendering on Safari UA tokens; keep the browser identified as Mobile Safari.
        configuration.applicationNameForUserAgent = Self.safariApplicationNameForUserAgent
        #if DEBUG
        if UITestingBootstrap.configuration?.mediaPlayback == .autoplayFixture {
            configuration.mediaTypesRequiringUserActionForPlayback = []
            configuration.allowsInlineMediaPlayback = true
        }
        #endif
        webView = WKWebView(frame: .zero, configuration: configuration)
        webView.scrollView.topEdgeEffect.isHidden = true

        let navigationDelegate = BrowserNavigationDelegate(controller: self)
        self.navigationDelegate = navigationDelegate
        webView.navigationDelegate = navigationDelegate
        installStateObservers()
        updateState()
        applyMediaPlaybackSuspensionIfNeeded()
    }

    func load(_ target: URL) {
        reloadOverride = nil
        fallbackURL = target
        guard currentURL != target else { return }
        currentURL = target
        enqueueMediaPlaybackAction { [weak self] in
            guard let self else { return }
            self.webView.load(URLRequest(url: target))
            self.updateState()
        }
    }

    func loadHTMLString(_ html: String, baseURL: URL?) {
        enqueueMediaPlaybackAction { [weak self] in
            guard let self else { return }
            self.webView.loadHTMLString(html, baseURL: baseURL)
            self.updateState()
        }
    }

    func setMediaPlaybackSuspended(_ suspended: Bool) {
        requestedMediaPlaybackSuspension = suspended
        applyMediaPlaybackSuspensionIfNeeded()
    }

    func updateState() {
        let updatedURL = webView.url ?? currentURL ?? fallbackURL
        currentURL = updatedURL
        currentTitle = webView.title
        canGoBack = webView.canGoBack
        canGoForward = webView.canGoForward
        isLoading = webView.isLoading
    }

    func reload() {
        if let reloadOverride {
            reloadOverride()
        } else {
            webView.reload()
        }
        updateState()
    }

    func setReloadOverride(_ action: (() -> Void)?) {
        reloadOverride = action
    }

    func stopLoading() {
        webView.stopLoading()
        updateState()
    }

    func goBack() {
        guard webView.canGoBack else { return }
        webView.goBack()
        updateState()
    }

    func goForward() {
        guard webView.canGoForward else { return }
        webView.goForward()
        updateState()
    }

    private func enqueueMediaPlaybackAction(_ action: @escaping () -> Void) {
        pendingMediaPlaybackAction = action
        applyMediaPlaybackSuspensionIfNeeded()
    }

    private func applyMediaPlaybackSuspensionIfNeeded() {
        guard !mediaPlaybackSuspensionUpdateInFlight else { return }

        guard requestedMediaPlaybackSuspension != mediaPlaybackSuspended else {
            flushPendingMediaPlaybackActionIfReady()
            return
        }

        let targetSuspension = requestedMediaPlaybackSuspension
        mediaPlaybackSuspensionUpdateInFlight = true
        webView.setAllMediaPlaybackSuspended(targetSuspension) { [weak self] in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.mediaPlaybackSuspended = targetSuspension
                self.mediaPlaybackSuspensionUpdateInFlight = false
                self.applyMediaPlaybackSuspensionIfNeeded()
            }
        }
    }

    private func flushPendingMediaPlaybackActionIfReady() {
        guard !mediaPlaybackSuspensionUpdateInFlight,
              requestedMediaPlaybackSuspension == mediaPlaybackSuspended,
              let action = pendingMediaPlaybackAction else { return }
        pendingMediaPlaybackAction = nil
        action()
    }

    func applyBottomChromeInset(_ bottomInset: CGFloat) {
        let inset = max(bottomInset, 0)
        applyObscuredBottomInset(inset)
        applyScrollViewBottomInset(inset)
        // Safe-area insets only settle once the view is in the window and
        // laid out, so re-apply after this update pass.
        DispatchQueue.main.async { [weak self] in
            self?.applyStatusBarObscuredInset()
        }
    }

    /// The status-bar blur strip covers the top of the full-bleed web view;
    /// tell WebKit so sticky and fixed page elements rest below the strip
    /// instead of under the status indicators, as in Safari.
    private func applyStatusBarObscuredInset() {
        guard !DeviceLayout.usesPadLayout else { return }
        let topInset = webView.safeAreaInsets.top
        guard abs(webView.obscuredContentInsets.top - topInset) > 0.5 else { return }

        var obscuredContentInsets = webView.obscuredContentInsets
        obscuredContentInsets.top = topInset
        webView.obscuredContentInsets = obscuredContentInsets
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
            }
        ]
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
        updateState()
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

    private func updateState() {
        Task { @MainActor [weak controller] in
            controller?.updateState()
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
    private static let headerBlurHeight: CGFloat = 48

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
                    if !isPadLayout {
                        headerBlur
                    }
                }
        }
        .ignoresSafeArea(edges: isPadLayout ? [.top, .bottom] : [])
        .toolbar {
            if showsToolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if controller.canGoBack {
                        backButton
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if controller.canGoForward {
                        forwardButton
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    reloadButton
                }
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
            }
        }
        .toolbarBackground(.hidden, for: .navigationBar)
    }

    private var headerBlur: some View {
        ProgressiveBlur()
            .frame(height: Self.headerBlurHeight)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .ignoresSafeArea(edges: .top)
            .allowsHitTesting(false)
    }

    @ViewBuilder
    private var content: some View {
        #if DEBUG
        if let configuration = UITestingBootstrap.configuration,
           configuration.articleSource == .fixture {
            if let article = UITestArticleFixtures.article(for: url) {
                UITestArticleView(
                    controller: controller,
                    url: url,
                    article: article,
                    obscuredBottomInset: obscuredBottomInset
                )
            } else {
                UITestMissingArticleView(url: url)
            }
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
        .ignoresSafeArea(edges: .top)
    }

    private var isPadLayout: Bool {
        DeviceLayout.usesPadLayout
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

    private var backButton: some View {
        Button {
            controller.goBack()
        } label: {
            Image(systemName: "chevron.backward")
        }
        .accessibilityLabel("Back")
    }

    private var forwardButton: some View {
        Button {
            controller.goForward()
        } label: {
            Image(systemName: "chevron.forward")
        }
        .accessibilityLabel("Forward")
    }

}

/// A thin system material masked by a vertical fade, giving a progressive
/// blur whose height we control directly (the system scroll edge effect
/// sizes its gradient from the safe area and cannot be shortened).
private struct ProgressiveBlur: View {
    var body: some View {
        Rectangle()
            .fill(.ultraThinMaterial)
            .mask(
                LinearGradient(
                    stops: [
                        .init(color: .black, location: 0),
                        .init(color: .black, location: 0.45),
                        .init(color: .clear, location: 1)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
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
        controller.setReloadOverride(nil)
        controller.applyBottomChromeInset(obscuredBottomInset)
        context.coordinator.scheduleLoad(controller: controller, url: url)
        return controller.webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        controller.setReloadOverride(nil)
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
private struct UITestArticleView: UIViewRepresentable {
    let controller: BrowserController
    let url: URL
    let article: UITestArticleContent
    let obscuredBottomInset: CGFloat

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> WKWebView {
        let webView = controller.webView
        controller.applyBottomChromeInset(obscuredBottomInset)
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        webView.accessibilityIdentifier = AccessibilityIdentifier.Browser.fixtureArticle
        let coordinator = context.coordinator
        coordinator.scheduleLoad { [self, weak coordinator] in
            guard let coordinator else { return }
            loadArticle(in: webView, coordinator: coordinator)
        }
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        controller.applyBottomChromeInset(obscuredBottomInset)
        guard context.coordinator.loadedArticle != article
            || context.coordinator.loadedURL != url else { return }
        let coordinator = context.coordinator
        coordinator.scheduleLoad { [self, weak coordinator] in
            guard let coordinator else { return }
            loadArticle(in: webView, coordinator: coordinator)
        }
    }

    private func loadArticle(in webView: WKWebView, coordinator: Coordinator) {
        coordinator.loadedArticle = article
        coordinator.loadedURL = url
        controller.fallbackURL = url
        controller.currentURL = url
        let html = html
        controller.setReloadOverride { [weak controller] in
            controller?.loadHTMLString(html, baseURL: url)
        }
        controller.loadHTMLString(html, baseURL: url)
        controller.updateState()
    }

    private var html: String {
        let resourceName = article.htmlResourceName ?? "ArticleFixture"
        guard let resourceURL = Bundle.main.url(forResource: resourceName, withExtension: "html"),
              let resourceHTML = try? String(contentsOf: resourceURL, encoding: .utf8) else {
            preconditionFailure("Missing UI-test article HTML resource: \(resourceName).html")
        }

        return resourceHTML
            .replacingOccurrences(of: "{{TITLE}}", with: escaped(article.title))
            .replacingOccurrences(of: "{{BODY}}", with: escaped(article.body))
    }

    private func escaped(_ value: String) -> String {
        value
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
    }

    @MainActor
    final class Coordinator {
        var loadedArticle: UITestArticleContent?
        var loadedURL: URL?
        private var loadTask: Task<Void, Never>?

        func scheduleLoad(operation: @escaping @MainActor () -> Void) {
            loadTask?.cancel()
            loadTask = Task { @MainActor in
                await Task.yield()
                guard !Task.isCancelled else { return }
                operation()
            }
        }

        deinit {
            loadTask?.cancel()
        }
    }
}

private struct UITestMissingArticleView: View {
    let url: URL

    var body: some View {
        ContentUnavailableView(
            "Missing UI-Test Article Fixture",
            systemImage: "exclamationmark.triangle",
            description: Text(url.absoluteString)
        )
        .accessibilityIdentifier(AccessibilityIdentifier.Browser.missingFixtureArticle)
        .accessibilityLabel("Missing UI-test article fixture")
        .accessibilityValue(url.absoluteString)
    }
}
#endif

@MainActor
private struct NavigationBackSwipeRestorer: UIViewControllerRepresentable {
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIViewController(context: Context) -> ProbeViewController {
        let viewController = ProbeViewController()
        viewController.view.backgroundColor = .clear
        viewController.view.isUserInteractionEnabled = false
        viewController.onLifecycle = { [weak coordinator = context.coordinator] viewController in
            coordinator?.installIfPossible(from: viewController)
        }
        return viewController
    }

    func updateUIViewController(_ viewController: ProbeViewController, context: Context) {
        viewController.onLifecycle = { [weak coordinator = context.coordinator] viewController in
            coordinator?.installIfPossible(from: viewController)
        }
        context.coordinator.installIfPossible(from: viewController)

        let coordinator = context.coordinator
        Task { @MainActor [weak viewController, weak coordinator] in
            guard let viewController else { return }
            coordinator?.installIfPossible(from: viewController)
        }
    }

    static func dismantleUIViewController(_ viewController: ProbeViewController, coordinator: Coordinator) {
        coordinator.restore()
        viewController.onLifecycle = nil
    }

    final class ProbeViewController: UIViewController {
        var onLifecycle: ((ProbeViewController) -> Void)?

        override func didMove(toParent parent: UIViewController?) {
            super.didMove(toParent: parent)
            onLifecycle?(self)
        }

        override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
            onLifecycle?(self)
        }

        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            onLifecycle?(self)
        }
    }

    @MainActor
    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        private weak var navigationController: UINavigationController?
        private weak var edgeGesture: UIGestureRecognizer?
        private weak var contentGesture: UIGestureRecognizer?
        private weak var originalEdgeDelegate: UIGestureRecognizerDelegate?
        private weak var originalContentDelegate: UIGestureRecognizerDelegate?

        func installIfPossible(from viewController: UIViewController) {
            guard let navigationController = viewController.nearestNavigationController else { return }
            install(on: navigationController)
        }

        private func install(on navigationController: UINavigationController) {
            self.navigationController = navigationController

            if let gesture = navigationController.interactivePopGestureRecognizer {
                if edgeGesture !== gesture {
                    edgeGesture = gesture
                    originalEdgeDelegate = gesture.delegate
                } else if gesture.delegate !== self {
                    originalEdgeDelegate = gesture.delegate
                }
                gesture.isEnabled = true
                gesture.delegate = self
            }

            if #available(iOS 26.0, *),
               let gesture = navigationController.interactiveContentPopGestureRecognizer {
                if contentGesture !== gesture {
                    contentGesture = gesture
                    originalContentDelegate = gesture.delegate
                } else if gesture.delegate !== self {
                    originalContentDelegate = gesture.delegate
                }
                gesture.isEnabled = true
                gesture.delegate = self
            }
        }

        func restore() {
            if edgeGesture?.delegate === self {
                edgeGesture?.delegate = originalEdgeDelegate
            }
            if #available(iOS 26.0, *),
               contentGesture?.delegate === self {
                contentGesture?.delegate = originalContentDelegate
            }
            edgeGesture = nil
            contentGesture = nil
            navigationController = nil
        }

        func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            guard isManagedPopGesture(gestureRecognizer) else { return true }
            guard let navigationController else { return false }
            guard navigationController.viewControllers.count > 1 else { return false }
            guard navigationController.transitionCoordinator == nil else { return false }

            if #available(iOS 26.0, *), gestureRecognizer === contentGesture {
                let location = gestureRecognizer.location(in: navigationController.view)
                return location.x <= systemPopStartMaxX(in: navigationController)
            }

            return true
        }

        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
            guard isManagedPopGesture(gestureRecognizer) else { return true }
            guard let navigationController else { return false }

            if #available(iOS 26.0, *), gestureRecognizer === contentGesture {
                let location = touch.location(in: navigationController.view)
                return location.x <= systemPopStartMaxX(in: navigationController)
            }

            return true
        }

        func gestureRecognizer(
            _ gestureRecognizer: UIGestureRecognizer,
            shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
        ) -> Bool {
            isManagedPopGesture(gestureRecognizer) || isManagedPopGesture(otherGestureRecognizer)
        }

        private func isManagedPopGesture(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            if gestureRecognizer === edgeGesture {
                return true
            }
            if #available(iOS 26.0, *), gestureRecognizer === contentGesture {
                return true
            }
            return false
        }

        private func systemPopStartMaxX(in navigationController: UINavigationController) -> CGFloat {
            navigationController.view.safeAreaInsets.left + 32
        }
    }
}

private extension UIViewController {
    var nearestNavigationController: UINavigationController? {
        if let navigationController {
            return navigationController
        }

        var current = parent
        while let viewController = current {
            if let navigationController = viewController as? UINavigationController {
                return navigationController
            }
            if let navigationController = viewController.navigationController {
                return navigationController
            }
            current = viewController.parent
        }

        return nil
    }
}

struct PostLinkBrowserView: View {
    @Environment(\.dismiss) private var dismiss
    let post: Post
    let presentation: PostLinkPresentation
    @State private var showingCommentsPane = false
    @State private var collapsedCommentsHeight = PostCommentsSheet.initialCollapsedHeight
    @State private var browserObscuredBottomInset = PostCommentsSheet.collapsedBrowserBottomInset
    @StateObject private var browserController: BrowserController

    init(post: Post, presentation: PostLinkPresentation) {
        self.post = post
        self.presentation = presentation
        _showingCommentsPane = State(initialValue: presentation == .expandedComments)
        _browserController = StateObject(wrappedValue: BrowserController(
            mediaPlaybackSuspended: presentation == .expandedComments
        ))
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
                    onBrowserObscuredBottomInsetChange: { browserObscuredBottomInset = $0 },
                    onMediaPlaybackSuspensionChange: { isSuspended in
                        browserController.setMediaPlaybackSuspended(isSuspended)
                    }
                )
                .transition(.move(edge: .bottom))
            }
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .tint(.accentColor)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(AccessibilityIdentifier.Browser.view)
        .navigationBarTitleDisplayMode(.inline)
        .background {
            NavigationBackSwipeRestorer()
                .frame(width: 0, height: 0)
        }
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
