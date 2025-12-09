//
//  ContentView.swift
//  Hackers
//
//  Copyright © 2025 Weiran Zhang. All rights reserved.
//

import Authentication
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
    @Environment(NavigationStore.self) private var navigationStore
    @Environment(SessionService.self) private var sessionService
    @Environment(ToastPresenter.self) private var toastPresenter
    @State private var settingsViewModel = SettingsViewModel()
    @State private var feedViewModel = FeedViewModel()
    @State private var showOnboarding = false
    private let onboardingCoordinator: OnboardingCoordinator
    private var navigationPathBinding: Binding<NavigationPath> {
        Binding(
            get: { navigationStore.path },
            set: { navigationStore.path = $0 }
        )
    }
    private var detailPathBinding: Binding<[NavigationDetailDestination]> {
        Binding(
            get: { navigationStore.detailPath },
            set: { navigationStore.detailPath = $0 }
        )
    }
    private var showingLoginBinding: Binding<Bool> {
        Binding(
            get: { navigationStore.showingLogin },
            set: { navigationStore.showingLogin = $0 }
        )
    }
    private var showingSettingsBinding: Binding<Bool> {
        Binding(
            get: { navigationStore.showingSettings },
            set: { navigationStore.showingSettings = $0 }
        )
    }

    init(container: DependencyContainer = .shared) {
        onboardingCoordinator = OnboardingCoordinator(
            onboardingUseCase: container.getOnboardingUseCase()
        )
    }

    var body: some View {
        Group {
            if UIDevice.current.userInterfaceIdiom == .pad {
                AdaptiveSplitView(settingsViewModel: settingsViewModel, feedViewModel: feedViewModel)
            } else {
                NavigationStack(path: navigationPathBinding) {
                    FeedView<NavigationStore>(
                        viewModel: feedViewModel,
                        isSidebar: false
                    )
                    .navigationDestination(for: NavigationDestination.self) { destination in
                        switch destination {
                        case let .comments(postID):
                            let initialPost: Post? = {
                                guard navigationStore.selectedPost?.id == postID else { return nil }
                                return navigationStore.selectedPost
                            }()
                            CommentsView<NavigationStore>(postID: postID, initialPost: initialPost)
                        case .settings:
                            SettingsView(
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
                                }
                            )
                        }
                    }
                }
            }
        }
        .textScaling(for: settingsViewModel.textSize)
        .accentColor(.accentColor)
        .toastOverlay(toastPresenter, isActive: !isPresentingModal)
        .sheet(isPresented: showingLoginBinding) {
            LoginView(
                isAuthenticated: sessionService.authenticationState == .authenticated,
                currentUsername: sessionService.username,
                onLogin: { username, password in
                    _ = try await sessionService.authenticate(username: username, password: password)
                },
                onLogout: {
                    sessionService.unauthenticate()
                },
                textSize: settingsViewModel.textSize
            )
            .textScaling(for: settingsViewModel.textSize)
                .toastOverlay(toastPresenter)
        }
        .sheet(isPresented: showingSettingsBinding) {
            SettingsView(
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
                }
            )
            .textScaling(for: settingsViewModel.textSize)
            .toastOverlay(toastPresenter)
        }
        .sheet(isPresented: $showOnboarding) {
            onboardingCoordinator
                .makeOnboardingView {
                    showOnboarding = false
                }
                .textScaling(for: settingsViewModel.textSize)
                .toastOverlay(toastPresenter)
        }
        .task {
            if onboardingCoordinator.shouldShowOnboarding() {
                showOnboarding = true
            }
        }
    }

    private var isPresentingModal: Bool {
        navigationStore.showingLogin || navigationStore.showingSettings || showOnboarding
    }
}

struct AdaptiveSplitView: View {
    @Environment(NavigationStore.self) private var navigationStore
    @Environment(SessionService.self) private var sessionService
    @State var settingsViewModel: SettingsViewModel
    let feedViewModel: FeedViewModel
    private var detailPathBinding: Binding<[NavigationDetailDestination]> {
        Binding(
            get: { navigationStore.detailPath },
            set: { navigationStore.detailPath = $0 }
        )
    }

    var body: some View {
        NavigationSplitView {
            // Sidebar - FeedView
            FeedView<NavigationStore>(
                viewModel: feedViewModel,
                isSidebar: true
            )
            .navigationSplitViewColumnWidth(min: 320, ideal: 375, max: 400)
        } detail: {
            // Detail - CommentsView or empty state
            NavigationStack(path: detailPathBinding) {
                if let embeddedURL = navigationStore.embeddedBrowserURL {
                    EmbeddedWebView(url: embeddedURL,
                                    onDismiss: { navigationStore.dismissEmbeddedBrowser() },
                                    showsCloseButton: true)
                        .id(embeddedURL.absoluteString)
                } else if let selectedPost = navigationStore.selectedPost {
                    CommentsView<NavigationStore>(postID: selectedPost.id, initialPost: selectedPost)
                        .id(selectedPost.id) // Add id to force re-render when post changes
                } else if let selectedPostId = navigationStore.selectedPostId {
                    CommentsView<NavigationStore>(postID: selectedPostId, initialPost: nil)
                        .id(selectedPostId)
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
