//
//  ContentView.swift
//  Hackers
//
//  Created by Weiran Zhang on SwiftUI Migration.
//  Copyright © 2024 Glass Umbrella. All rights reserved.
//

import SwiftUI
import UIKit
import Settings
import Comments
import Feed
import DesignSystem
import Shared

struct MainContentView: View {
    @EnvironmentObject private var navigationStore: NavigationStore
    @StateObject private var sessionService = SessionService()

    var body: some View {
        Group {
            if UIDevice.current.userInterfaceIdiom == .pad {
                AdaptiveSplitView()
                    .environmentObject(navigationStore)
                    .environmentObject(sessionService)
            } else {
                NavigationStack(path: $navigationStore.path) {
                    CleanFeedView<NavigationStore, SessionService>(
                        isSidebar: false,
                        showThumbnails: true,
                        swipeActionsEnabled: true
                    )
                    .environmentObject(navigationStore)
                    .environmentObject(sessionService)
                    .navigationDestination(for: NavigationDestination.self) { destination in
                        switch destination {
                        case .comments(let post):
                            CleanCommentsView<NavigationStore>(post: post)
                                .environmentObject(navigationStore)
                                .environmentObject(sessionService)
                        case .settings:
                            CleanSettingsView<NavigationStore>(
                                isAuthenticated: sessionService.authenticationState == .authenticated,
                                currentUsername: sessionService.username
                            )
                            .environmentObject(navigationStore)
                            .environmentObject(sessionService)
                        }
                    }
                }
            }
        }
        .accentColor(.accentColor)
        .sheet(isPresented: $navigationStore.showingLogin) {
            LoginView(
                isAuthenticated: sessionService.authenticationState == .authenticated,
                currentUsername: sessionService.username,
                onLogin: { username, password in
                    Task {
                        try? await sessionService.authenticate(username: username, password: password)
                    }
                },
                onLogout: {
                    sessionService.unauthenticate()
                }
            )
        }
        .sheet(isPresented: $navigationStore.showingSettings) {
            CleanSettingsView<NavigationStore>(
                isAuthenticated: sessionService.authenticationState == .authenticated,
                currentUsername: sessionService.username
            )
            .environmentObject(navigationStore)
            .environmentObject(sessionService)
        }
    }
}

struct AdaptiveSplitView: View {
    @EnvironmentObject private var navigationStore: NavigationStore
    @EnvironmentObject private var sessionService: SessionService

    var body: some View {
        NavigationSplitView {
            // Sidebar - FeedView
            CleanFeedView<NavigationStore, SessionService>(
                isSidebar: true,
                showThumbnails: true,
                swipeActionsEnabled: false
            )
            .environmentObject(navigationStore)
            .environmentObject(sessionService)
            .navigationSplitViewColumnWidth(min: 320, ideal: 375, max: 400)
        } detail: {
            // Detail - CommentsView or empty state
            NavigationStack {
                if let selectedPost = navigationStore.selectedPost {
                    CleanCommentsView<NavigationStore>(post: selectedPost)
                        .environmentObject(navigationStore)
                        .environmentObject(sessionService)
                        .id(selectedPost.id) // Add id to force re-render when post changes
                } else {
                    EmptyDetailView()
                }
            }
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
