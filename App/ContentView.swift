//
//  ContentView.swift
//  Hackers
//
//  Created by Weiran Zhang on SwiftUI Migration.
//  Copyright © 2024 Glass Umbrella. All rights reserved.
//

import SwiftUI
import UIKit

struct MainContentView: View {
    @EnvironmentObject private var navigationStore: NavigationStore
    @EnvironmentObject private var settingsStore: SettingsStore

    var body: some View {
        Group {
            if UIDevice.current.userInterfaceIdiom == .pad {
                AdaptiveSplitView()
                    .environmentObject(navigationStore)
            } else {
                NavigationStack {
                    if AppConfiguration.shared.useCleanFeed {
                        CleanFeedViewWrapper()
                            .environmentObject(navigationStore)
                            .navigationDestination(item: $navigationStore.selectedHackersKitPost) { post in
                                if AppConfiguration.shared.useCleanComments {
                                    CleanCommentsViewWrapper(post: post)
                                        .environmentObject(navigationStore)
                                } else {
                                    CommentsView(post: post)
                                        .environmentObject(navigationStore)
                                }
                            }
                    } else {
                        FeedView()
                            .environmentObject(navigationStore)
                            // Navigation is now handled by NavigationLink in FeedView
                    }
                }
            }
        }
        .accentColor(.accentColor)
        .sheet(isPresented: $navigationStore.showingLogin) {
            LoginView()
        }
        .sheet(isPresented: $navigationStore.showingSettings) {
            if AppConfiguration.shared.useCleanSettings {
                CleanSettingsViewWrapper()
                    .environmentObject(settingsStore)
            } else {
                SettingsView()
                    .environmentObject(settingsStore)
            }
        }
    }
}

struct AdaptiveSplitView: View {
    @EnvironmentObject private var navigationStore: NavigationStore

    var body: some View {
        NavigationSplitView {
            // Sidebar - FeedView
            if AppConfiguration.shared.useCleanFeed {
                CleanFeedViewWrapper(isSidebar: true)
                    .environmentObject(navigationStore)
                    .navigationSplitViewColumnWidth(min: 320, ideal: 375, max: 400)
            } else {
                FeedView(isSidebar: true)
                    .environmentObject(navigationStore)
                    .navigationSplitViewColumnWidth(min: 320, ideal: 375, max: 400)
            }
        } detail: {
            // Detail - CommentsView or empty state
            NavigationStack {
                if let selectedPost = navigationStore.selectedHackersKitPost {
                    if AppConfiguration.shared.useCleanComments {
                        CleanCommentsViewWrapper(post: selectedPost)
                            .environmentObject(navigationStore)
                            .id(selectedPost.id) // Add id to force re-render when post changes
                    } else {
                        CommentsView(post: selectedPost)
                            .environmentObject(navigationStore)
                            .id(selectedPost.id) // Add id to force re-render when post changes
                    }
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
        .environmentObject(SettingsStore())
        .environmentObject(NavigationStore())
}
