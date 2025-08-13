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
    @StateObject private var navigationStore = NavigationStore()
    @EnvironmentObject private var settingsStore: SettingsStore

    var body: some View {
        Group {
            if UIDevice.current.userInterfaceIdiom == .pad {
                AdaptiveSplitView()
                    .environmentObject(navigationStore)
            } else {
                NavigationStack {
                    FeedView()
                        .environmentObject(navigationStore)
                }
            }
        }
        .accentColor(.accentColor)
        .sheet(isPresented: $navigationStore.showingLogin) {
            LoginView()
        }
        .sheet(isPresented: $navigationStore.showingSettings) {
            SettingsView()
                .environmentObject(settingsStore)
        }
    }
}

struct AdaptiveSplitView: View {
    @EnvironmentObject private var navigationStore: NavigationStore
    
    var body: some View {
        NavigationSplitView {
            // Sidebar - FeedView
            FeedView(isSidebar: true)
                .environmentObject(navigationStore)
                .navigationSplitViewColumnWidth(min: 320, ideal: 375, max: 400)
        } detail: {
            // Detail - CommentsView or empty state
            if let selectedPost = navigationStore.selectedPost {
                CommentsView(post: selectedPost)
                    .environmentObject(navigationStore)
            } else {
                EmptyDetailView()
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
}
