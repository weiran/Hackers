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

@MainActor
struct MainContentView: View {
    @EnvironmentObject private var navigationStore: NavigationStore
    @StateObject private var sessionService: SessionService
    @StateObject private var settingsViewModel = SettingsViewModel()
    @State private var showOnboarding = false
    private let onboardingCoordinator: OnboardingCoordinator

    init(container: DependencyContainer = .shared) {
        _sessionService = StateObject(wrappedValue: container.makeSessionService())
        onboardingCoordinator = OnboardingCoordinator(
            onboardingUseCase: container.getOnboardingUseCase()
        )
    }

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
            onboardingCoordinator
                .makeOnboardingView {
                    showOnboarding = false
                }
                .textScaling(for: settingsViewModel.textSize)
        }
        .task {
            if onboardingCoordinator.shouldShowOnboarding() {
                showOnboarding = true
            }
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
