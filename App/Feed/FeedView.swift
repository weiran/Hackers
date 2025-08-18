//
//  FeedView.swift
//  Hackers
//
//  Created by Weiran Zhang on SwiftUI Migration.
//  Copyright © 2024 Glass Umbrella. All rights reserved.
//

import SwiftUI
import SafariServices

struct FeedView: View {
    @StateObject private var viewModel = SwiftUIFeedViewModel()
    @EnvironmentObject private var navigationStore: NavigationStore
    @State private var selectedPostType: PostType = .news
    @State private var showingVoteError = false
    @State private var voteErrorMessage = ""
    @State private var showingAuthenticationDialog = false

    let isSidebar: Bool

    init(isSidebar: Bool = false) {
        self.isSidebar = isSidebar
    }

    private var selectionBinding: Binding<Int?> {
        isSidebar ? Binding(
            get: { navigationStore.selectedPost?.id },
            set: { newPostId in
                if let postId = newPostId,
                   let selectedPost = viewModel.posts.first(where: { $0.id == postId }) {
                    navigationStore.showPost(selectedPost)
                }
            }
        ) : .constant(nil)
    }

    var body: some View {
        NavigationStack {
            if viewModel.isLoading && viewModel.posts.isEmpty {
                ProgressView("Loading...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(selection: selectionBinding) {
                    ForEach(viewModel.posts, id: \.id) { post in
                        let rowView = PostRowView(
                            post: post,
                            navigationStore: navigationStore,
                            isSidebar: isSidebar,
                            onVote: { post in
                                Task {
                                    await handleVote(post: post)
                                }
                            },
                            onLinkTap: { post in
                                handleLinkTap(post: post)
                            },
                            onCommentsTap: { _ in }
                        )
                        
                        Group {
                            if isSidebar {
                                // iPad: Use tag for List selection, which triggers navigation via selectionBinding
                                rowView
                                    .tag(post.id)
                            } else {
                                // iPhone: Use NavigationLink for proper row behavior
                                NavigationLink(destination: CommentsView(post: post).environmentObject(navigationStore)) {
                                    rowView
                                }
                            }
                        }
                        .onAppear {
                            // Load next page when near end
                            if post == viewModel.posts.last {
                                Task {
                                    await viewModel.loadNextPage()
                                }
                            }
                        }
                        .contextMenu {
                            PostContextMenu(
                                post: post,
                                onVote: {
                                    Task {
                                        await handleVote(post: post)
                                    }
                                },
                                onOpenLink: {
                                    handleLinkTap(post: post)
                                },
                                onShare: {
                                    sharePost(post)
                                }
                            )
                        }
                        .authenticationDialog(isPresented: $showingAuthenticationDialog) {
                            navigationStore.showLogin()
                        }
                    }
                }
                .listStyle(.plain)
                .refreshable {
                    await viewModel.loadFeed()
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                Menu {
                    ForEach(PostType.allCases, id: \.self) { postType in
                        Button {
                            selectedPostType = postType
                            navigationStore.selectPostType(postType)
                            viewModel.postType = postType
                            Task {
                                await viewModel.loadFeed()
                            }
                        } label: {
                            HStack {
                                Image(systemName: postType.iconName)
                                Text(postType.displayName)
                                if postType == selectedPostType {
                                    Spacer()
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: selectedPostType.iconName)
                            .font(.headline)
                            .foregroundColor(.primary)
                        Text(selectedPostType.displayName)
                            .font(.headline)
                            .foregroundColor(.primary)
                        Image(systemName: "chevron.down")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

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
        .task { @Sendable in
            await viewModel.loadFeed()
        }
        .alert("Vote Error", isPresented: $showingVoteError) {
            Button("OK") { }
        } message: {
            Text(voteErrorMessage)
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    @MainActor
    private func handleVote(post: Post) async {
        let isUpvote = !post.upvoted

        // Optimistically update UI
        post.upvoted = isUpvote
        post.score += isUpvote ? 1 : -1

        do {
            try await viewModel.vote(on: post, upvote: isUpvote)
        } catch {
            // Revert optimistic update
            post.upvoted = !isUpvote
            post.score += isUpvote ? -1 : 1

            if let hackersError = error as? HackersKitError {
                switch hackersError {
                case .unauthenticated:
                    showingAuthenticationDialog = true
                default:
                    voteErrorMessage = "Failed to vote. Please try again."
                    showingVoteError = true
                }
            } else {
                voteErrorMessage = "Failed to vote. Please try again."
                showingVoteError = true
            }
        }
    }

    private func handleLinkTap(post: Post) {
        guard !post.url.absoluteString.starts(with: "item?id=") else {
            navigationStore.showPost(post)
            return
        }

        LinkOpener.openURL(post.url, with: post, showCommentsButton: true)
    }

    private func sharePost(_ post: Post) {
        ShareService.shared.sharePost(post)
    }
}

struct PostRowView: View {
    @ObservedObject var post: Post
    let onVote: ((Post) -> Void)?
    let onLinkTap: ((Post) -> Void)?
    let onCommentsTap: ((Post) -> Void)?
    let navigationStore: NavigationStore
    let isSidebar: Bool

    init(post: Post,
         navigationStore: NavigationStore,
         isSidebar: Bool = false,
         onVote: ((Post) -> Void)? = nil,
         onLinkTap: ((Post) -> Void)? = nil,
         onCommentsTap: ((Post) -> Void)? = nil) {
        self.post = post
        self.navigationStore = navigationStore
        self.isSidebar = isSidebar
        self.onVote = onVote
        self.onLinkTap = onLinkTap
        self.onCommentsTap = onCommentsTap
    }

    var body: some View {
        postContent
            .swipeActions(edge: .leading, allowsFullSwipe: true) {
                if UserDefaults.standard.swipeActionsEnabled {
                    if post.upvoted {
                        // Only show unvote if unvote link is available
                        if post.voteLinks?.unvote != nil {
                            Button {
                                onVote?(post)
                            } label: {
                                Image(systemName: "arrow.uturn.down")
                            }
                            .tint(.secondary)
                        }
                    } else {
                        // Show upvote button
                        Button {
                            onVote?(post)
                        } label: {
                            Image(systemName: "arrow.up")
                        }
                        .tint(Color("upvotedColor"))
                    }
                }
            }
    }

    private var postContent: some View {
        PostDisplayView(
            post: post,
            showVoteButton: false,
            showPostText: false,
            onLinkTap: { onLinkTap?(post) },
            onThumbnailTap: { onLinkTap?(post) }
        )
    }
}

// SwiftUI-compatible FeedViewModel
class SwiftUIFeedViewModel: ObservableObject {
    @Published var posts: [Post] = []
    @Published var isLoading = false
    @Published var isLoadingMore = false

    var postType: PostType = .news {
        didSet {
            if postType != oldValue {
                feedViewModel.postType = postType
            }
        }
    }

    private let feedViewModel = FeedViewModel()

    @MainActor
    func loadFeed() async {
        guard !isLoading else { return }

        isLoading = true
        feedViewModel.postType = postType
        feedViewModel.reset()

        do {
            try await feedViewModel.fetchFeed()
            posts = feedViewModel.posts
        } catch {
            print("Error loading feed: \(error)")
            // TODO: Add error state handling
        }

        isLoading = false
    }

    @MainActor
    func loadNextPage() async {
        guard !isLoading && !isLoadingMore && !feedViewModel.isFetching else { return }

        isLoadingMore = true

        do {
            try await feedViewModel.fetchFeed(fetchNextPage: true)
            posts = feedViewModel.posts
        } catch {
            print("Error loading next page: \(error)")
        }

        isLoadingMore = false
    }

    func vote(on post: Post, upvote: Bool) async throws {
        try await feedViewModel.vote(on: post, upvote: upvote)
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
