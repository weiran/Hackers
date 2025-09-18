//
//  ContentView.swift
//  Hackers
//
//  Copyright © 2025 Weiran Zhang. All rights reserved.
//

import Comments
import DesignSystem
import Domain
import Feed
import Settings
import Shared
import SwiftUI
import UIKit
import WebKit

struct MainContentView: View {
    @EnvironmentObject private var navigationStore: NavigationStore
    @StateObject private var sessionService = SessionService()
    @StateObject private var settingsViewModel = SettingsViewModel()
    @State private var showOnboarding = false

    var body: some View {
        Group {
            if UIDevice.current.userInterfaceIdiom == .pad {
                AdaptiveSplitView(settingsViewModel: settingsViewModel)
                    .environmentObject(navigationStore)
                    .environmentObject(sessionService)
            } else {
                NavigationStack(path: $navigationStore.path) {
                    FeedView<NavigationStore, SessionService>(
                        isSidebar: false,
                    )
                    .environmentObject(navigationStore)
                    .environmentObject(sessionService)
                    .navigationDestination(for: NavigationDestination.self) { destination in
                        switch destination {
                        case let .comments(post):
                            CommentsView<NavigationStore>(post: post)
                                .environmentObject(navigationStore)
                                .environmentObject(sessionService)
                        case .settings:
                            SettingsView<NavigationStore>(
                                viewModel: settingsViewModel,
                                isAuthenticated: sessionService.authenticationState == .authenticated,
                                currentUsername: sessionService.username,
                                onLogin: { username, password in
                                    _ = try await sessionService.authenticate(username: username, password: password)
                                },
                                onLogout: {
                                    sessionService.unauthenticate()
                                },
                                onShowOnboarding: {
                                    showOnboarding = true
                                },
                            )
                            .environmentObject(navigationStore)
                            .environmentObject(sessionService)
                        }
                    }
                }
            }
        }
        .textScaling(for: settingsViewModel.textSize)
        .accentColor(.accentColor)
        .sheet(isPresented: $navigationStore.showingLogin) {
            LoginView(
                isAuthenticated: sessionService.authenticationState == .authenticated,
                currentUsername: sessionService.username,
                onLogin: { username, password in
                    Task {
                        _ = try? await sessionService.authenticate(username: username, password: password)
                    }
                },
                onLogout: {
                    sessionService.unauthenticate()
                },
            )
        }
        .sheet(isPresented: $navigationStore.showingSettings) {
            SettingsView<NavigationStore>(
                viewModel: settingsViewModel,
                isAuthenticated: sessionService.authenticationState == .authenticated,
                currentUsername: sessionService.username,
                onLogin: { username, password in
                    _ = try await sessionService.authenticate(username: username, password: password)
                },
                onLogout: {
                    sessionService.unauthenticate()
                },
                onShowOnboarding: {
                    showOnboarding = true
                },
            )
            .environmentObject(navigationStore)
            .environmentObject(sessionService)
            .textScaling(for: settingsViewModel.textSize)
        }
        .sheet(isPresented: $showOnboarding) {
            OnboardingViewWrapper()
                .textScaling(for: settingsViewModel.textSize)
        }
    }
}

struct AdaptiveSplitView: View {
    @EnvironmentObject private var navigationStore: NavigationStore
    @EnvironmentObject private var sessionService: SessionService
    @StateObject var settingsViewModel: SettingsViewModel

    var body: some View {
        NavigationSplitView {
            // Sidebar - FeedView
            FeedView<NavigationStore, SessionService>(
                isSidebar: true,
            )
            .environmentObject(navigationStore)
            .environmentObject(sessionService)
            .navigationSplitViewColumnWidth(min: 320, ideal: 375, max: 400)
        } detail: {
            // Detail - CommentsView or empty state
            NavigationStack(path: $navigationStore.detailPath) {
                if let embeddedURL = navigationStore.embeddedBrowserURL {
                    EmbeddedWebView(url: embeddedURL,
                                    onDismiss: { navigationStore.dismissEmbeddedBrowser() },
                                    showsCloseButton: true)
                        .id(embeddedURL.absoluteString)
                } else if let selectedPost = navigationStore.selectedPost {
                    CommentsView<NavigationStore>(post: selectedPost)
                        .environmentObject(navigationStore)
                        .environmentObject(sessionService)
                        .id(selectedPost.id) // Add id to force re-render when post changes
                } else {
                    EmptyDetailView()
                }
            }
            .navigationDestination(for: NavigationDetailDestination.self) { destination in
                switch destination {
                case let .web(url):
                    EmbeddedWebView(url: url,
                                    onDismiss: { navigationStore.dismissEmbeddedBrowser() },
                                    showsCloseButton: false)
                }
            }
        }
        .textScaling(for: settingsViewModel.textSize)
    }
}

private struct EmbeddedWebView: View {
    let url: URL
    let onDismiss: @MainActor () -> Void
    let showsCloseButton: Bool

    @State private var currentURL: URL?
    @State private var currentTitle: String?

    var body: some View {
        WebKitView(
            url: url,
            onUpdate: { updatedURL, updatedTitle in
                currentURL = updatedURL
                currentTitle = updatedTitle
            }
        )
        .ignoresSafeArea(.container, edges: .all)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                shareButton
            }
            ToolbarItem(placement: .topBarTrailing) {
                if showsCloseButton {
                    closeButton
                }
            }
        }
    }

    private var shareButton: some View {
        Button {
            Task { @MainActor in
                let targetURL = currentURL ?? url
                ShareService.shared.shareURL(targetURL, title: currentTitle)
            }
        } label: {
            Image(systemName: "square.and.arrow.up")
        }
        .accessibilityLabel("Share")
    }

    private var closeButton: some View {
        Button {
            Task { @MainActor in onDismiss() }
        } label: {
            Image(systemName: "xmark")
        }
        .accessibilityLabel("Close")
    }
}

// TODO: Replace WebKitView with native WebView once macOS Catalyst supports it.
private struct WebKitView: UIViewRepresentable {
    let url: URL
    let onUpdate: (URL?, String?) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onUpdate: onUpdate)
    }

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView(frame: .zero)
        webView.navigationDelegate = context.coordinator
        context.coordinator.load(url: url, into: webView)
        context.coordinator.forwardUpdate(from: webView)
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        context.coordinator.load(url: url, into: webView)
        context.coordinator.forwardUpdate(from: webView)
    }

    final class Coordinator: NSObject, WKNavigationDelegate {
        private let onUpdate: (URL?, String?) -> Void
        private var lastRequestedURL: URL?

        init(onUpdate: @escaping (URL?, String?) -> Void) {
            self.onUpdate = onUpdate
        }

        func load(url: URL, into webView: WKWebView) {
            guard lastRequestedURL != url else { return }
            lastRequestedURL = url
            let request = URLRequest(url: url)
            webView.load(request)
        }

        func forwardUpdate(from webView: WKWebView) {
            if let currentURL = webView.url {
                lastRequestedURL = currentURL
            }
            onUpdate(webView.url, webView.title)
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            forwardUpdate(from: webView)
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError _: Error) {
            forwardUpdate(from: webView)
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError _: Error) {
            forwardUpdate(from: webView)
        }
    }
}

struct EmptyDetailView: View {
    var body: some View {
        ContentUnavailableView {
            Label("Select a Post", systemImage: "doc.text")
        } description: {
            Text("Choose a post from the sidebar to view its comments and details")
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    MainContentView()
        .environmentObject(NavigationStore())
}
