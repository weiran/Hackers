//
//  FeedView.swift
//  Hackers
//
//  Created by Weiran Zhang on SwiftUI Migration.
//  Copyright © 2024 Glass Umbrella. All rights reserved.
//

import SwiftUI
import UIKit

struct FeedView: View {
    @StateObject private var viewModel = SwiftUIFeedViewModel()
    @EnvironmentObject private var navigationStore: NavigationStore
    @State private var selectedPostType: PostType = .news
    
    var body: some View {
        NavigationStack {
            VStack {
                PostTypePicker(selectedPostType: $selectedPostType)
                    .onChange(of: selectedPostType) { newValue in
                        navigationStore.selectPostType(newValue)
                        viewModel.postType = newValue
                        Task {
                            await viewModel.loadFeed()
                        }
                    }
                
                if viewModel.isLoading && viewModel.posts.isEmpty {
                    ProgressView("Loading...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(viewModel.posts, id: \.id) { post in
                        PostRowView(post: post)
                            .onTapGesture {
                                navigationStore.showPost(post)
                            }
                    }
                    .refreshable {
                        await viewModel.loadFeed()
                    }
                }
            }
            .navigationTitle("Hacker News")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        navigationStore.showLogin()
                    } label: {
                        Image(systemName: "person.circle")
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        navigationStore.showSettings()
                    } label: {
                        Image(systemName: "gear")
                    }
                }
            }
            .task {
                await viewModel.loadFeed()
            }
        }
    }
}

struct PostTypePicker: View {
    @Binding var selectedPostType: PostType
    
    var body: some View {
        Picker("Post Type", selection: $selectedPostType) {
            ForEach(PostType.allCases, id: \.self) { postType in
                Text(postType.displayName)
                    .tag(postType)
            }
        }
        .pickerStyle(SegmentedPickerStyle())
        .padding(.horizontal)
    }
}

struct PostRowView: View {
    let post: Post
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(post.title)
                .font(.headline)
                .foregroundColor(Color(UIColor(named: "titleTextColor")!))
            
            HStack(spacing: 12) {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.up")
                        .foregroundColor(post.upvoted ? Color(UIColor(named: "upvotedColor")!) : .secondary)
                    Text("\(post.score)")
                        .foregroundColor(.secondary)
                }
                
                HStack(spacing: 4) {
                    Image(systemName: "message")
                        .foregroundColor(.secondary)
                    Text("\(post.commentsCount)")
                        .foregroundColor(.secondary)
                }
                
                Text("by \(post.by)")
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(post.age)
                    .foregroundColor(.secondary)
            }
            .font(.caption)
        }
        .padding(.vertical, 4)
    }
}

// SwiftUI-compatible FeedViewModel
class SwiftUIFeedViewModel: ObservableObject {
    @Published var posts: [Post] = []
    @Published var isLoading = false
    
    var postType: PostType = .news
    private let feedViewModel = FeedViewModel()
    
    @MainActor
    func loadFeed() async {
        isLoading = true
        feedViewModel.postType = postType
        feedViewModel.reset()
        
        do {
            try await feedViewModel.fetchFeed()
            posts = feedViewModel.posts
        } catch {
            print("Error loading feed: \(error)")
        }
        
        isLoading = false
    }
}

extension PostType {
    var displayName: String {
        switch self {
        case .news: return "Top"
        case .ask: return "Ask"
        case .show: return "Show"
        case .jobs: return "Jobs"
        case .newest: return "New"
        case .best: return "Best"
        case .active: return "Active"
        }
    }
}

#Preview {
    FeedView()
        .environmentObject(NavigationStore())
}