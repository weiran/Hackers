//
//  CommentsComponents.swift
//  Comments
//
//  Extracted subviews and helpers from CommentsView to reduce file length
//

import DesignSystem
import Domain
import Foundation
import Observation
import Shared
import SwiftUI
import UIKit

private struct CommentsListFramePreferenceKey: PreferenceKey {
    static let defaultValue: CGRect? = nil

    static func reduce(value: inout CGRect?, nextValue: () -> CGRect?) {
        value = nextValue() ?? value
    }
}

private struct PendingCommentFramePreferenceKey: PreferenceKey {
    static let defaultValue: CGRect? = nil

    static func reduce(value: inout CGRect?, nextValue: () -> CGRect?) {
        value = nextValue() ?? value
    }
}

private struct SystemBackGestureEdgeShield: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = true
        return view
    }

    func updateUIView(_ view: UIView, context: Context) {}
}

struct CommentsContentView: View {
    @Environment(\.textScaling) private var textScaling
    let showsPostHeader: Bool
    let handleLinkTap: () -> Void
    let toggleCommentVisibility: (Comment) -> Void
    let hideCommentBranch: (Comment, @escaping (Int) -> Void) -> Void
    let updateIsAtTop: ((Bool) -> Void)?
    let updateTitleVisibility: ((Bool) -> Void)?
    let presentationState: CommentsPresentationState
    let postHeaderMatchedGeometryNamespace: Namespace.ID?
    let isPostHeaderMatchedGeometrySource: Bool
    @State var viewModel: CommentsViewModel
    @State var votingViewModel: VotingViewModel
    @Binding var showTitle: Bool
    @Binding var pendingCommentID: Int?
    @Binding var listAnimationsEnabled: Bool
    @State private var lastIsAtTop = true
    @State private var pendingAutoScrollCheckID: Int?
    @State private var pendingAutoScrollFrame: CGRect?
    @State private var listFrame: CGRect?
    @State private var autoScrollSequence = 0

    var body: some View {
        Group {
            if let post = viewModel.post {
                content(for: post)
            }
        }
    }

    private var commentScrollTopInset: CGFloat {
        presentationState.commentScrollTopInset
    }

    private var reservesSystemBackGestureEdge: Bool {
        if case .customBrowser = presentationState {
            true
        } else {
            false
        }
    }

    private var systemBackGestureEdgeWidth: CGFloat {
        let leadingInset = PresentationContextProvider.shared.keyWindow?.safeAreaInsets.left ?? 0
        return leadingInset + 56
    }

    private func content(for post: Post) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            ScrollViewReader { proxy in
                List {
                    postHeaderSection(for: post)
                    commentsSection(for: post, proxy: proxy)
                }
                .onScrollGeometryChange(for: CGFloat.self, of: { geometry in
                    geometry.contentOffset.y + geometry.contentInsets.top
                }, action: { _, newValue in
                    let shouldShowTitle = showTitle ? newValue > 24 : newValue > 56
                    if shouldShowTitle != showTitle {
                        showTitle = shouldShowTitle
                        updateTitleVisibility?(shouldShowTitle)
                    }
                    let isAtTop = lastIsAtTop ? newValue <= 8 : newValue <= 1
                    if isAtTop != lastIsAtTop {
                        lastIsAtTop = isAtTop
                        updateIsAtTop?(isAtTop)
                    }
                })
                .listStyle(.plain)
                .accessibilityIdentifier("comments.list")
                .safeAreaInset(edge: .top, spacing: 0) {
                    commentScrollTopSafeAreaInset
                }
                .background {
                    GeometryReader { geometry in
                        Color.clear.preference(
                            key: CommentsListFramePreferenceKey.self,
                            value: geometry.frame(in: .global)
                        )
                    }
                }
                .overlay(alignment: .leading) {
                    if reservesSystemBackGestureEdge {
                        SystemBackGestureEdgeShield()
                            .frame(width: systemBackGestureEdgeWidth)
                            .ignoresSafeArea(.container, edges: .leading)
                            .accessibilityHidden(true)
                    }
                }
                .transaction { transaction in
                    transaction.disablesAnimations = !listAnimationsEnabled
                }
                .onChange(of: pendingCommentID) { _, _ in
                    scrollToPendingComment(with: proxy)
                }
                .onChange(of: viewModel.visibleRevision) { _, _ in
                    scrollToPendingComment(with: proxy)
                }
                .onPreferenceChange(CommentsListFramePreferenceKey.self) { listFrame = $0 }
                .onPreferenceChange(PendingCommentFramePreferenceKey.self) { pendingAutoScrollFrame = $0 }
                .task(id: viewModel.visibleRevision) {
                    CommentTextCache.prewarm(
                        comments: viewModel.visibleComments.prefix(30),
                        textScaling: textScaling
                    )
                }
            }
        }
    }

    @ViewBuilder
    private var commentScrollTopSafeAreaInset: some View {
        if commentScrollTopInset > 0 {
            Color.clear
                .frame(height: commentScrollTopInset)
                .allowsHitTesting(false)
        }
    }

    @ViewBuilder
    private func postHeaderSection(for post: Post) -> some View {
        if showsPostHeader {
            PostHeader(
                post: post,
                votingViewModel: votingViewModel,
                isLoadingComments: viewModel.isLoading,
                showThumbnails: viewModel.showThumbnails,
                matchedGeometryNamespace: postHeaderMatchedGeometryNamespace,
                isMatchedGeometrySource: isPostHeaderMatchedGeometrySource,
                onLinkTap: { handleLinkTap() },
                onPostUpdated: { updatedPost in
                    viewModel.post = updatedPost
                },
                onBookmarkToggle: { await viewModel.toggleBookmark() }
            )
            .id("header")
            .listRowSeparator(.hidden)
            .if(shouldShowVoteActions(for: post)) { view in
                view.swipeActions(edge: .leading, allowsFullSwipe: true) {
                    postHeaderSwipeActions(for: post)
                }
            }
        }
    }

    private func shouldShowVoteActions(for post: Post) -> Bool {
        (post.voteLinks?.upvote != nil && !post.upvoted)
            || (post.voteLinks?.unvote != nil && post.upvoted)
    }

    @ViewBuilder
    private func postHeaderSwipeActions(for post: Post) -> some View {
        if post.upvoted && post.voteLinks?.unvote != nil {
            Button {
                guard !viewModel.isLoading else { return }
                Task {
                    var mutablePost = post
                    await votingViewModel.unvote(post: &mutablePost)
                    await MainActor.run {
                        viewModel.post = mutablePost
                    }
                }
            } label: {
                Image(systemName: "arrow.uturn.down")
            }
            .tint(.orange)
            .accessibilityLabel("Unvote")
            .disabled(viewModel.isLoading)
        } else {
            Button {
                guard !viewModel.isLoading else { return }
                Task {
                    var mutablePost = post
                    await votingViewModel.upvote(post: &mutablePost)
                    await MainActor.run {
                        if mutablePost.upvoted {
                            viewModel.post = mutablePost
                        }
                    }
                }
            } label: {
                Image(systemName: "arrow.up")
            }
            .tint(AppColors.upvotedColor)
            .accessibilityLabel("Upvote")
            .disabled(viewModel.isLoading)
        }
    }

    @ViewBuilder
    private func commentsSection(for post: Post, proxy: ScrollViewProxy) -> some View {
        if viewModel.isLoading {
            LoadingView()
                .plainListRow()
        } else if viewModel.comments.isEmpty {
            EmptyCommentsView()
                .plainListRow()
        } else {
            CommentsForEach(
                post: post,
                toggleCommentVisibility: { comment in
                    let shouldCheckAutoScroll = comment.visibility == .visible
                    if shouldCheckAutoScroll {
                        pendingAutoScrollCheckID = comment.id
                    }
                    toggleCommentVisibility(comment)
                    if shouldCheckAutoScroll {
                        scheduleAutoScrollCheck(for: comment.id, proxy: proxy)
                    }
                },
                hideCommentBranch: { comment in
                    hideCommentBranch(comment) { scrollToComment(withID: $0, proxy: proxy) }
                },
                viewModel: viewModel,
                votingViewModel: votingViewModel,
                pendingAutoScrollCheckID: pendingAutoScrollCheckID,
            )
        }
    }

    private func scrollToPendingComment(with proxy: ScrollViewProxy) {
        guard let targetID = pendingCommentID else { return }
        guard viewModel.visibleComments.contains(where: { $0.id == targetID }) else { return }

        Task { @MainActor in
            scrollToComment(withID: targetID, proxy: proxy, animation: .easeInOut)
            pendingCommentID = nil
        }
    }

    private func scrollToComment(
        withID commentID: Int,
        proxy: ScrollViewProxy,
        animation: Animation? = nil
    ) {
        let updates = {
            proxy.scrollTo(commentID, anchor: .top)
        }

        if let animation {
            withAnimation(animation) {
                updates()
            }
        } else {
            updates()
        }
    }

    private func scheduleAutoScrollCheck(for commentID: Int, proxy: ScrollViewProxy) {
        autoScrollSequence += 1
        let sequence = autoScrollSequence

        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 350_000_000)
            guard autoScrollSequence == sequence,
                  pendingAutoScrollCheckID == commentID
            else { return }

            if shouldScrollPendingCommentIntoView() {
                scrollToComment(withID: commentID, proxy: proxy, animation: .easeInOut(duration: 0.3))
            }

            pendingAutoScrollCheckID = nil
            pendingAutoScrollFrame = nil
        }
    }

    private func shouldScrollPendingCommentIntoView() -> Bool {
        guard let pendingAutoScrollFrame, let listFrame else { return true }
        let visibleFrame = CGRect(
            x: listFrame.minX,
            y: listFrame.minY + commentScrollTopInset,
            width: listFrame.width,
            height: max(listFrame.height - commentScrollTopInset, 0)
        )
        return !visibleFrame.contains(pendingAutoScrollFrame)
    }
}

struct CommentsForEach: View {
    @Environment(\.textScaling) private var textScaling
    let post: Post
    let toggleCommentVisibility: (Comment) -> Void
    let hideCommentBranch: (Comment) -> Void
    @State var viewModel: CommentsViewModel
    @State var votingViewModel: VotingViewModel
    let pendingAutoScrollCheckID: Int?

    var body: some View {
        ForEach(viewModel.visibleComments, id: \.id) { comment in
            CommentRow(
                state: rowState(for: comment),
                onToggle: { toggleCommentVisibility(comment) },
                onHide: { hideCommentBranch(comment) },
                onUpvote: { Task { await votingViewModel.upvote(comment: comment, in: post) } },
                onUnvote: { Task { await votingViewModel.unvote(comment: comment, in: post) } },
                onCopy: { UIPasteboard.general.string = comment.text.strippingHTML() },
                onShare: { ContentSharePresenter.shared.shareComment(comment) }
            )
            .id(comment.id)
            .background {
                if pendingAutoScrollCheckID == comment.id {
                    GeometryReader { geometry in
                        Color.clear.preference(
                            key: PendingCommentFramePreferenceKey.self,
                            value: geometry.frame(in: .global)
                        )
                    }
                }
            }
            .listRowSeparator(.visible)
            .accessibilityIdentifier("comments.comment.\(comment.id)")
            .if(shouldShowVoteActions(for: comment)) { view in
                view.swipeActions(edge: .leading, allowsFullSwipe: true) {
                    if comment.upvoted && comment.voteLinks?.unvote != nil {
                        Button {
                            Task {
                                await votingViewModel.unvote(comment: comment, in: post)
                            }
                        } label: {
                            Image(systemName: "arrow.uturn.down")
                        }
                        .tint(.orange)
                        .accessibilityLabel("Unvote")
                    } else {
                        Button {
                            Task {
                                await votingViewModel.upvote(comment: comment, in: post)
                            }
                        } label: {
                            Image(systemName: "arrow.up")
                        }
                        .tint(AppColors.upvotedColor)
                        .accessibilityLabel("Upvote")
                    }
                }
            }
            .swipeActions(edge: .trailing) {
                Button { hideCommentBranch(comment) } label: {
                    Image(systemName: "minus.circle")
                }
            }
        }
    }

    private func rowState(for comment: Comment) -> CommentRowState {
        CommentRowState(
            id: comment.id,
            author: comment.by,
            age: comment.age,
            visualLevel: min(comment.level, 6),
            visibility: comment.visibility,
            isPostAuthor: comment.by == post.by,
            isUpvoted: comment.upvoted,
            canVote: comment.voteLinks?.upvote != nil,
            canUnvote: comment.voteLinks?.unvote != nil,
            styledText: comment.visibility == .visible
                ? CommentTextCache.styledText(for: comment, textScaling: textScaling)
                : nil
        )
    }

    private func shouldShowVoteActions(for comment: Comment) -> Bool {
        (comment.voteLinks?.upvote != nil && !comment.upvoted)
            || (comment.voteLinks?.unvote != nil && comment.upvoted)
    }
}

struct PostHeader: View {
    let post: Post
    let votingViewModel: VotingViewModel
    let isLoadingComments: Bool
    let showThumbnails: Bool
    let matchedGeometryNamespace: Namespace.ID?
    let isMatchedGeometrySource: Bool
    let onLinkTap: () -> Void
    let onPostUpdated: @Sendable (Post) -> Void
    let onBookmarkToggle: @Sendable () async -> Bool

    var body: some View {
        Button(action: onLinkTap) {
            PostDisplayView(
                post: post,
                votingState: votingViewModel.votingState(for: post),
                showPostText: true,
                showThumbnails: showThumbnails,
                onThumbnailTap: { onLinkTap() },
                onUpvoteTap: { await handleUpvote() },
                onUnvoteTap: { await handleUnvote() },
                onBookmarkTap: { await onBookmarkToggle() },
                matchedGeometryNamespace: matchedGeometryNamespace,
                isMatchedGeometrySource: isMatchedGeometrySource
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .contextMenu {
            VotingContextMenuItems.postVotingMenuItems(
                for: post,
                onVote: { Task { await handleUpvote() } },
                onUnvote: { Task { await handleUnvote() } }
            )
            Divider()
            Button { onLinkTap() } label: {
                Label("Open Link", systemImage: "safari")
            }
            Button { ContentSharePresenter.shared.shareURL(post.url, title: post.title) } label: {
                Label("Share", systemImage: "square.and.arrow.up")
            }
        }
    }

    private func handleUpvote() async -> Bool {
        guard !isLoadingComments else { return false }
        guard votingViewModel.canVote(item: post), !post.upvoted else { return false }

        var mutablePost = post
        await votingViewModel.upvote(post: &mutablePost)
        let wasUpvoted = mutablePost.upvoted

        if wasUpvoted {
            await MainActor.run {
                onPostUpdated(mutablePost)
            }
        }

        return wasUpvoted
    }

    private func handleUnvote() async -> Bool {
        guard !isLoadingComments else { return true }
        guard votingViewModel.canUnvote(item: post), post.upvoted else { return true }

        var mutablePost = post
        await votingViewModel.unvote(post: &mutablePost)
        let wasUnvoted = !mutablePost.upvoted

        if wasUnvoted {
            await MainActor.run {
                onPostUpdated(mutablePost)
            }
        }

        return wasUnvoted
    }
}
