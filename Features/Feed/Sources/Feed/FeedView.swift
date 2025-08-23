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
    @State private var selectedPostType: Domain.PostType = .news
    @State private var selectedPostId: Int?
    @State private var showingVoteError = false
    @State private var voteErrorMessage = ""
    @State private var showingAuthenticationDialog = false
    @EnvironmentObject private var navigationStore: NavigationStore
    @EnvironmentObject private var authService: AuthService

    let isSidebar: Bool

    public init(
        viewModel: FeedViewModel = FeedViewModel(),
        isSidebar: Bool = false
    ) {
        self._viewModel = State(initialValue: viewModel)
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
        .alert("Vote Error", isPresented: $showingVoteError) {
            Button("OK") { }
        } message: {
            Text(voteErrorMessage)
        }
        .sheet(isPresented: $showingAuthenticationDialog) {
            Text("Please log in to vote")
                .onAppear {
                    navigationStore.showLogin()
                }
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
            onVote: {
                Task { await handleVote(post: post) }
            },
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
                    Task { await handleVote(post: post) }
                } label: {
                    Image(systemName: post.upvoted ? "arrow.uturn.down" : "arrow.up")
                }
                .tint(post.upvoted ? .secondary : AppColors.upvotedColor)
            }
        }
        .contextMenu {
            PostContextMenu(
                post: post,
                onVote: { Task { await handleVote(post: post) } },
                onOpenLink: { handleLinkTap(post: post) },
                onShare: { ShareService.shared.sharePost(post) }
            )
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
                Image(systemName: "chevron.down")
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

    @MainActor
    private func handleVote(post: Domain.Post) async {
        let isUpvote = !post.upvoted

        do {
            try await viewModel.vote(on: post, upvote: isUpvote)
        } catch {
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

    private func handleLinkTap(post: Domain.Post) {
        guard !post.url.absoluteString.starts(with: HackerNewsConstants.itemPrefix) else {
            navigationStore.showPost(post)
            return
        }

        LinkOpener.openURL(post.url, with: nil, showCommentsButton: false)
    }
}

struct PostRowView: View {
    let post: Domain.Post
    let onVote: (() -> Void)?
    let onLinkTap: (() -> Void)?
    let onCommentsTap: (() -> Void)?

    init(post: Domain.Post,
         onVote: (() -> Void)? = nil,
         onLinkTap: (() -> Void)? = nil,
         onCommentsTap: (() -> Void)? = nil) {
        self.post = post
        self.onVote = onVote
        self.onLinkTap = onLinkTap
        self.onCommentsTap = onCommentsTap
    }

    var body: some View {
        PostDisplayView(
            post: post,
            showPostText: false,
            showThumbnails: true,
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
