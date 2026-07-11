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
    private let postHeaderMatchedGeometryNamespace: Namespace.ID?
    private let isPostHeaderMatchedGeometrySource: Bool
    private let titleVisible: Binding<Bool>?
    private let toolbarGeometry: CommentsToolbarGeometry?
    private let onPostLinkTap: (() -> Void)?
    private let onTitleDragChanged: ((DragGesture.Value) -> Void)?
    private let onTitleDragEnded: ((DragGesture.Value) -> Void)?
    private let onPostHeaderDragChanged: ((DragGesture.Value) -> Void)?
    private let onPostHeaderDragEnded: ((DragGesture.Value) -> Void)?
    @State private var viewModel: CommentsViewModel
    @State private var votingViewModel: VotingViewModel
    @State private var titleVisibility: CommentsHeaderTitleVisibility
    @State private var pendingCommentID: Int?

    public init(
        postID: Int,
        initialPost: Post? = nil,
        targetCommentID: Int? = nil,
        showsPostHeader: Bool = true,
        allowsRefresh: Bool = true,
        showsToolbar: Bool = true,
        controlsNavigationBarVisibility: Bool = true,
        presentationState: CommentsPresentationState = .standard,
        postHeaderMatchedGeometryNamespace: Namespace.ID? = nil,
        isPostHeaderMatchedGeometrySource: Bool = true,
        headerTitleVisibility: CommentsHeaderTitleVisibility? = nil,
        toolbarGeometry: CommentsToolbarGeometry? = nil,
        titleVisible: Binding<Bool>? = nil,
        onPostLinkTap: (() -> Void)? = nil,
        onTitleDragChanged: ((DragGesture.Value) -> Void)? = nil,
        onTitleDragEnded: ((DragGesture.Value) -> Void)? = nil,
        onPostHeaderDragChanged: ((DragGesture.Value) -> Void)? = nil,
        onPostHeaderDragEnded: ((DragGesture.Value) -> Void)? = nil,
        viewModel: CommentsViewModel? = nil,
        votingViewModel: VotingViewModel? = nil
    ) {
        self.showsPostHeader = showsPostHeader
        self.allowsRefresh = allowsRefresh
        self.showsToolbar = showsToolbar
        self.controlsNavigationBarVisibility = controlsNavigationBarVisibility
        self.presentationState = presentationState
        self.postHeaderMatchedGeometryNamespace = postHeaderMatchedGeometryNamespace
        self.isPostHeaderMatchedGeometrySource = isPostHeaderMatchedGeometrySource
        self.titleVisible = titleVisible
        self.toolbarGeometry = toolbarGeometry
        self.onPostLinkTap = onPostLinkTap
        self.onTitleDragChanged = onTitleDragChanged
        self.onTitleDragEnded = onTitleDragEnded
        self.onPostHeaderDragChanged = onPostHeaderDragChanged
        self.onPostHeaderDragEnded = onPostHeaderDragEnded
        _titleVisibility = State(initialValue: headerTitleVisibility ?? CommentsHeaderTitleVisibility())
        _pendingCommentID = State(initialValue: targetCommentID ?? (initialPost == nil && viewModel == nil ? postID : nil))
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
        postHeaderMatchedGeometryNamespace: Namespace.ID? = nil,
        isPostHeaderMatchedGeometrySource: Bool = true,
        headerTitleVisibility: CommentsHeaderTitleVisibility? = nil,
        toolbarGeometry: CommentsToolbarGeometry? = nil,
        titleVisible: Binding<Bool>? = nil,
        onPostLinkTap: (() -> Void)? = nil,
        onTitleDragChanged: ((DragGesture.Value) -> Void)? = nil,
        onTitleDragEnded: ((DragGesture.Value) -> Void)? = nil,
        onPostHeaderDragChanged: ((DragGesture.Value) -> Void)? = nil,
        onPostHeaderDragEnded: ((DragGesture.Value) -> Void)? = nil,
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
            postHeaderMatchedGeometryNamespace: postHeaderMatchedGeometryNamespace,
            isPostHeaderMatchedGeometrySource: isPostHeaderMatchedGeometrySource,
            headerTitleVisibility: headerTitleVisibility,
            toolbarGeometry: toolbarGeometry,
            titleVisible: titleVisible,
            onPostLinkTap: onPostLinkTap,
            onTitleDragChanged: onTitleDragChanged,
            onTitleDragEnded: onTitleDragEnded,
            onPostHeaderDragChanged: onPostHeaderDragChanged,
            onPostHeaderDragEnded: onPostHeaderDragEnded,
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
                    updateTitleVisibility: { titleVisible?.wrappedValue = $0 },
                    presentationState: presentationState,
                    postHeaderMatchedGeometryNamespace: postHeaderMatchedGeometryNamespace,
                    isPostHeaderMatchedGeometrySource: isPostHeaderMatchedGeometrySource,
                    titleVisibility: titleVisibility,
                    onPostHeaderDragChanged: onPostHeaderDragChanged,
                    onPostHeaderDragEnded: onPostHeaderDragEnded,
                    viewModel: viewModel,
                    votingViewModel: votingViewModel,
                    pendingCommentID: $pendingCommentID,
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
                .toolbarBackground(.automatic, for: .navigationBar)
        }
        .toolbar {
            if controlsNavigationBarVisibility && showsToolbar {
                ToolbarItem(placement: .principal) {
                    if let post = viewModel.post {
                        ToolbarTitle(
                            post: post,
                            showThumbnails: viewModel.showThumbnails,
                            titleVisibility: titleVisibility,
                            onTap: handleLinkTap,
                            onDragChanged: onTitleDragChanged,
                            onDragEnded: onTitleDragEnded,
                        )
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    if let post = viewModel.post {
                        ShareMenu(post: post, toolbarGeometry: toolbarGeometry)
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

    private func toggleCommentVisibility(withID commentID: Int) -> Comment? {
        viewModel.toggleCommentVisibility(withID: commentID)
    }

}

enum CommentsLinkNavigator {
    static func hackerNewsItemID(from url: URL) -> Int? {
        HackerNewsConstants.itemID(from: url)
    }
}
