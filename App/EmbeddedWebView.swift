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
    let page = WebPage()

    func load(_ target: URL) {
        fallbackURL = target
        guard currentURL != target else { return }
        currentURL = target
        _ = page.load(target)
        updateState()
    }

    func updateState() {
        currentURL = page.url ?? currentURL ?? fallbackURL
        currentTitle = page.title
        let list = page.backForwardList
        canGoBack = !list.backList.isEmpty
        canGoForward = !list.forwardList.isEmpty
        isLoading = page.isLoading
    }

    func reload() {
        _ = page.reload()
        updateState()
    }

    func stopLoading() {
        page.stopLoading()
        updateState()
    }

    func goBack() {
        guard let item = page.backForwardList.backList.last else { return }
        _ = page.load(item)
        updateState()
    }

    func goForward() {
        guard let item = page.backForwardList.forwardList.first else { return }
        _ = page.load(item)
        updateState()
    }
}

enum WebViewAnimations {
    static let standard = Animation.easeInOut(duration: 0.25)
    static let fast = Animation.easeInOut(duration: 0.2)
    static let revealDelay: TimeInterval = 0.15
}

struct EmbeddedWebView: View {
    let url: URL
    let onDismiss: @MainActor () -> Void
    let showsCloseButton: Bool
    let showsToolbar: Bool
    @StateObject private var controller: BrowserController

    init(
        url: URL,
        onDismiss: @MainActor @escaping () -> Void,
        showsCloseButton: Bool,
        showsToolbar: Bool = true,
        controller: BrowserController? = nil
    ) {
        self.url = url
        self.onDismiss = onDismiss
        self.showsCloseButton = showsCloseButton
        self.showsToolbar = showsToolbar
        _controller = StateObject(wrappedValue: controller ?? BrowserController())
    }

    var body: some View {
        content
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
            .safeAreaInset(edge: .bottom, spacing: 0) {
                if bottomPanelInsetHeight > 0 {
                    Color.clear.frame(height: bottomPanelInsetHeight)
                }
            }
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
        return PostCommentsSheet.initialCollapsedHeight
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
                controller: browserController
            )

            if showingCommentsPane {
                PostCommentsSheet(
                    post: post,
                    controller: browserController,
                    initialPresentation: presentation,
                    onDismiss: { dismiss() }
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
            withAnimation(WebViewAnimations.standard) {
                showingCommentsPane = true
            }
        }
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
