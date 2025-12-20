//
//  CommentsView.swift
//  Comments
//
//  Copyright © 2025 Weiran Zhang. All rights reserved.
//

import DesignSystem
import Domain
import Foundation
import Shared
import SwiftUI

public struct CommentsView<Store: NavigationStoreProtocol>: View {
    @State private var viewModel: CommentsViewModel
    @State private var votingViewModel: VotingViewModel
    private let showsPostHeader: Bool
    private let allowsRefresh: Bool
    @State private var showTitle = false
    @State private var hasMeasuredInitialOffset = false
    @State private var visibleCommentPositions: [Int: CGRect] = [:]
    @State private var pendingCommentID: Int?
    @State private var listAnimationsEnabled = false
    @Environment(Store.self) private var navigationStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    public init(
        postID: Int,
        initialPost: Post? = nil,
        targetCommentID: Int? = nil,
        showsPostHeader: Bool = true,
        allowsRefresh: Bool = true,
        viewModel: CommentsViewModel? = nil,
        votingViewModel: VotingViewModel? = nil
    ) {
        self.showsPostHeader = showsPostHeader
        self.allowsRefresh = allowsRefresh
        _pendingCommentID = State(initialValue: targetCommentID ?? (initialPost == nil ? postID : nil))
        if let viewModel {
            _viewModel = State(initialValue: viewModel)
        } else {
            _viewModel = State(initialValue: CommentsViewModel(postID: postID, initialPost: initialPost))
        }
        let container = DependencyContainer.shared
        let defaultVotingViewModel = VotingViewModel(
            votingStateProvider: container.getVotingStateProvider(),
            commentVotingStateProvider: container.getCommentVotingStateProvider(),
            authenticationUseCase: container.getAuthenticationUseCase()
        )
        _votingViewModel = State(initialValue: votingViewModel ?? defaultVotingViewModel)
    }

    public init(
        post: Post,
        targetCommentID: Int? = nil,
        showsPostHeader: Bool = true,
        allowsRefresh: Bool = true,
        viewModel: CommentsViewModel? = nil,
        votingViewModel: VotingViewModel? = nil
    ) {
        self.init(
            postID: post.id,
            initialPost: post,
            targetCommentID: targetCommentID,
            showsPostHeader: showsPostHeader,
            allowsRefresh: allowsRefresh,
            viewModel: viewModel,
            votingViewModel: votingViewModel
        )
    }

    public var body: some View {
        Group {
            if let post = viewModel.post {
                CommentsContentView(
                    viewModel: viewModel,
                    votingViewModel: votingViewModel,
                    showsPostHeader: showsPostHeader,
                    showTitle: $showTitle,
                    visibleCommentPositions: $visibleCommentPositions,
                    pendingCommentID: $pendingCommentID,
                    listAnimationsEnabled: $listAnimationsEnabled,
                    handleLinkTap: handleLinkTap,
                    toggleCommentVisibility: toggleCommentVisibility,
                    hideCommentBranch: hideCommentBranch,
                )
            } else if viewModel.isPostLoading {
                AppLoadingStateView(message: "Loading...")
            } else if let error = viewModel.error {
                AppEmptyStateView(
                    iconSystemName: "exclamationmark.triangle",
                    title: "Unable to load post",
                    subtitle: error.localizedDescription
                )
            } else {
                AppLoadingStateView(message: "Loading...")
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                if let post = viewModel.post {
                    ToolbarTitle(
                        post: post,
                        showTitle: showTitle,
                        showThumbnails: viewModel.showThumbnails,
                        onTap: handleLinkTap,
                    )
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                if let post = viewModel.post {
                    BookmarkToolbarButton(
                        isBookmarked: post.isBookmarked,
                        toggleBookmark: { await viewModel.toggleBookmark() }
                    )
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                if let post = viewModel.post {
                    ShareMenu(post: post)
                }
            }
        }
        .task {
            votingViewModel.navigationStore = navigationStore
            // Set up callback to update navigation store when post changes
            viewModel.onPostUpdated = { [weak navigationStore] updatedPost in
                if let updatedPost {
                    navigationStore?.selectedPost = updatedPost
                }
            }
            await viewModel.loadComments()
            if let targetID = pendingCommentID {
                _ = await viewModel.revealComment(withId: targetID)
            }
        }
        .if(allowsRefresh) { view in
            view.refreshable {
                await viewModel.refreshComments()
                if let targetID = pendingCommentID {
                    _ = await viewModel.revealComment(withId: targetID)
                }
            }
        }
        .environment(\.openURL, OpenURLAction { url in
            if handleHackerNewsPostLink(url) {
                return .handled
            }
            if navigationStore.openURLInPrimaryContext(url) {
                return .handled
            }
            LinkOpener.openURL(url, with: viewModel.post)
            return .handled
        })
        .alert(
            "Vote Error",
            isPresented: Binding(
                get: { votingViewModel.lastError != nil },
                set: { newValue in if newValue == false { votingViewModel.clearError() } },
            ),
        ) {
            Button("OK") { votingViewModel.clearError() }
        } message: {
            Text(votingViewModel.lastError?.localizedDescription ?? "Failed to vote. Please try again.")
        }
        .task { @MainActor in
            votingViewModel.navigationStore = navigationStore
        }
    }

    private func handleLinkTap() {
        guard let post = viewModel.post else { return }
        if navigationStore.openURLInPrimaryContext(post.url) {
            return
        }
        let mode = DependencyContainer.shared.getSettingsUseCase().linkBrowserMode
        if mode == .customBrowser, UIDevice.current.userInterfaceIdiom != .pad {
            navigationStore.showPostLink(post)
            return
        }
        LinkOpener.openURL(post.url, with: post)
    }

    private func handleHackerNewsPostLink(_ url: URL) -> Bool {
        guard let itemId = CommentsLinkNavigator.hackerNewsItemID(from: url) else { return false }

        if viewModel.revealComment(withId: itemId) {
            pendingCommentID = itemId
            return true
        }

        if let currentPostId = viewModel.post?.id, currentPostId == itemId {
            return true
        }

        navigationStore.showPost(withId: itemId)
        return true
    }

    private func toggleCommentVisibility(_ comment: Comment, scrollTo: @escaping (String) -> Void) {
        listAnimationsEnabled = true
        let wasVisible = comment.visibility == .visible

        withAnimation(.easeInOut(duration: 0.3)) {
            viewModel.toggleCommentVisibility(comment)
        }

        if wasVisible, !isCommentVisibleOnScreen(comment) {
            Task { @MainActor in
                withAnimation(.easeInOut(duration: 0.3)) {
                    scrollTo("comment-\(comment.id)")
                }
                listAnimationsEnabled = false
            }
        } else {
            Task { @MainActor in listAnimationsEnabled = false }
        }
    }

    private func hideCommentBranch(_ comment: Comment, scrollTo: @escaping (String) -> Void) {
        listAnimationsEnabled = true
        let collapsedRoot = withAnimation(.easeInOut(duration: 0.3)) {
            viewModel.hideCommentBranch(comment)
        }

        Task { @MainActor in
            if let root = collapsedRoot {
                withAnimation(.easeInOut(duration: 0.3)) {
                    scrollTo("comment-\(root.id)")
                }
            }
            listAnimationsEnabled = false
        }
    }

    private func isCommentVisibleOnScreen(_ comment: Comment) -> Bool {
        guard let commentFrame = visibleCommentPositions[comment.id] else { return false }
        guard let window = PresentationContextProvider.shared.windowScene?.windows.first else { return false }
        let screenBounds = window.bounds
        return screenBounds.contains(CGPoint(x: commentFrame.midX, y: commentFrame.minY))
    }
}

enum CommentsLinkNavigator {
    static func hackerNewsItemID(from url: URL) -> Int? {
        guard url.host == HackerNewsConstants.host else { return nil }
        guard url.path == "/item" else { return nil }
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true) else { return nil }
        return components.queryItems?.first(where: { $0.name == "id" })?.value.flatMap(Int.init)
    }
}
