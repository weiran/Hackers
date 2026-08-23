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

    var headerBlurTopInset: CGFloat {
        switch self {
        case .standard:
            0
        case .customBrowser:
            0
        }
    }

    var headerBlurFadeExtension: CGFloat {
        switch self {
        case .standard:
            0
        case .customBrowser:
            32
        }
    }

    var usesCustomHeaderBlur: Bool {
        switch self {
        case .standard:
            false
        case .customBrowser:
            true
        }
    }
}

public struct CommentsView<Store: NavigationStoreProtocol>: View {
    @Environment(Store.self) private var navigationStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @Environment(\.appRuntimePolicy) private var appRuntimePolicy
    @Environment(SessionService.self) private var sessionService
    private let showsPostHeader: Bool
    private let allowsRefresh: Bool
    private let showsToolbar: Bool
    private let controlsNavigationBarVisibility: Bool
    private let presentationState: CommentsPresentationState
    private let postHeaderMatchedGeometryNamespace: Namespace.ID?
    private let isPostHeaderMatchedGeometrySource: Bool
    private let titleVisible: Binding<Bool>?
    private let toolbarGeometry: CommentsToolbarGeometry?
    private let isInteractionEnabled: Bool
    private let onPostLinkTap: (() -> Void)?
    private let onTitleDragChanged: ((DragGesture.Value) -> Void)?
    private let onTitleDragEnded: ((DragGesture.Value) -> Void)?
    private let onPostHeaderDragChanged: ((DragGesture.Value) -> Void)?
    private let onPostHeaderDragEnded: ((DragGesture.Value) -> Void)?
    @State private var viewModel: CommentsViewModel
    @State private var votingViewModel: VotingViewModel
    @State private var titleVisibility: CommentsHeaderTitleVisibility
    @State private var pendingCommentID: Int?
    @State private var replyScrollTarget: Int?
    @State private var composer = CommentComposerModel()
}

public extension CommentsView {
    init(
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
        isInteractionEnabled: Bool = true,
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
        self.isInteractionEnabled = isInteractionEnabled
        self.onPostLinkTap = onPostLinkTap
        self.onTitleDragChanged = onTitleDragChanged
        self.onTitleDragEnded = onTitleDragEnded
        self.onPostHeaderDragChanged = onPostHeaderDragChanged
        self.onPostHeaderDragEnded = onPostHeaderDragEnded
        _titleVisibility = State(initialValue: headerTitleVisibility ?? CommentsHeaderTitleVisibility())
        let initialTargetID = targetCommentID ?? (initialPost == nil && viewModel == nil ? postID : nil)
        _pendingCommentID = State(initialValue: initialTargetID)
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

    init(
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
        isInteractionEnabled: Bool = true,
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
            isInteractionEnabled: isInteractionEnabled,
            onPostLinkTap: onPostLinkTap,
            onTitleDragChanged: onTitleDragChanged,
            onTitleDragEnded: onTitleDragEnded,
            onPostHeaderDragChanged: onPostHeaderDragChanged,
            onPostHeaderDragEnded: onPostHeaderDragEnded,
            viewModel: viewModel,
            votingViewModel: votingViewModel
        )
    }
}

private extension CommentsView {
    private var canComment: Bool {
        appRuntimePolicy.allowsCommenting
            && sessionService.authenticationState == .authenticated
    }
}

public extension CommentsView {
    var body: some View {
        Group {
            if viewModel.post != nil {
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
                    canComment: canComment,
                    composer: composer,
                    replyScrollTarget: $replyScrollTarget,
                    onReply: handleReplyActivation(commentID:author:),
                    onSubmitComposerDraft: {
                        Task { await submitComposerDraft() }
                    }
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
                .toolbarBackground(
                    presentationState.usesCustomHeaderBlur ? .hidden : .automatic,
                    for: .navigationBar
                )
                .overlay(alignment: .top) {
                    if showsToolbar, presentationState.usesCustomHeaderBlur {
                        commentsHeaderBlur
                    }
                }
        }
        .toolbar {
            if controlsNavigationBarVisibility && showsToolbar {
                if !presentationState.usesCustomHeaderBlur {
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
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    if let post = viewModel.post {
                        ShareMenu(post: post, toolbarGeometry: toolbarGeometry)
                    }
                }
            }
        }
        .task { [navigationStore] in
            votingViewModel.navigationStore = navigationStore
            // Set up callback to update navigation store when post changes
            viewModel.onPostUpdated = { [weak navigationStore] updatedPost in
                if let updatedPost {
                    navigationStore?.selectedPost = updatedPost
                }
            }
            await viewModel.loadComments()
            if let targetID = pendingCommentID {
                _ = viewModel.revealComment(withId: targetID)
            }
        }
        .if(allowsRefresh) { view in
            view.refreshable {
                await viewModel.refreshComments()
                if let targetID = pendingCommentID {
                    _ = viewModel.revealComment(withId: targetID)
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
        .alert(
            composerAlertTitle,
            isPresented: Binding(
                get: { composer.alert != nil },
                set: { if !$0 { composer.alert = nil } }
            ),
            presenting: composer.alert
        ) { alert in
            composerAlertActions(for: alert)
        } message: { alert in
            Text(composerAlertMessage(for: alert))
        }
        .onChange(of: canComment) { _, available in
            guard !available else { return }
            composer.collapsePreservingDraft()
        }
        .onChange(of: isInteractionEnabled) { _, enabled in
            guard !enabled else { return }
            composer.collapsePreservingDraft()
        }
    }
}

private extension CommentsView {
    private var commentsHeaderBlur: some View {
        GeometryReader { proxy in
            ProgressiveHeaderBlurBackground(
                height: proxy.safeAreaInsets.top + 44 + presentationState.headerBlurTopInset,
                fadeExtension: presentationState.headerBlurFadeExtension
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
        if DeviceLayout.prefersInlineCustomBrowser(mode: mode) {
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

// MARK: - Comment submission

extension CommentsView {
    // MARK: - Comment submission

    private func submitComposerDraft() async {
        // Central gate: never issue comment-form network traffic while the
        // feature or session is unavailable.
        guard composer.isPosting else { return }
        guard canComment else {
            composer.postingFailed(message: "Comments are currently unavailable.")
            return
        }
        guard let author = sessionService.username else {
            await handleSessionExpiry()
            return
        }

        let parentID: Int
        switch composer.target {
        case .story:
            parentID = viewModel.postID
        case let .reply(commentID, _):
            parentID = commentID
        }

        do {
            let outcome = try await viewModel.submitComment(
                parentID: parentID,
                text: composer.text,
                author: author
            )
            handleSubmissionOutcome(outcome)
        } catch let error as CommentSubmissionError {
            await handleSubmissionError(error)
        } catch {
            composer.postingFailed(
                message: "Couldn’t post this comment. Your draft has been kept."
            )
        }
    }

    private func handleSubmissionOutcome(_ outcome: CommentSubmissionOutcome) {
        switch outcome {
        case let .confirmed(submitted):
            if let inserted = viewModel.insertSubmittedComment(submitted) {
                pendingCommentID = inserted.id
            }
            composer.postingSucceeded()
        case let .unconfirmed(attempt):
            composer.postingBecameUnconfirmed(attempt: attempt)
        }
    }

    private func handleSubmissionError(_ error: CommentSubmissionError) async {
        switch error {
        case .unauthenticated:
            await handleSessionExpiry()
        case .commentingUnavailable:
            composer.postingFailed(message: "Hacker News is not accepting replies to this item.")
        case let .rejected(message):
            composer.postingFailed(message: message ?? "Couldn’t post this comment. Your draft has been kept.")
        case .empty, .invalidTarget, .malformedResponse:
            composer.postingFailed(message: "Couldn’t post this comment. Your draft has been kept.")
        }
    }

    private func reconcileUnconfirmedComment() async {
        guard case let .outcomeUnknown(attempt) = composer.submissionState else { return }
        do {
            if let submitted = try await viewModel.reconcileSubmittedComment(attempt: attempt) {
                if let inserted = viewModel.insertSubmittedComment(submitted) {
                    pendingCommentID = inserted.id
                }
                composer.outcomeUnknownResolved()
            } else {
                composer.outcomeUnknownStillUnresolved()
            }
        } catch {
            composer.outcomeUnknownStillUnresolved()
        }
    }

    private func handleSessionExpiry() async {
        // Draft and target stay in the composer; the gate hides all commenting
        // UI while logged out. If the same comments view survives a re-login,
        // the preserved collapsed draft reappears.
        composer.sessionDidExpire()
        let container = DependencyContainer.shared
        try? await container.getAuthenticationUseCase().logout()
        NotificationCenter.default.post(name: .userDidLogout, object: nil)
        navigationStore.showLogin()
    }

    // MARK: - Reply activation

    private func handleReplyActivation(commentID: Int, author: String) {
        guard canComment, !composer.isPosting else { return }
        let wasDirtySwitch = composer.hasDraft
            && composer.target != .reply(commentID: commentID, author: author)
        composer.activateReply(commentID: commentID, author: author)
        guard !wasDirtySwitch else { return }
        presentReplyTarget(commentID: commentID)
    }

    private func confirmDiscardAndReply() {
        guard case let .discardDraft(newTarget) = composer.alert else { return }
        composer.confirmTargetReplacement()
        if case let .reply(commentID, _) = newTarget {
            presentReplyTarget(commentID: commentID)
        }
    }

    private func presentReplyTarget(commentID: Int) {
        _ = viewModel.revealComment(withId: commentID)
        replyScrollTarget = commentID
        composer.expand()
    }

    // MARK: - Composer alerts

    private var composerAlertTitle: String {
        switch composer.alert {
        case .discardDraft: "Discard current draft?"
        case .outcomeUnknown: "Couldn’t confirm this comment"
        case nil: ""
        }
    }

    @ViewBuilder
    private func composerAlertActions(for alert: CommentComposerAlert) -> some View {
        switch alert {
        case let .discardDraft(newTarget):
            Button("Keep Editing") { composer.keepCurrentDraft() }
            switch newTarget {
            case .reply:
                Button("Discard & Reply", role: .destructive) { confirmDiscardAndReply() }
            case .story:
                Button("Discard & Comment", role: .destructive) { confirmDiscardAndReply() }
            }
        case .outcomeUnknown:
            Button("Check Again") {
                Task { await reconcileUnconfirmedComment() }
            }
            Button("Keep Draft") { composer.alert = nil }
        }
    }

    private func composerAlertMessage(for alert: CommentComposerAlert) -> String {
        switch alert {
        case let .discardDraft(newTarget):
            switch newTarget {
            case let .reply(_, author):
                "Starting a reply to \(author) will discard what you have written."
            case .story:
                "Starting a new comment will discard what you have written."
            }
        case .outcomeUnknown:
            "Hackers could not confirm whether Hacker News accepted this comment. "
                + "Check the thread before posting it again."
        }
    }
}
