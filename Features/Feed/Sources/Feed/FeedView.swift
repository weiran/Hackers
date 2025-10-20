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

public struct FeedView<NavigationStore: NavigationStoreProtocol>: View {
    @State private var viewModel: FeedViewModel
    @State private var votingViewModel: VotingViewModel
    @State private var selectedPostType: Domain.PostType
    @State private var selectedPostId: Int?
    @EnvironmentObject private var navigationStore: NavigationStore

    let isSidebar: Bool

    public init(
        viewModel: FeedViewModel = FeedViewModel(),
        votingViewModel: VotingViewModel? = nil,
        isSidebar: Bool = false,
    ) {
        _viewModel = State(initialValue: viewModel)
        _selectedPostType = State(initialValue: viewModel.postType)
        let container = DependencyContainer.shared
        let defaultVotingViewModel = VotingViewModel(
            votingService: container.getVotingService(),
            commentVotingService: container.getCommentVotingService(),
            authenticationUseCase: container.getAuthenticationUseCase()
        )
        _votingViewModel = State(initialValue: votingViewModel ?? defaultVotingViewModel)
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
        NavigationStack {
            contentView
                .navigationBarTitleDisplayMode(.inline)
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                toolbarMenu
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                settingsButton
            }
        }
        .task { @Sendable in
            // Set the navigation store for the voting view model
            votingViewModel.navigationStore = navigationStore
            await viewModel.loadFeed()
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
        if viewModel.isLoading, viewModel.posts.isEmpty {
            AppLoadingStateView(message: "Loading...")
        } else {
            List(selection: selectionBinding) {
                ForEach(viewModel.posts, id: \.id) { post in
                    postRow(for: post)
                }
            }
            .if(isSidebar) { view in view.listStyle(.sidebar) }
            .if(!isSidebar) { view in view.listStyle(.plain) }
            .refreshable {
                await viewModel.refreshFeed()
            }
        }
    }

    @ViewBuilder
    private func postRow(for post: Domain.Post) -> some View {
        PostRowView(
            post: post,
            votingViewModel: votingViewModel,
            showThumbnails: viewModel.showThumbnails,
            onLinkTap: { handleLinkTap(post: post) },
            onCommentsTap: isSidebar ? nil : { navigationStore.showPost(post) },
            onUpvoteApplied: { postId in
                viewModel.applyLocalUpvote(to: postId)
            }
        )
        .if(isSidebar) { view in
            view.tag(post.id)
        }
        .onAppear {
            if post == viewModel.posts.last {
                Task {
                    await viewModel.loadNextPage()
                }
            }
        }
        .if(post.voteLinks?.upvote != nil && !post.upvoted) { view in
            view.swipeActions(edge: .leading, allowsFullSwipe: true) {
                voteSwipeAction(for: post)
            }
        }
        .contextMenu { contextMenuContent(for: post) }
    }

    @ViewBuilder
    private func voteSwipeAction(for post: Domain.Post) -> some View {
        Button {
            Task {
                var mutablePost = post
                await votingViewModel.upvote(post: &mutablePost)
                await MainActor.run {
                    if mutablePost.upvoted {
                        viewModel.applyLocalUpvote(to: post.id)
                    }
                }
            }
        } label: {
            Image(systemName: "arrow.up")
        }
        .tint(AppColors.upvotedColor)
        .accessibilityLabel("Upvote")
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
                            viewModel.applyLocalUpvote(to: post.id)
                        }
                    }
                }
            },
        )

        Divider()

        if !isHackerNewsItemURL(post.url) {
            Button { handleLinkTap(post: post) } label: {
                Label("Open Link", systemImage: "safari")
            }
        }

        Button { ContentSharePresenter.shared.sharePost(post) } label: {
            Label("Share", systemImage: "square.and.arrow.up")
        }
    }

    @ViewBuilder
    private var toolbarMenu: some View {
        Menu {
            ForEach(Domain.PostType.allCases, id: \.self) { postType in
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
        } label: {
            HStack(spacing: 4) {
                Image(systemName: selectedPostType.iconName)
                    .font(.headline)
                Text(selectedPostType.displayName)
                    .font(.headline)
                Image(systemName: "chevron.down")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .foregroundStyle(.primary)
        }
        .padding(.horizontal, 10)
        // hacky way to adapt to iPad toolbar height being smaller
        .padding(.vertical, UIDevice.current.userInterfaceIdiom == .pad ? 4 : 8)
        .glassEffect()
        // hack to fix glitchy UI bug: https://github.com/weiran/Hackers/issues/313
        .clipShape(RoundedRectangle(cornerRadius: 32.0))
    }

    @ViewBuilder
    private var settingsButton: some View {
        Button {
            navigationStore.showSettings()
        } label: {
            Image(systemName: "gearshape")
                .font(.headline)
                .foregroundColor(.primary)
        }
        .accessibilityLabel("Settings")
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
    let onUpvoteApplied: ((Int) -> Void)?

    init(post: Domain.Post,
         votingViewModel: VotingViewModel,
         showThumbnails: Bool = true,
         onLinkTap: (() -> Void)? = nil,
         onCommentsTap: (() -> Void)? = nil,
         onUpvoteApplied: ((Int) -> Void)? = nil)
    {
        self.post = post
        self.votingViewModel = votingViewModel
        self.onLinkTap = onLinkTap
        self.onCommentsTap = onCommentsTap
        self.showThumbnails = showThumbnails
        self.onUpvoteApplied = onUpvoteApplied
    }

    var body: some View {
        PostDisplayView(
            post: post,
            votingState: votingViewModel.votingState(for: post),
            showPostText: false,
            showThumbnails: showThumbnails,
            onThumbnailTap: onLinkTap,
            onUpvoteTap: { await handleUpvoteTap() }
        )
        .contentShape(Rectangle())
        .if(onCommentsTap != nil) { view in
            view.onTapGesture {
                onCommentsTap?()
            }
        }
        .if(onCommentsTap != nil) { view in
            view
                .accessibilityAddTraits(.isButton)
                .accessibilityHint("Open comments")
        }
    }

    private func handleUpvoteTap() async -> Bool {
        guard votingViewModel.canVote(item: post), !post.upvoted else { return false }

        var mutablePost = post
        await votingViewModel.upvote(post: &mutablePost)
        let wasUpvoted = mutablePost.upvoted

        if wasUpvoted {
            await MainActor.run {
                onUpvoteApplied?(mutablePost.id)
            }
        }

        return wasUpvoted
    }
}
