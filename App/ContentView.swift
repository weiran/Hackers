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

struct MainContentView: View {
    @EnvironmentObject private var navigationStore: NavigationStore

    var body: some View {
        Group {
            if UIDevice.current.userInterfaceIdiom == .pad {
                AdaptiveSplitView()
                    .environmentObject(navigationStore)
            } else {
                NavigationStack(path: $navigationStore.path) {
                    CleanFeedView<NavigationStore>(
                        isSidebar: false,
                        showThumbnails: true,
                        swipeActionsEnabled: true
                    )
                    .environmentObject(navigationStore)
                    .navigationDestination(for: NavigationDestination.self) { destination in
                        switch destination {
                        case .comments(let post):
                            CleanCommentsView<NavigationStore>(post: post)
                                .environmentObject(navigationStore)
                        case .settings:
                            CleanSettingsView<NavigationStore>(
                                isAuthenticated: false, // TODO: Connect to actual auth state
                                currentUsername: nil
                            )
                            .environmentObject(navigationStore)
                        }
                    }
                }
            }
        }
        .accentColor(.accentColor)
        .sheet(isPresented: $navigationStore.showingLogin) {
            LoginView(
                isAuthenticated: false, // TODO: Connect to actual auth state
                currentUsername: nil,
                onLogin: { _, _ in }, // TODO: Implement login
                onLogout: { } // TODO: Implement logout
            )
        }
        .sheet(isPresented: $navigationStore.showingSettings) {
            CleanSettingsView<NavigationStore>(
                isAuthenticated: false, // TODO: Connect to actual auth state
                currentUsername: nil
            )
            .environmentObject(navigationStore)
        }
    }
}

struct AdaptiveSplitView: View {
    @EnvironmentObject private var navigationStore: NavigationStore

    var body: some View {
        NavigationSplitView {
            // Sidebar - FeedView
            CleanFeedView<NavigationStore>(
                isSidebar: true,
                showThumbnails: true,
                swipeActionsEnabled: false
            )
            .environmentObject(navigationStore)
            .navigationSplitViewColumnWidth(min: 320, ideal: 375, max: 400)
        } detail: {
            // Detail - CommentsView or empty state
            NavigationStack {
                if let selectedPost = navigationStore.selectedPost {
                    CleanCommentsView<NavigationStore>(post: selectedPost)
                        .environmentObject(navigationStore)
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
