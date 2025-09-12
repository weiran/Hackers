//
//  FeedView.swift
//  Feed
//
//  Copyright © 2025 Weiran Zhang. All rights reserved.
//

import SwiftUI
import Domain
import Shared
import DesignSystem

public struct FeedView<NavigationStore: NavigationStoreProtocol, AuthService: AuthenticationServiceProtocol>: View {
    @State private var viewModel: FeedViewModel
    @State private var votingViewModel: VotingViewModel
    @State private var selectedPostType: Domain.PostType = .news
    @State private var selectedPostId: Int?
    @EnvironmentObject private var navigationStore: NavigationStore
    @EnvironmentObject private var authService: AuthService

    let isSidebar: Bool

    public init(
        viewModel: FeedViewModel = FeedViewModel(),
        votingViewModel: VotingViewModel? = nil,
        isSidebar: Bool = false
    ) {
        self._viewModel = State(initialValue: viewModel)
        let container = DependencyContainer.shared
        let defaultVotingViewModel = VotingViewModel(
            votingService: container.getVotingService(),
            commentVotingService: container.getCommentVotingService()
        )
        self._votingViewModel = State(initialValue: votingViewModel ?? defaultVotingViewModel)
        self.isSidebar = isSidebar
    }

    private var selectionBinding: Binding<Int?> {
        if isSidebar {
            Binding(
                get: { selectedPostId },
                set: { newPostId in
                    if let postId = newPostId,
                       let selectedPost = viewModel.posts.first(where: { $0.id == postId }) {
                        selectedPostId = postId
                        navigationStore.showPost(selectedPost)
                    }
                }
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
            ToolbarItem(placement: .navigationBarLeading) {
                userButton
            }

            ToolbarItem(placement: .principal) {
                toolbarMenu
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                settingsButton
            }
        }
        .task { @Sendable in
            await viewModel.loadFeed()
        }
        .alert("Vote Error", isPresented: .constant(votingViewModel.lastError != nil)) {
            Button("OK") {
                votingViewModel.clearError()
            }
        } message: {
            Text(votingViewModel.lastError?.localizedDescription ?? "Failed to vote. Please try again.")
        }
    }

    @ViewBuilder
    private var contentView: some View {
        if viewModel.isLoading && viewModel.posts.isEmpty {
            ProgressView("Loading...")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            List(selection: selectionBinding) {
                ForEach(viewModel.posts, id: \.id) { post in
                    postRow(for: post)
                }
            }
            .listStyle(.plain)
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
            onLinkTap: { handleLinkTap(post: post) },
            onCommentsTap: { navigationStore.showPost(post) }
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
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            if !isSidebar {
                Button {
                    Task {
                        var mutablePost = post
                        await votingViewModel.toggleVote(for: &mutablePost)
                    }
                } label: {
                    Image(systemName: post.upvoted ? "arrow.uturn.down" : "arrow.up")
                }
                .tint(post.upvoted ? .secondary : AppColors.upvotedColor)
            }
        }
        .contextMenu {
            VotingContextMenuItems.postVotingMenuItems(
                for: post,
                onVote: {
                    Task {
                        var mutablePost = post
                        await votingViewModel.toggleVote(for: &mutablePost)
                    }
                }
            )

            Divider()

            if !post.url.absoluteString.starts(with: HackerNewsConstants.itemPrefix) {
                Button {
                    handleLinkTap(post: post)
                } label: {
                    Label("Open Link", systemImage: "safari")
                }
            }

            Button {
                ShareService.shared.sharePost(post)
            } label: {
                Label("Share", systemImage: "square.and.arrow.up")
            }
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
                    .foregroundColor(.primary)
                Text(selectedPostType.displayName)
                    .font(.headline)
                    .foregroundColor(.primary)
                Image(systemName: "chevron.down.circle.fill")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    @ViewBuilder
    private var userButton: some View {
        Button {
            navigationStore.showLogin()
        } label: {
            Image(systemName: authService.isAuthenticated ? "person.crop.circle.fill" : "person.crop.circle")
                .font(.headline)
                .foregroundColor(authService.isAuthenticated ? .primary : .secondary)
        }
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
    }


    private func handleLinkTap(post: Domain.Post) {
        guard !post.url.absoluteString.starts(with: HackerNewsConstants.itemPrefix) else {
            navigationStore.showPost(post)
            return
        }

        LinkOpener.openURL(post.url, with: nil)
    }
}

struct PostRowView: View {
    let post: Domain.Post
    let votingViewModel: VotingViewModel
    let onLinkTap: (() -> Void)?
    let onCommentsTap: (() -> Void)?

    init(post: Domain.Post,
         votingViewModel: VotingViewModel,
         onLinkTap: (() -> Void)? = nil,
         onCommentsTap: (() -> Void)? = nil) {
        self.post = post
        self.votingViewModel = votingViewModel
        self.onLinkTap = onLinkTap
        self.onCommentsTap = onCommentsTap
    }

    var body: some View {
        PostDisplayView(
            post: post,
            votingState: votingViewModel.votingState(for: post),
            showPostText: false,
            onThumbnailTap: onLinkTap
        )
        .contentShape(Rectangle())
        .onTapGesture {
            onCommentsTap?()
        }
    }
}

extension View {
    @ViewBuilder
    func `if`<Transform: View>(_ condition: Bool, transform: (Self) -> Transform) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}
