//
//  CommentsView.swift
//  Comments
//
//  Copyright © 2025 Weiran Zhang. All rights reserved.
//

import DesignSystem
import Domain
import Shared
import SwiftUI

public struct CommentsView<NavigationStore: NavigationStoreProtocol>: View {
    @State private var viewModel: CommentsViewModel
    @State private var votingViewModel: VotingViewModel
    @State private var showTitle = false
    @State private var hasMeasuredInitialOffset = false
    @State private var visibleCommentPositions: [Int: CGRect] = [:]
    @State private var navigateToPostId: Int?
    @EnvironmentObject private var navigationStore: NavigationStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    public init(post: Post, viewModel: CommentsViewModel? = nil, votingViewModel: VotingViewModel? = nil) {
        _viewModel = State(initialValue: viewModel ?? CommentsViewModel(post: post))
        let container = DependencyContainer.shared
        let defaultVotingViewModel = VotingViewModel(
            votingService: container.getVotingService(),
            commentVotingService: container.getCommentVotingService(),
        )
        _votingViewModel = State(initialValue: votingViewModel ?? defaultVotingViewModel)
    }

    public var body: some View {
        CommentsContentView(
            viewModel: viewModel,
            votingViewModel: votingViewModel,
            showTitle: $showTitle,
            hasMeasuredInitialOffset: $hasMeasuredInitialOffset,
            visibleCommentPositions: $visibleCommentPositions,
            navigateToPostId: $navigateToPostId,
            handleLinkTap: handleLinkTap,
            toggleCommentVisibility: toggleCommentVisibility,
        )
        .navigationTitle("Comments")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                ToolbarTitle(
                    post: viewModel.post,
                    showTitle: showTitle,
                    onTap: handleLinkTap,
                )
            }
            ToolbarItem(placement: .navigationBarTrailing) { ShareMenu(post: viewModel.post) }
        }
        .task {
            votingViewModel.navigationStore = navigationStore
            await viewModel.loadComments()
        }
        .refreshable { await viewModel.refreshComments() }
        .environment(\.openURL, OpenURLAction { url in
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
        LinkOpener.openURL(viewModel.post.url, with: viewModel.post)
    }

    private func toggleCommentVisibility(_ comment: Comment, scrollTo: @escaping (String) -> Void) {
        withAnimation(.easeInOut(duration: 0.3)) {
            let wasVisible = comment.visibility == .visible
            viewModel.toggleCommentVisibility(comment)
            if wasVisible, !isCommentVisibleOnScreen(comment) {
                withAnimation(.easeInOut(duration: 0.3)) { scrollTo("comment-\(comment.id)") }
            }
        }
    }

    private func isCommentVisibleOnScreen(_ comment: Comment) -> Bool {
        guard let commentFrame = visibleCommentPositions[comment.id] else { return false }
        guard let window = PresentationService.shared.windowScene?.windows.first else { return false }
        let screenBounds = window.bounds
        return screenBounds.contains(CGPoint(x: commentFrame.midX, y: commentFrame.minY))
    }
}
