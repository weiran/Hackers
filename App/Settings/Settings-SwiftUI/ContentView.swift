//
//  ContentView.swift
//  Hackers
//
//  Created by Weiran Zhang on SwiftUI Migration.
//  Copyright © 2024 Glass Umbrella. All rights reserved.
//

import SwiftUI
import UIKit

struct ContentView: View {
    @StateObject private var navigationStore = NavigationStore()
    @EnvironmentObject private var settingsStore: SettingsStore
    
    var body: some View {
        NavigationSplitView {
            FeedView()
                .environmentObject(navigationStore)
        } detail: {
            if let selectedPost = navigationStore.selectedPost {
                CommentsView(post: selectedPost)
                    .environmentObject(navigationStore)
            } else {
                EmptyStateView()
            }
        }
        .accentColor(Color(UIColor(named: "appTintColor")!))
        .sheet(isPresented: $navigationStore.showingLogin) {
            LoginView()
        }
        .sheet(isPresented: $navigationStore.showingSettings) {
            SettingsView()
                .environmentObject(settingsStore)
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(SettingsStore())
}