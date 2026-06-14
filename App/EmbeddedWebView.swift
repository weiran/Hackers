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

enum PageHeaderBlurTint: Equatable {
    case light
    case dark

    var color: Color {
        switch self {
        case .light:
            .white
        case .dark:
            .black
        }
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
    let page: WebPage
    private var headerTintTask: Task<Void, Never>?
    private var pageHeaderBlurTintURL: URL?

    init() {
        var configuration = WebPage.Configuration()
        // Some app-shell sites gate rendering on Safari UA tokens; keep WebPage identified as Mobile Safari.
        configuration.applicationNameForUserAgent = Self.safariApplicationNameForUserAgent
        page = WebPage(configuration: configuration)
    }

    func load(_ target: URL) {
        fallbackURL = target
        guard currentURL != target else { return }
        currentURL = target
        _ = page.load(target)
        updateState()
    }

    func updateState() {
        let updatedURL = page.url ?? currentURL ?? fallbackURL
        if pageHeaderBlurTintURL != updatedURL {
            pageHeaderBlurTint = nil
            pageHeaderBlurTintURL = nil
        }
        currentURL = updatedURL
        currentTitle = page.title
        let list = page.backForwardList
        canGoBack = !list.backList.isEmpty
        canGoForward = !list.forwardList.isEmpty
        isLoading = page.isLoading
        scheduleHeaderTintUpdate()
    }

    func reload() {
        resetHeaderBlurTint()
        _ = page.reload()
        updateState()
    }

    func stopLoading() {
        page.stopLoading()
        updateState()
    }

    func goBack() {
        guard let item = page.backForwardList.backList.last else { return }
        resetHeaderBlurTint()
        _ = page.load(item)
        updateState()
    }

    func goForward() {
        guard let item = page.backForwardList.forwardList.first else { return }
        resetHeaderBlurTint()
        _ = page.load(item)
        updateState()
    }

    private func resetHeaderBlurTint() {
        pageHeaderBlurTint = nil
        pageHeaderBlurTintURL = nil
    }

    private func scheduleHeaderTintUpdate() {
        headerTintTask?.cancel()
        headerTintTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .milliseconds(250))
            guard !Task.isCancelled else { return }
            await self?.updateHeaderTintFromPage()

            try? await Task.sleep(for: .milliseconds(750))
            guard !Task.isCancelled else { return }
            await self?.updateHeaderTintFromPage()
        }
    }

    private func updateHeaderTintFromPage() async {
        do {
            guard let result = try await page.callJavaScript(Self.headerTintDetectionScript) as? String else {
                return
            }

            let updatedTint: PageHeaderBlurTint = result == "dark" ? .dark : .light
            if pageHeaderBlurTint != updatedTint {
                pageHeaderBlurTint = updatedTint
            }
            pageHeaderBlurTintURL = currentURL
        } catch {
            // Cross-origin and in-flight navigations can reject evaluation; keep the last usable tint.
        }
    }

    private static var safariApplicationNameForUserAgent: String {
        "Version/\(UIDevice.current.systemVersion) Mobile/15E148 Safari/604.1"
    }

    private static let headerTintDetectionScript = """
    function parseColor(value) {
        if (!value || value === 'transparent') { return null; }
        const match = value.match(/rgba?\\(([^)]+)\\)/);
        if (!match) { return null; }

        const parts = match[1]
            .replace(/\\//g, ' ')
            .split(/[ ,]+/)
            .filter(Boolean);

        if (parts.length < 3) { return null; }

        function component(part) {
            return part.endsWith('%') ? parseFloat(part) * 2.55 : parseFloat(part);
        }

        const r = component(parts[0]);
        const g = component(parts[1]);
        const b = component(parts[2]);
        const a = parts.length >= 4 ? parseFloat(parts[3]) : 1;

        if ([r, g, b, a].some((number) => Number.isNaN(number))) { return null; }
        return { r, g, b, a };
    }

    function luminance(color) {
        const channel = (value) => {
            const normalized = Math.max(0, Math.min(255, value)) / 255;
            return normalized <= 0.03928
                ? normalized / 12.92
                : Math.pow((normalized + 0.055) / 1.055, 2.4);
        };

        return 0.2126 * channel(color.r) + 0.7152 * channel(color.g) + 0.0722 * channel(color.b);
    }

    function firstUsefulBackground(element) {
        var current = element;
        while (current) {
            const color = parseColor(getComputedStyle(current).backgroundColor);
            if (color && color.a > 0.35) { return color; }
            current = current.parentElement;
        }
        return null;
    }

    const width = Math.max(document.documentElement.clientWidth || 0, window.innerWidth || 0);
    const height = Math.max(document.documentElement.clientHeight || 0, window.innerHeight || 0);
    const points = [
        [width * 0.25, 1],
        [width * 0.50, 1],
        [width * 0.75, 1],
        [width * 0.25, Math.min(32, height * 0.08)],
        [width * 0.50, Math.min(32, height * 0.08)],
        [width * 0.75, Math.min(32, height * 0.08)]
    ];

    const colors = points
        .map(([x, y]) => document.elementFromPoint(x, y))
        .map(firstUsefulBackground)
        .filter(Boolean);

    if (colors.length === 0 && document.body) {
        const bodyColor = parseColor(getComputedStyle(document.body).backgroundColor);
        if (bodyColor && bodyColor.a > 0.35) { colors.push(bodyColor); }
    }

    if (colors.length === 0) {
        const rootColor = parseColor(getComputedStyle(document.documentElement).backgroundColor);
        if (rootColor && rootColor.a > 0.35) { colors.push(rootColor); }
    }

    if (colors.length === 0) {
        const themeColor = document.querySelector('meta[name="theme-color"]')?.content;
        if (themeColor) {
            const probe = document.createElement('span');
            probe.style.color = themeColor;
            document.documentElement.appendChild(probe);
            const parsedThemeColor = parseColor(getComputedStyle(probe).color);
            probe.remove();
            if (parsedThemeColor) { colors.push(parsedThemeColor); }
        }
    }

    if (colors.length === 0) { return 'light'; }

    const averageLuminance = colors.reduce((sum, color) => sum + luminance(color), 0) / colors.length;
    return averageLuminance < 0.45 ? 'dark' : 'light';
    """
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
    let bottomScrollContentInset: CGFloat
    @StateObject private var controller: BrowserController

    init(
        url: URL,
        onDismiss: @MainActor @escaping () -> Void,
        showsCloseButton: Bool,
        showsToolbar: Bool = true,
        bottomWebViewInset: CGFloat = 0,
        bottomScrollContentInset: CGFloat = 0,
        controller: BrowserController? = nil
    ) {
        self.url = url
        self.onDismiss = onDismiss
        self.showsCloseButton = showsCloseButton
        self.showsToolbar = showsToolbar
        self.bottomWebViewInset = bottomWebViewInset
        self.bottomScrollContentInset = bottomScrollContentInset
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
            if let tint = controller.pageHeaderBlurTint {
                ProgressiveHeaderBlurBackground(
                    height: proxy.safeAreaInsets.top,
                    fadeExtension: Self.statusBarBlurFadeExtension,
                    tintMiddleLocation: 0.45,
                    tint: tint.color
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .transition(.opacity)
            }
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
        WebView(controller.page)
            .background(WebViewScrollInsetApplicator(bottomInset: bottomScrollContentInset))
            .task(id: url) { await load(url) }
            .task { await monitorNavigations() }
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
                LinkOpener.openURL(targetURL)
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

    @MainActor
    private func load(_ target: URL) async {
        controller.load(target)
    }

    @MainActor
    private func monitorNavigations() async {
        controller.updateState()
        do {
            for try await _ in controller.page.navigations {
                controller.updateState()
            }
        } catch {
            // Ignore navigation stream errors; state updates happen on successful events.
        }
    }
}

private struct WebViewScrollInsetApplicator: UIViewRepresentable {
    let bottomInset: CGFloat

    func makeUIView(context: Context) -> WebViewScrollInsetView {
        let view = WebViewScrollInsetView()
        view.bottomInset = bottomInset
        return view
    }

    func updateUIView(_ uiView: WebViewScrollInsetView, context: Context) {
        uiView.bottomInset = bottomInset
    }
}

private final class WebViewScrollInsetView: UIView {
    var bottomInset: CGFloat = 0 {
        didSet {
            guard abs(bottomInset - oldValue) > 0.5 else { return }
            applyInsetsWhenReady()
        }
    }

    private weak var webView: WKWebView?
    private var isApplyScheduled = false
    private var applyAttempts = 0

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        backgroundColor = .clear
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        applyInsetsWhenReady()
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        applyInsetsWhenReady()
    }

    private func applyInsetsWhenReady() {
        guard !isApplyScheduled else { return }
        isApplyScheduled = true
        DispatchQueue.main.async { [weak self] in
            self?.isApplyScheduled = false
            self?.applyInsets()
        }
    }

    private func applyInsets() {
        guard let webView = resolvedWebView() else {
            retryApplyInsets()
            return
        }

        applyAttempts = 0
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

    private func retryApplyInsets() {
        guard window != nil, applyAttempts < 8 else { return }
        applyAttempts += 1
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
            self?.applyInsetsWhenReady()
        }
    }

    private func resolvedWebView() -> WKWebView? {
        if let webView, webView.window != nil, isInCurrentHierarchy(webView) {
            return webView
        }

        var candidateSuperview = superview
        while let candidate = candidateSuperview, !(candidate is UIWindow) {
            if let resolved = candidate.firstDescendant(ofType: WKWebView.self, excluding: self) {
                webView = resolved
                return resolved
            }
            candidateSuperview = candidate.superview
        }

        return nil
    }

    private func isInCurrentHierarchy(_ view: UIView) -> Bool {
        var candidateSuperview = superview
        while let candidate = candidateSuperview, !(candidate is UIWindow) {
            if view.isDescendant(of: candidate) {
                return true
            }
            candidateSuperview = candidate.superview
        }

        return false
    }
}

private extension UIView {
    func firstDescendant<T: UIView>(ofType type: T.Type, excluding excludedView: UIView) -> T? {
        for subview in subviews where subview !== excludedView {
            if let typedSubview = subview as? T {
                return typedSubview
            }

            if let descendant = subview.firstDescendant(ofType: type, excluding: excludedView) {
                return descendant
            }
        }

        return nil
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
    @State private var browserScrollContentInset = PostCommentsSheet.defaultCollapsedBrowserScrollContentInset
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
                bottomScrollContentInset: browserScrollContentInset,
                controller: browserController
            )

            if showingCommentsPane {
                PostCommentsSheet(
                    post: post,
                    controller: browserController,
                    initialPresentation: presentation,
                    onDismiss: { dismiss() },
                    onCollapsedHeightChange: { collapsedCommentsHeight = $0 },
                    onBrowserScrollContentInsetChange: { browserScrollContentInset = $0 }
                )
                .transition(.move(edge: .bottom))
            }
        }
        .tint(.accentColor)
        .accessibilityIdentifier("browser.view")
        .navigationBarBackButtonHidden(true)
        .toolbarBackground(.hidden, for: .navigationBar)
        .navigationBarTitleDisplayMode(.inline)
        .nativeInteractivePopGesture(edgeOnly: true)
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

private extension View {
    func nativeInteractivePopGesture(edgeOnly: Bool) -> some View {
        background {
            NativeInteractivePopGestureInstaller(edgeOnly: edgeOnly)
                .frame(width: 0, height: 0)
                .allowsHitTesting(false)
        }
    }
}

@MainActor
private struct NativeInteractivePopGestureInstaller: UIViewControllerRepresentable {
    var edgeOnly: Bool

    func makeCoordinator() -> Coordinator {
        Coordinator(edgeOnly: edgeOnly)
    }

    func makeUIViewController(context: Context) -> ProbeViewController {
        let controller = ProbeViewController()
        controller.view.backgroundColor = .clear
        controller.view.isUserInteractionEnabled = false
        controller.onLifecycle = { [weak coordinator = context.coordinator] controller in
            coordinator?.installIfPossible(from: controller)
        }
        return controller
    }

    func updateUIViewController(_ controller: ProbeViewController, context: Context) {
        context.coordinator.edgeOnly = edgeOnly
        controller.onLifecycle = { [weak coordinator = context.coordinator] controller in
            coordinator?.installIfPossible(from: controller)
        }
        context.coordinator.installIfPossible(from: controller)

        let coordinator = context.coordinator
        Task { @MainActor [weak controller, weak coordinator] in
            guard let controller else { return }
            coordinator?.installIfPossible(from: controller)
        }
    }

    static func dismantleUIViewController(_ controller: ProbeViewController, coordinator: Coordinator) {
        coordinator.restore()
        controller.onLifecycle = nil
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

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        var edgeOnly: Bool

        private weak var navigationController: UINavigationController?
        private weak var edgeGesture: UIGestureRecognizer?
        private weak var contentGesture: UIGestureRecognizer?
        private weak var originalEdgeDelegate: UIGestureRecognizerDelegate?
        private weak var originalContentDelegate: UIGestureRecognizerDelegate?

        init(edgeOnly: Bool) {
            self.edgeOnly = edgeOnly
        }

        func installIfPossible(from controller: UIViewController) {
            guard let navigationController = controller.nearestNavigationController else { return }
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
            guard isManagedPopGesture(gestureRecognizer) else {
                return true
            }
            guard let navigationController else { return false }
            guard navigationController.viewControllers.count > 1 else { return false }
            guard navigationController.transitionCoordinator == nil else { return false }

            if #available(iOS 26.0, *),
               gestureRecognizer === contentGesture,
               edgeOnly {
                let location = gestureRecognizer.location(in: navigationController.view)
                return location.x <= systemPopStartMaxX(in: navigationController)
            }

            return true
        }

        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
            guard isManagedPopGesture(gestureRecognizer) else {
                return true
            }
            guard let navigationController else { return false }

            if #available(iOS 26.0, *),
               gestureRecognizer === contentGesture,
               edgeOnly {
                let location = touch.location(in: navigationController.view)
                return location.x <= systemPopStartMaxX(in: navigationController)
            }

            return true
        }

        func gestureRecognizer(
            _ gestureRecognizer: UIGestureRecognizer,
            shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
        ) -> Bool {
            return isManagedPopGesture(gestureRecognizer) || isManagedPopGesture(otherGestureRecognizer)
        }

        private func isManagedPopGesture(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            if gestureRecognizer === edgeGesture {
                return true
            }
            if #available(iOS 26.0, *),
               gestureRecognizer === contentGesture {
                return true
            }
            return false
        }

        private func systemPopStartMaxX(in navigationController: UINavigationController) -> CGFloat {
            navigationController.view.safeAreaInsets.left + 56
        }
    }
}

private extension UIViewController {
    var nearestNavigationController: UINavigationController? {
        if let navigationController {
            return navigationController
        }

        var current = parent
        while let controller = current {
            if let navigationController = controller as? UINavigationController {
                return navigationController
            }
            if let navigationController = controller.navigationController {
                return navigationController
            }
            current = controller.parent
        }

        return nil
    }
}
