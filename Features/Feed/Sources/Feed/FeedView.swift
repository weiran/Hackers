//
//  FeedView.swift
//  Feed
//
//  Copyright © 2025 Weiran Zhang. All rights reserved.
//

import DesignSystem
import Domain
import Shared
import SwiftUI

public struct FeedView<Store: NavigationStoreProtocol>: View {
    @State private var viewModel: FeedViewModel
    @State private var votingViewModel: VotingViewModel
    @State private var selectedPostType: Domain.PostType
    @State private var selectedPostId: Int?
    @State private var searchText: String
    @Environment(Store.self) private var navigationStore

    let isSidebar: Bool

    private var primaryPostTypes: [Domain.PostType] {
        [.news, .ask, .show, .jobs, .newest, .best, .active]
    }

    private var secondaryPostTypes: [Domain.PostType] {
        [.bookmarks]
    }

    private var shouldShowBookmarksEmptyState: Bool {
        viewModel.postType == .bookmarks && viewModel.posts.isEmpty && !viewModel.isLoading && !viewModel.hasActiveSearch
    }

    public init(
        viewModel: FeedViewModel = FeedViewModel(),
        votingViewModel: VotingViewModel? = nil,
        isSidebar: Bool = false
    ) {
        _viewModel = State(initialValue: viewModel)
        _selectedPostType = State(initialValue: viewModel.postType)
        let container = DependencyContainer.shared
        let defaultVotingViewModel = VotingViewModel(
            votingStateProvider: container.getVotingStateProvider(),
            commentVotingStateProvider: container.getCommentVotingStateProvider(),
            authenticationUseCase: container.getAuthenticationUseCase()
        )
        _votingViewModel = State(initialValue: votingViewModel ?? defaultVotingViewModel)
        _searchText = State(initialValue: viewModel.searchQuery)
        self.isSidebar = isSidebar
    }

    private var selectionBinding: Binding<Int?> {
        if isSidebar {
            Binding(
                get: { selectedPostId },
                set: { newPostId in
                    if let postId = newPostId,
                       let selectedPost = viewModel.posts.first(where: { $0.id == postId })
                    {
                        selectedPostId = postId
                        navigationStore.showPost(selectedPost)
                    }
                },
            )
        } else {
            .constant(nil)
        }
    }

    public var body: some View {
        contentView
            .navigationTitle(viewModel.hasActiveSearch ? "Search" : selectedPostType.displayName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    settingsButton
                }
                ToolbarSpacer(.flexible, placement: .bottomBar)
                DefaultToolbarItem(kind: .search, placement: .bottomBar)
            }
            .toolbarTitleMenu {
                postTypeTitleMenu
            }
            .searchable(text: $searchText, placement: .toolbar, prompt: "Search Hacker News")
            .searchToolbarBehavior(.minimize)
            .onChange(of: searchText) { _, newValue in
                viewModel.updateSearchQuery(newValue)
            }
            .onChange(of: viewModel.searchQuery) { _, newValue in
                if newValue != searchText {
                    searchText = newValue
                }
            }
            .onChange(of: selectedPostType) { _, _ in
                // Clear selection when category changes to prevent stale sidebar selection
                selectedPostId = nil
            }
        .task { @Sendable in
            // Set the navigation store for the voting view model
            votingViewModel.navigationStore = navigationStore
            await viewModel.loadFeed()
        }
        .onChange(of: navigationStore.selectedPost) { oldPost, newPost in
            // When selectedPost changes in navigation store (e.g., from comments view),
            // update it in the feed
            if let updatedPost = newPost {
                viewModel.replacePost(updatedPost)
            }
        }
        .alert(
            "Vote Error",
            isPresented: Binding(
                get: { votingViewModel.lastError != nil },
                set: { newValue in
                    if newValue == false { votingViewModel.clearError() }
                },
            ),
        ) {
            Button("OK") { votingViewModel.clearError() }
        } message: {
            Text(votingViewModel.lastError?.localizedDescription ?? "Failed to vote. Please try again.")
        }
        .onAppear {
            // Ensure the navigation store is set
            votingViewModel.navigationStore = navigationStore
        }
    }

    @ViewBuilder
    private var contentView: some View {
        Group {
            if viewModel.hasActiveSearch {
                searchContentView
            } else if viewModel.isLoading && viewModel.posts.isEmpty && viewModel.postType != .bookmarks {
                AppLoadingStateView(message: "Loading...")
            } else if shouldShowBookmarksEmptyState {
                AppEmptyStateView(
                    iconSystemName: "bookmark",
                    title: "No bookmarks yet",
                    subtitle: "Save stories to keep them here."
                )
            } else {
                feedListView(posts: viewModel.posts, enablePagination: true)
                    .refreshable {
                        await viewModel.refreshFeed()
                    }
            }
        }
        .animation(.default, value: viewModel.hasActiveSearch)
    }

    @ViewBuilder
    private var searchContentView: some View {
        if viewModel.isSearchInProgress {
            ProgressView("Searching...")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let error = viewModel.searchError {
            AppEmptyStateView(
                iconSystemName: "exclamationmark.triangle",
                title: "Search Failed",
                subtitle: error.localizedDescription
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if viewModel.searchResults.isEmpty {
            AppEmptyStateView(
                iconSystemName: "magnifyingglass",
                title: "No Results",
                subtitle: "Try a different query."
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            feedListView(posts: viewModel.searchResults, enablePagination: false)
        }
    }

    private func feedListView(posts: [Domain.Post], enablePagination: Bool) -> some View {
        List(selection: selectionBinding) {
            ForEach(posts, id: \.id) { post in
                postRow(for: post, enablePagination: enablePagination)
            }
        }
        .if(isSidebar) { view in view.listStyle(.sidebar) }
        .if(!isSidebar) { view in view.listStyle(.plain) }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .id(selectedPostType)
    }

    @ViewBuilder
    private func postRow(for post: Domain.Post, enablePagination: Bool = true) -> some View {
        PostRowView(
            post: post,
            votingViewModel: votingViewModel,
            showThumbnails: viewModel.showThumbnails,
            compactMode: viewModel.compactFeedDesign,
            onLinkTap: { handleLinkTap(post: post) },
            onCommentsTap: isSidebar ? nil : { navigationStore.showPost(post) },
            onPostUpdated: { updatedPost in
                viewModel.replacePost(updatedPost)
            },
            onBookmarkToggle: {
                await viewModel.toggleBookmark(for: post)
            }
        )
        .if(isSidebar) { view in
            view.tag(post.id)
        }
        .onAppear {
            guard enablePagination else { return }
            if post == viewModel.posts.last {
                Task {
                    await viewModel.loadNextPage()
                }
            }
        }
        .if((post.voteLinks?.upvote != nil && !post.upvoted) || (post.voteLinks?.unvote != nil && post.upvoted)) { view in
            view.swipeActions(edge: .leading, allowsFullSwipe: true) {
                voteSwipeAction(for: post)
            }
        }
        .listRowSeparator(.hidden, edges: .top)
        .listRowSeparator(.visible, edges: .bottom)
        .contextMenu { contextMenuContent(for: post) }
    }

    @ViewBuilder
    private func voteSwipeAction(for post: Domain.Post) -> some View {
        if post.upvoted && post.voteLinks?.unvote != nil {
            // Unvote action
            Button {
                Task {
                    var mutablePost = post
                    await votingViewModel.unvote(post: &mutablePost)
                    await MainActor.run {
                        if !mutablePost.upvoted {
                            if let existingLinks = mutablePost.voteLinks {
                                mutablePost.voteLinks = VoteLinks(upvote: existingLinks.upvote, unvote: nil)
                            }
                            viewModel.replacePost(mutablePost)
                        }
                    }
                }
            } label: {
                Image(systemName: "arrow.uturn.down")
            }
            .tint(.orange)
            .accessibilityLabel("Unvote")
        } else {
            // Upvote action
            Button {
                Task {
                    var mutablePost = post
                    await votingViewModel.upvote(post: &mutablePost)
                    await MainActor.run {
                        if mutablePost.upvoted {
                            viewModel.replacePost(mutablePost)
                        }
                    }
                }
            } label: {
                Image(systemName: "arrow.up")
            }
            .tint(AppColors.upvotedColor)
            .accessibilityLabel("Upvote")
        }
    }

    @ViewBuilder
    private func contextMenuContent(for post: Domain.Post) -> some View {
        VotingContextMenuItems.postVotingMenuItems(
            for: post,
            onVote: {
                Task {
                    var mutablePost = post
                    await votingViewModel.upvote(post: &mutablePost)
                    await MainActor.run {
                        if mutablePost.upvoted {
                            viewModel.replacePost(mutablePost)
                        }
                    }
                }
            },
            onUnvote: {
                Task {
                    var mutablePost = post
                    await votingViewModel.unvote(post: &mutablePost)
                    await MainActor.run {
                        if !mutablePost.upvoted {
                            if let existingLinks = mutablePost.voteLinks {
                                mutablePost.voteLinks = VoteLinks(upvote: existingLinks.upvote, unvote: nil)
                            }
                            viewModel.replacePost(mutablePost)
                        }
                    }
                }
            }
        )

        Divider()

        if !isHackerNewsItemURL(post.url) {
            Button { handleLinkTap(post: post) } label: {
                Label("Open Link", systemImage: "safari")
            }
        }

        Button {
            Task {
                _ = await viewModel.toggleBookmark(for: post)
            }
        } label: {
            Label(
                post.isBookmarked ? "Remove Bookmark" : "Save Bookmark",
                systemImage: post.isBookmarked ? "bookmark.slash" : "bookmark"
            )
        }

        Button { ContentSharePresenter.shared.sharePost(post) } label: {
            Label("Share", systemImage: "square.and.arrow.up")
        }
    }

    @ViewBuilder
    private var postTypeTitleMenu: some View {
        ForEach(primaryPostTypes, id: \.self) { postType in
            postTypeMenuButton(for: postType)
        }
        if !secondaryPostTypes.isEmpty {
            Divider()
            ForEach(secondaryPostTypes, id: \.self) { postType in
                postTypeMenuButton(for: postType)
            }
        }
    }

    @ViewBuilder
    private var settingsButton: some View {
        Button {
            navigationStore.showSettings()
        } label: {
            Image(systemName: "gearshape")
                .font(.headline)
                .foregroundStyle(.primary)
        }
        .accessibilityLabel("Settings")
    }

    @ViewBuilder
    private func postTypeMenuButton(for postType: Domain.PostType) -> some View {
        Button {
            selectedPostType = postType
            Task {
                await viewModel.changePostType(postType)
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

    private func handleLinkTap(post: Domain.Post) {
        guard !isHackerNewsItemURL(post.url) else {
            navigationStore.showPost(post)
            return
        }

        if isSidebar {
            navigationStore.showPost(post)
            selectedPostId = post.id
        }

        if navigationStore.openURLInPrimaryContext(post.url, pushOntoDetailStack: !isSidebar) {
            return
        }
        LinkOpener.openURL(post.url, with: nil)
    }

    private func isHackerNewsItemURL(_ url: URL) -> Bool {
        guard let hnHost = url.host else { return false }
        return hnHost == Shared.HackerNewsConstants.host && url.path == "/item"
    }
}

struct PostRowView: View {
    let post: Domain.Post
    let votingViewModel: VotingViewModel
    let onLinkTap: (() -> Void)?
    let onCommentsTap: (() -> Void)?
    let showThumbnails: Bool
    let compactMode: Bool
    let onPostUpdated: ((Domain.Post) -> Void)?
    let onBookmarkToggle: (() async -> Bool)?

    init(post: Domain.Post,
         votingViewModel: VotingViewModel,
         showThumbnails: Bool = true,
         compactMode: Bool = false,
         onLinkTap: (() -> Void)? = nil,
         onCommentsTap: (() -> Void)? = nil,
         onPostUpdated: ((Domain.Post) -> Void)? = nil,
         onBookmarkToggle: (() async -> Bool)? = nil)
    {
        self.post = post
        self.votingViewModel = votingViewModel
        self.onLinkTap = onLinkTap
        self.onCommentsTap = onCommentsTap
        self.showThumbnails = showThumbnails
        self.compactMode = compactMode
        self.onPostUpdated = onPostUpdated
        self.onBookmarkToggle = onBookmarkToggle
    }

    var body: some View {
        if let onCommentsTap {
            Button(action: onCommentsTap) {
                PostDisplayView(
                    post: post,
                    votingState: votingViewModel.votingState(for: post),
                    showPostText: false,
                    showThumbnails: showThumbnails,
                    compactMode: compactMode,
                    onThumbnailTap: onLinkTap,
                    onUpvoteTap: { await handleUpvoteTap() },
                    onUnvoteTap: { await handleUnvoteTap() },
                    onBookmarkTap: {
                        guard let onBookmarkToggle else { return post.isBookmarked }
                        return await onBookmarkToggle()
                    },
                    onCommentsTap: onCommentsTap
                )
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityAddTraits(.isButton)
            .accessibilityHint("Open comments")
        } else {
            PostDisplayView(
                post: post,
                votingState: votingViewModel.votingState(for: post),
                showPostText: false,
                showThumbnails: showThumbnails,
                compactMode: compactMode,
                onThumbnailTap: onLinkTap,
                onUpvoteTap: { await handleUpvoteTap() },
                onUnvoteTap: { await handleUnvoteTap() },
                onBookmarkTap: {
                    guard let onBookmarkToggle else { return post.isBookmarked }
                    return await onBookmarkToggle()
                },
                onCommentsTap: onCommentsTap
            )
            .contentShape(Rectangle())
        }
    }

    private func handleUpvoteTap() async -> Bool {
        guard votingViewModel.canVote(item: post), !post.upvoted else { return false }

        var mutablePost = post
        await votingViewModel.upvote(post: &mutablePost)
        let wasUpvoted = mutablePost.upvoted

        if wasUpvoted {
            await MainActor.run {
                onPostUpdated?(mutablePost)
            }
        }

        return wasUpvoted
    }

    private func handleUnvoteTap() async -> Bool {
        guard votingViewModel.canUnvote(item: post), post.upvoted else { return true }

        var mutablePost = post
        await votingViewModel.unvote(post: &mutablePost)
        let wasUnvoted = !mutablePost.upvoted

        if wasUnvoted {
            if let existingLinks = mutablePost.voteLinks {
                mutablePost.voteLinks = VoteLinks(upvote: existingLinks.upvote, unvote: nil)
            }
            await MainActor.run {
                onPostUpdated?(mutablePost)
            }
        }

        return wasUnvoted
    }
}
