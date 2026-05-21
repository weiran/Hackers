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

public enum CommentsPresentationState: Equatable, Sendable {
    case standard
    case customBrowser(topContentInset: CGFloat)

    var commentScrollTopInset: CGFloat {
        switch self {
        case .standard:
            0
        case let .customBrowser(topContentInset):
            max(topContentInset, 0)
        }
    }
}

public struct CommentsView<Store: NavigationStoreProtocol>: View {
    @Environment(Store.self) private var navigationStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    private let showsPostHeader: Bool
    private let allowsRefresh: Bool
    private let showsToolbar: Bool
    private let controlsNavigationBarVisibility: Bool
    private let presentationState: CommentsPresentationState
    private let titleVisible: Binding<Bool>?
    private let isAtTop: Binding<Bool>?
    private let onPostLinkTap: (() -> Void)?
    @State private var viewModel: CommentsViewModel
    @State private var votingViewModel: VotingViewModel
    @State private var showTitle = false
    @State private var hasMeasuredInitialOffset = false
    @State private var visibleCommentPositions: [Int: CGRect] = [:]
    @State private var pendingCommentID: Int?
    @State private var listAnimationsEnabled = false

    public init(
        postID: Int,
        initialPost: Post? = nil,
        targetCommentID: Int? = nil,
        showsPostHeader: Bool = true,
        allowsRefresh: Bool = true,
        showsToolbar: Bool = true,
        controlsNavigationBarVisibility: Bool = true,
        presentationState: CommentsPresentationState = .standard,
        titleVisible: Binding<Bool>? = nil,
        isAtTop: Binding<Bool>? = nil,
        onPostLinkTap: (() -> Void)? = nil,
        viewModel: CommentsViewModel? = nil,
        votingViewModel: VotingViewModel? = nil
    ) {
        self.showsPostHeader = showsPostHeader
        self.allowsRefresh = allowsRefresh
        self.showsToolbar = showsToolbar
        self.controlsNavigationBarVisibility = controlsNavigationBarVisibility
        self.presentationState = presentationState
        self.titleVisible = titleVisible
        self.isAtTop = isAtTop
        self.onPostLinkTap = onPostLinkTap
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
        showsToolbar: Bool = true,
        controlsNavigationBarVisibility: Bool = true,
        presentationState: CommentsPresentationState = .standard,
        titleVisible: Binding<Bool>? = nil,
        isAtTop: Binding<Bool>? = nil,
        onPostLinkTap: (() -> Void)? = nil,
        viewModel: CommentsViewModel? = nil,
        votingViewModel: VotingViewModel? = nil
    ) {
        self.init(
            postID: post.id,
            initialPost: post,
            targetCommentID: targetCommentID,
            showsPostHeader: showsPostHeader,
            allowsRefresh: allowsRefresh,
            showsToolbar: showsToolbar,
            controlsNavigationBarVisibility: controlsNavigationBarVisibility,
            presentationState: presentationState,
            titleVisible: titleVisible,
            isAtTop: isAtTop,
            onPostLinkTap: onPostLinkTap,
            viewModel: viewModel,
            votingViewModel: votingViewModel
        )
    }

    public var body: some View {
        Group {
            if let post = viewModel.post {
                CommentsContentView(
                    showsPostHeader: showsPostHeader,
                    handleLinkTap: handleLinkTap,
                    toggleCommentVisibility: toggleCommentVisibility,
                    hideCommentBranch: hideCommentBranch,
                    updateIsAtTop: { isAtTop?.wrappedValue = $0 },
                    updateTitleVisibility: { titleVisible?.wrappedValue = $0 },
                    presentationState: presentationState,
                    viewModel: viewModel,
                    votingViewModel: votingViewModel,
                    showTitle: $showTitle,
                    visibleCommentPositions: $visibleCommentPositions,
                    pendingCommentID: $pendingCommentID,
                    listAnimationsEnabled: $listAnimationsEnabled,
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
        .if(controlsNavigationBarVisibility) { view in
            view
                .navigationBarTitleDisplayMode(.inline)
                .toolbar(showsToolbar ? .visible : .hidden, for: .navigationBar)
                .toolbarBackground(.hidden, for: .navigationBar)
                .overlay(alignment: .top) {
                    if showsToolbar {
                        commentsHeaderBlur
                    }
                }
        }
        .toolbar {
            if controlsNavigationBarVisibility && showsToolbar {
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
                        ShareMenu(post: post)
                    }
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

    private var commentsHeaderBlur: some View {
        GeometryReader { proxy in
            ProgressiveHeaderBlurBackground(
                height: proxy.safeAreaInsets.top + 44,
                fadeExtension: 32
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .allowsHitTesting(false)
    }

    private func handleLinkTap() {
        if let onPostLinkTap {
            onPostLinkTap()
            return
        }
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

    private func toggleCommentVisibility(_ comment: Comment, scrollToComment: @escaping (Int) -> Void) {
        listAnimationsEnabled = true
        let wasVisible = comment.visibility == .visible

        withAnimation(.easeInOut(duration: 0.3)) {
            viewModel.toggleCommentVisibility(comment)
        }

        if wasVisible, !isCommentVisibleOnScreen(comment) {
            Task { @MainActor in
                withAnimation(.easeInOut(duration: 0.3)) {
                    scrollToComment(comment.id)
                }
                listAnimationsEnabled = false
            }
        } else {
            Task { @MainActor in listAnimationsEnabled = false }
        }
    }

    private func hideCommentBranch(_ comment: Comment, scrollToComment: @escaping (Int) -> Void) {
        listAnimationsEnabled = true
        let collapsedRoot = withAnimation(.easeInOut(duration: 0.3)) {
            viewModel.hideCommentBranch(comment)
        }

        Task { @MainActor in
            if let root = collapsedRoot {
                withAnimation(.easeInOut(duration: 0.3)) {
                    scrollToComment(root.id)
                }
            }
            listAnimationsEnabled = false
        }
    }

    private func isCommentVisibleOnScreen(_ comment: Comment) -> Bool {
        guard let commentFrame = visibleCommentPositions[comment.id] else { return false }
        guard let window = PresentationContextProvider.shared.windowScene?.windows.first else { return false }
        let visibleBounds = window.bounds.inset(
            by: UIEdgeInsets(top: presentationState.commentScrollTopInset, left: 0, bottom: 0, right: 0)
        )
        return visibleBounds.contains(CGPoint(x: commentFrame.midX, y: commentFrame.minY))
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
