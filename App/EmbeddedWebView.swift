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
        WebView(controller.page)
            .task(id: url) { await load(url) }
            .task { await monitorNavigations() }
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

struct PostLinkBrowserView: View {
    @Environment(\.dismiss) private var dismiss
    let post: Post
    @State private var showingCommentsPane = false
    @StateObject private var browserController = BrowserController()

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
                    onDismiss: { dismiss() }
                )
                .transition(.move(edge: .bottom))
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .task {
            withAnimation(WebViewAnimations.standard) {
                showingCommentsPane = true
            }
        }
        .background(InteractivePopGestureEnabler().allowsHitTesting(false))
    }
}

private struct InteractivePopGestureEnabler: UIViewControllerRepresentable {
    func makeUIViewController(context _: Context) -> UIViewController {
        let controller = UIViewController()
        controller.view.backgroundColor = .clear
        return controller
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        guard let navigationController = uiViewController.navigationController else { return }
        context.coordinator.navigationController = navigationController
        if navigationController.interactivePopGestureRecognizer?.delegate !== context.coordinator {
            navigationController.interactivePopGestureRecognizer?.delegate = context.coordinator
        }
        navigationController.interactivePopGestureRecognizer?.isEnabled = true
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        weak var navigationController: UINavigationController?

        func gestureRecognizerShouldBegin(_: UIGestureRecognizer) -> Bool {
            (navigationController?.viewControllers.count ?? 0) > 1
        }

        func gestureRecognizer(
            _: UIGestureRecognizer,
            shouldRecognizeSimultaneouslyWith _: UIGestureRecognizer
        ) -> Bool {
            true
        }
    }
}
