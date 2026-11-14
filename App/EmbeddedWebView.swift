//
//  EmbeddedWebView.swift
//  Hackers
//
//  Created by Codex on 2025-09-18.
//

import Comments
import DesignSystem
import CoreImage.CIFilterBuiltins
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
    @Published private(set) var pageBackgroundColor = UIColor.systemBackground
    var fallbackURL: URL?
    let webView: WKWebView
    private var navigationDelegate: BrowserNavigationDelegate?
    private var observations: [NSKeyValueObservation] = []
    private var reloadOverride: (() -> Void)?
    private var mediaPlaybackSuspended = false
    private var requestedMediaPlaybackSuspension = false
    private var mediaPlaybackSuspensionUpdateInFlight = false
    private var pendingMediaPlaybackAction: (() -> Void)?
    private var bottomChromeInset: CGFloat = 0
    private var usesNativeViewport = false
    private var usesVerticalToolbar = false
    private var hasConfiguredObscuredInsets = false

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
        let browserWebView = ChromeAwareWebView(frame: .zero, configuration: configuration)
        webView = browserWebView
        webView.scrollView.topEdgeEffect.isHidden = true

        let navigationDelegate = BrowserNavigationDelegate(controller: self)
        self.navigationDelegate = navigationDelegate
        webView.navigationDelegate = navigationDelegate
        browserWebView.onLayout = { [weak self] in
            self?.updateChromeInsets()
        }
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

    func applyBottomChromeInset(_ bottomInset: CGFloat, usesNativeViewport: Bool = false, usesVerticalToolbar: Bool = false) {
        self.usesVerticalToolbar = usesVerticalToolbar
        if self.usesNativeViewport != usesNativeViewport {
            self.usesNativeViewport = usesNativeViewport
            if usesNativeViewport && hasConfiguredObscuredInsets {
                webView.obscuredContentInsets = .zero
                webView.scrollView.contentInset = .zero
                webView.scrollView.verticalScrollIndicatorInsets = .zero
                hasConfiguredObscuredInsets = false
            }
        }
        bottomChromeInset = max(bottomInset, 0)
        updateChromeInsets()
        DispatchQueue.main.async { [weak self] in
            self?.updateChromeInsets()
        }
    }

    private func updateChromeInsets() {
        guard let window = webView.window, !usesNativeViewport || usesVerticalToolbar else { return }
        // A vertical toolbar leaves the top unobscured. Keep native sizing and
        // scrolling, but exclude the navigation container's inherited top inset.
        let obscuredInsets = UIEdgeInsets(
            top: usesVerticalToolbar ? 0 : window.safeAreaInsets.top,
            left: 0,
            bottom: usesVerticalToolbar ? window.safeAreaInsets.bottom : bottomChromeInset,
            right: 0
        )
        if !hasConfiguredObscuredInsets || webView.obscuredContentInsets != obscuredInsets {
            webView.obscuredContentInsets = obscuredInsets
            hasConfiguredObscuredInsets = true
        }
        if !usesNativeViewport {
            applyScrollViewBottomInset(bottomChromeInset)
        }
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
            webView.observe(\.underPageBackgroundColor, options: [.initial, .new]) { [weak self] _, _ in
                Task { @MainActor [weak self] in
                    guard let self else { return }
                    self.pageBackgroundColor = self.webView.underPageBackgroundColor
                }
            },
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

/// Refresh native chrome geometry when cached browsers move between layouts.
private final class ChromeAwareWebView: WKWebView {
    var onLayout: (() -> Void)?

    override func layoutSubviews() {
        super.layoutSubviews()
        onLayout?()
    }

    override func safeAreaInsetsDidChange() {
        super.safeAreaInsetsDidChange()
        onLayout?()
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
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalBrowserControlsEdge) private var verticalControlsEdge

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
        Group {
            if usesSystemBrowserLayout {
                content
                    .ignoresSafeArea(.container, edges: verticalControlsEdge == nil ? .bottom : [.top, .bottom])
                    .background {
                        if let verticalControlsEdge {
                            Color(uiColor: controller.pageBackgroundColor)
                                .ignoresSafeArea(.container, edges: verticalControlsEdge == .leading ? [.leading, .top, .bottom] : [.trailing, .top, .bottom])
                        }
                    }
            } else {
                extendedBrowserContent
            }
        }
        .toolbarBackground(usesStandardTopToolbar ? .visible : usesSystemBrowserLayout ? .automatic : .hidden, for: .navigationBar)
        .toolbarBackground(usesStandardTopToolbar ? Color(uiColor: .systemBackground) : .clear, for: .navigationBar)
        .toolbar { browserToolbar }
    }

    private var usesStandardTopToolbar: Bool {
        UIDevice.current.userInterfaceIdiom == .pad && showsToolbar
    }

    private var usesSystemBrowserLayout: Bool {
        usesStandardTopToolbar || (isPadLayout && showsToolbar)
    }

    private var extendedBrowserContent: some View {
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
    }

    @ToolbarContentBuilder
    private var browserToolbar: some ToolbarContent {
        if showsToolbar {
            // Add items only when they apply so no empty slot is left in a bar, and
            // give each one a title and symbol so it can sit in the iPhone Duo vertical
            // bar. Close is the primary navigation item, so it goes first.
            if showsCloseButton {
                ToolbarItem(placement: .cancellationAction) { closeButton }
                    .preferVerticalToolbarAxis()
            }
            if controller.canGoBack {
                ToolbarItem(placement: .topBarTrailing) { backButton }
                    .preferVerticalToolbarAxis()
            }
            if controller.canGoForward {
                ToolbarItem(placement: .topBarTrailing) { forwardButton }
                    .preferVerticalToolbarAxis()
            }
            ToolbarItem(placement: .topBarTrailing) { reloadButton }
                .preferVerticalToolbarAxis()
            ToolbarItem(placement: .topBarTrailing) { shareButton }
                .preferVerticalToolbarAxis()
            ToolbarItem(placement: .topBarTrailing) { openInSafariButton }
                .preferVerticalToolbarAxis()
        }
    }

    private var headerBlur: some View {
        HeaderVariableBlur(maxBlurRadius: 6)
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
                    obscuredBottomInset: obscuredBottomInset,
                    usesNativeViewport: usesSystemBrowserLayout,
                    usesVerticalToolbar: verticalControlsEdge != nil
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
            obscuredBottomInset: obscuredBottomInset,
            usesNativeViewport: usesSystemBrowserLayout,
            usesVerticalToolbar: verticalControlsEdge != nil
        )
        .ignoresSafeArea(edges: usesSystemBrowserLayout ? [] : .top)
    }

    private var isPadLayout: Bool {
        horizontalSizeClass == .regular || DeviceLayout.isRunningOnMac
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
            Label("Share", systemImage: "square.and.arrow.up")
        }
    }

    private var openInSafariButton: some View {
        Button {
            Task { @MainActor in
                let targetURL = controller.currentURL ?? url
                LinkOpener.openInSystemBrowser(targetURL)
            }
        } label: {
            Label("Open in Safari", systemImage: "safari")
        }
    }

    private var closeButton: some View {
        Button {
            Task { @MainActor in onDismiss() }
        } label: {
            Label("Close", systemImage: "xmark")
        }
    }

    private var reloadButton: some View {
        Button {
            if controller.isLoading {
                controller.stopLoading()
            } else {
                controller.reload()
            }
        } label: {
            Label(controller.isLoading ? "Stop" : "Reload",
                  systemImage: controller.isLoading ? "xmark" : "arrow.clockwise")
        }
    }

    private var backButton: some View {
        Button {
            controller.goBack()
        } label: {
            Label("Previous Page", systemImage: "arrow.backward")
        }
    }

    private var forwardButton: some View {
        Button {
            controller.goForward()
        } label: {
            Label("Next Page", systemImage: "arrow.forward")
        }
    }

}

private extension ToolbarContent {
    /// Symbol items normally choose their own axis, but the embedded web view can stay
    /// alive while an iPhone Duo changes displays. Explicitly opting in ensures its
    /// existing items migrate into the vertical bar instead of remaining in a top pill.
    @ToolbarContentBuilder
    func preferVerticalToolbarAxis() -> some ToolbarContent {
        if #available(iOS 27.1, *) {
            axisBehavior(UIDevice.current.userInterfaceIdiom == .pad ? .horizontalOnly : .verticalPreferred)
        } else {
            self
        }
    }
}

/// True progressive gaussian blur: the blur radius ramps to zero across the
/// strip while every pixel stays at full contrast, matching Safari's header
/// scrim. Public materials cannot vary blur radius (only opacity and tint,
/// which read as a fade), so this uses the private variableBlur CAFilter that
/// Safari and the previous VariableBlur package rely on.
/// Technique credit: nikstar/VariableBlur and jtrivedi/VariableBlurView (MIT).
private struct HeaderVariableBlur: UIViewRepresentable {
    let maxBlurRadius: CGFloat

    func makeUIView(context: Context) -> VariableBlurUIView {
        VariableBlurUIView(maxBlurRadius: maxBlurRadius)
    }

    func updateUIView(_ uiView: VariableBlurUIView, context: Context) {}
}

private final class VariableBlurUIView: UIVisualEffectView {
    init(maxBlurRadius: CGFloat) {
        super.init(effect: UIBlurEffect(style: .regular))

        guard let filterClass = NSClassFromString(String("retliFAC".reversed())) as? NSObject.Type,
              let variableBlur = filterClass
                  .perform(NSSelectorFromString(String(":epyThtiWretlif".reversed())), with: "variableBlur")?
                  .takeUnretainedValue() as? NSObject else {
            return
        }

        // The blur radius at each pixel scales with the mask's alpha, so the
        // gradient ramps the radius from max at the top to zero at the bottom.
        variableBlur.setValue(maxBlurRadius, forKey: "inputRadius")
        variableBlur.setValue(Self.gradientMask(), forKey: "inputMaskImage")
        variableBlur.setValue(true, forKey: "inputNormalizeEdges")

        subviews.first?.layer.filters = [variableBlur]
        for subview in subviews.dropFirst() {
            subview.alpha = 0
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func didMoveToWindow() {
        // Keeps the unblurred bottom edge crisp instead of pixelated.
        guard let window, let backdropLayer = subviews.first?.layer else { return }
        backdropLayer.setValue(window.traitCollection.displayScale, forKey: "scale")
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        // Calling super here crashes; the appearance-agnostic blur needs no
        // trait-driven update anyway.
    }

    private static func gradientMask() -> CGImage {
        let gradient = CIFilter.linearGradient()
        gradient.color0 = CIColor.black
        gradient.color1 = CIColor.clear
        gradient.point0 = CGPoint(x: 0, y: 100)
        gradient.point1 = CGPoint(x: 0, y: 0)
        return CIContext().createCGImage(
            gradient.outputImage!,
            from: CGRect(x: 0, y: 0, width: 100, height: 100)
        )!
    }
}

private struct BrowserWebView: UIViewRepresentable {
    let controller: BrowserController
    let url: URL
    let obscuredBottomInset: CGFloat
    let usesNativeViewport: Bool
    let usesVerticalToolbar: Bool

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> WKWebView {
        context.coordinator.requestedURL = url
        controller.setReloadOverride(nil)
        controller.applyBottomChromeInset(obscuredBottomInset, usesNativeViewport: usesNativeViewport, usesVerticalToolbar: usesVerticalToolbar)
        if controller.currentURL == nil {
            context.coordinator.scheduleLoad(controller: controller, url: url)
        }
        return controller.webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        controller.setReloadOverride(nil)
        controller.applyBottomChromeInset(obscuredBottomInset, usesNativeViewport: usesNativeViewport, usesVerticalToolbar: usesVerticalToolbar)
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
    let usesNativeViewport: Bool
    let usesVerticalToolbar: Bool

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> WKWebView {
        let webView = controller.webView
        controller.applyBottomChromeInset(obscuredBottomInset, usesNativeViewport: usesNativeViewport, usesVerticalToolbar: usesVerticalToolbar)
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        webView.accessibilityIdentifier = AccessibilityIdentifier.Browser.fixtureArticle
        let coordinator = context.coordinator
        if controller.currentURL == nil {
            coordinator.scheduleLoad { [self, weak coordinator] in
                guard let coordinator else { return }
                loadArticle(in: webView, coordinator: coordinator)
            }
        } else {
            coordinator.loadedArticle = article
            coordinator.loadedURL = url
        }
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        controller.applyBottomChromeInset(obscuredBottomInset, usesNativeViewport: usesNativeViewport, usesVerticalToolbar: usesVerticalToolbar)
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
