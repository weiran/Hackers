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

public struct CommentsView<NavigationStore: NavigationStoreProtocol>: View {
    @State private var viewModel: CommentsViewModel
    @State private var votingViewModel: VotingViewModel
    @State private var showTitle = false
    @State private var hasMeasuredInitialOffset = false
    @State private var visibleCommentPositions: [Int: CGRect] = [:]
    @State private var pendingCommentID: Int?
    @State private var listAnimationsEnabled = false
    @EnvironmentObject private var navigationStore: NavigationStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    public init(
        postID: Int,
        initialPost: Post? = nil,
        targetCommentID: Int? = nil,
        viewModel: CommentsViewModel? = nil,
        votingViewModel: VotingViewModel? = nil
    ) {
        _pendingCommentID = State(initialValue: targetCommentID ?? (initialPost == nil ? postID : nil))
        if let viewModel {
            _viewModel = State(initialValue: viewModel)
        } else {
            _viewModel = State(initialValue: CommentsViewModel(postID: postID, initialPost: initialPost))
        }
        let container = DependencyContainer.shared
        let defaultVotingViewModel = VotingViewModel(
            votingService: container.getVotingService(),
            commentVotingService: container.getCommentVotingService(),
            authenticationUseCase: container.getAuthenticationUseCase()
        )
        _votingViewModel = State(initialValue: votingViewModel ?? defaultVotingViewModel)
    }

    public init(
        post: Post,
        targetCommentID: Int? = nil,
        viewModel: CommentsViewModel? = nil,
        votingViewModel: VotingViewModel? = nil
    ) {
        self.init(
            postID: post.id,
            initialPost: post,
            targetCommentID: targetCommentID,
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
                        onTap: handleLinkTap,
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
            await viewModel.loadComments()
            if let targetID = pendingCommentID {
                _ = await viewModel.revealComment(withId: targetID)
            }
        }
        .refreshable {
            await viewModel.refreshComments()
            if let targetID = pendingCommentID {
                _ = await viewModel.revealComment(withId: targetID)
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
        .onAppear { votingViewModel.navigationStore = navigationStore }
    }

    private func handleLinkTap() {
        guard let post = viewModel.post else { return }
        if navigationStore.openURLInPrimaryContext(post.url) {
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
            DispatchQueue.main.async {
                withAnimation(.easeInOut(duration: 0.3)) {
                    scrollTo("comment-\(comment.id)")
                }
                listAnimationsEnabled = false
            }
        } else {
            DispatchQueue.main.async { listAnimationsEnabled = false }
        }
    }

    private func hideCommentBranch(_ comment: Comment, scrollTo: @escaping (String) -> Void) {
        listAnimationsEnabled = true
        let collapsedRoot = withAnimation(.easeInOut(duration: 0.3)) {
            viewModel.hideCommentBranch(comment)
        }

        DispatchQueue.main.async {
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
