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

private struct CommentRowFramePreferenceKey: PreferenceKey {
    static let defaultValue: [Int: CGRect] = [:]

    static func reduce(value: inout [Int: CGRect], nextValue: () -> [Int: CGRect]) {
        value.merge(nextValue(), uniquingKeysWith: { _, new in new })
    }
}

private struct CommentScrollMetrics: Equatable {
    var contentOffset: CGPoint = .zero
    var contentInsets: EdgeInsets = EdgeInsets()
    var visibleRect: CGRect = .zero
}

private enum CommentScrollIntent {
    case preserveCollapsedRoot(commentID: Int)
    case revealComment(commentID: Int)
}

private extension UnitPoint {
    static let commentTop = UnitPoint(x: 0.5, y: 0)
}

private extension View {
    func commentRowFrame(id: Int) -> some View {
        background {
            GeometryReader { geometry in
                Color.clear.preference(
                    key: CommentRowFramePreferenceKey.self,
                    value: [id: geometry.frame(in: .scrollView)]
                )
            }
        }
    }
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
    let titleVisibility: CommentsHeaderTitleVisibility
    @State var viewModel: CommentsViewModel
    @State var votingViewModel: VotingViewModel
    @Binding var pendingCommentID: Int?
    @Binding var listAnimationsEnabled: Bool
    @State private var lastIsAtTop = true
    @State private var scrollPosition = ScrollPosition(idType: Int.self)
    @State private var rowFrames: [Int: CGRect] = [:]
    @State private var scrollMetrics = CommentScrollMetrics()
    @State private var pendingScrollIntent: CommentScrollIntent?

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

    private func content(for post: Post) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    postHeaderSection(for: post)
                    commentsSection(for: post)
                }
                .scrollTargetLayout()
            }
            .scrollPosition($scrollPosition)
            .onScrollGeometryChange(for: CommentScrollMetrics.self, of: { geometry in
                CommentScrollMetrics(
                    contentOffset: geometry.contentOffset,
                    contentInsets: geometry.contentInsets,
                    visibleRect: geometry.visibleRect
                )
            }, action: { _, newValue in
                scrollMetrics = newValue
                updateHeaderState(for: newValue)
            })
            .onScrollPhaseChange { _, newPhase in
                if newPhase == .tracking || newPhase == .interacting {
                    pendingScrollIntent = nil
                }
            }
            .accessibilityIdentifier("comments.list")
            .safeAreaInset(edge: .top, spacing: 0) {
                commentScrollTopSafeAreaInset
            }
            .transaction { transaction in
                transaction.disablesAnimations = !listAnimationsEnabled
            }
            .onChange(of: pendingCommentID) { _, _ in
                scrollToPendingComment()
            }
            .onChange(of: viewModel.visibleRevision) { _, _ in
                scrollToPendingComment()
            }
            .onPreferenceChange(CommentRowFramePreferenceKey.self) { newFrames in
                rowFrames = newFrames
                resolvePendingScrollIntent()
            }
            .task(id: viewModel.visibleRevision) {
                CommentTextCache.prewarm(
                    comments: viewModel.visibleComments.prefix(30),
                    textScaling: textScaling
                )
            }
        }
    }

    private func updateHeaderState(for metrics: CommentScrollMetrics) {
        let offsetY = metrics.contentOffset.y + metrics.contentInsets.top
        let shouldShowTitle = titleVisibility.isVisible ? offsetY > 24 : offsetY > 56
        if shouldShowTitle != titleVisibility.isVisible {
            withAnimation(.easeInOut(duration: 0.3)) {
                titleVisibility.setVisible(shouldShowTitle)
                updateTitleVisibility?(shouldShowTitle)
            }
        }

        let isAtTop = lastIsAtTop ? offsetY <= 8 : offsetY <= 1
        if isAtTop != lastIsAtTop {
            lastIsAtTop = isAtTop
            updateIsAtTop?(isAtTop)
        }
    }

    private func scrollPreservationIntent(for comment: Comment) -> CommentScrollIntent {
        .preserveCollapsedRoot(commentID: comment.id)
    }

    private func resolvePendingScrollIntent() {
        guard let intent = pendingScrollIntent else { return }

        switch intent {
        case .preserveCollapsedRoot(let commentID):
            guard viewModel.visibleComments.contains(where: { $0.id == commentID }) else {
                pendingScrollIntent = nil
                return
            }

            if let frame = rowFrames[commentID], isCollapsedRootVisible(frame) {
                pendingScrollIntent = nil
            } else {
                scrollPosition.scrollTo(id: commentID, anchor: .commentTop)
                pendingScrollIntent = nil
            }
        case .revealComment(let commentID):
            if viewModel.visibleComments.contains(where: { $0.id == commentID }) {
                scrollPosition.scrollTo(id: commentID, anchor: .commentTop)
                pendingScrollIntent = nil
                pendingCommentID = nil
            }
        }
    }

    private func isCollapsedRootVisible(_ frame: CGRect) -> Bool {
        let topBoundary = commentScrollTopInset
        let bottomBoundary = max(scrollMetrics.visibleRect.height, topBoundary)
        return frame.minY >= topBoundary && frame.minY < bottomBoundary
    }

    private func scrollToPendingComment() {
        guard let targetID = pendingCommentID else { return }
        guard viewModel.visibleComments.contains(where: { $0.id == targetID }) else { return }

        pendingScrollIntent = .revealComment(commentID: targetID)
        withAnimation(.easeInOut(duration: 0.3)) {
            resolvePendingScrollIntent()
        }
    }

    private func toggleCommentVisibilityWithScrollPreservation(_ comment: Comment) {
        let shouldPreserveRoot = comment.visibility == .visible
        if shouldPreserveRoot {
            pendingScrollIntent = scrollPreservationIntent(for: comment)
        }

        withAnimation(.easeInOut(duration: 0.3)) {
            toggleCommentVisibility(comment)
        }
    }

    private func hideCommentBranchWithScrollPreservation(_ comment: Comment) {
        if let rootComment = visibleRootComment(of: comment) {
            pendingScrollIntent = scrollPreservationIntent(for: rootComment)
        }

        hideCommentBranch(comment) { rootID in
            if pendingScrollIntent == nil {
                pendingScrollIntent = .revealComment(commentID: rootID)
            }
        }
    }

    private func visibleRootComment(of comment: Comment) -> Comment? {
        guard let index = viewModel.comments.firstIndex(where: { $0.id == comment.id }) else {
            return nil
        }

        for candidate in viewModel.comments[...index].reversed()
            where candidate.level == 0 && candidate.visibility != .hidden {
            return candidate
        }

        return nil
    }

    private func commentRow(for comment: Comment, in post: Post) -> some View {
        CommentRow(
            state: rowState(for: comment),
            onToggle: { toggleCommentVisibilityWithScrollPreservation(comment) },
            onHide: { hideCommentBranchWithScrollPreservation(comment) },
            onUpvote: { Task { await votingViewModel.upvote(comment: comment, in: post) } },
            onUnvote: { Task { await votingViewModel.unvote(comment: comment, in: post) } },
            onCopy: { UIPasteboard.general.string = comment.text.strippingHTML() },
            onShare: { ContentSharePresenter.shared.shareComment(comment) }
        )
        .id(comment.id)
        .commentRowFrame(id: comment.id)
        .padding(.leading, CGFloat(16 + min(comment.level, 6) * 14))
        .padding(.trailing, 16)
        .padding(.vertical, 16)
        .accessibilityIdentifier("comments.comment.\(comment.id)")
    }

    private func rowState(for comment: Comment) -> CommentRowState {
        CommentRowState(
            id: comment.id,
            author: comment.by,
            age: comment.age,
            visibility: comment.visibility,
            isPostAuthor: comment.by == viewModel.post?.by,
            isUpvoted: comment.upvoted,
            canVote: comment.voteLinks?.upvote != nil,
            canUnvote: comment.voteLinks?.unvote != nil,
            styledText: comment.visibility == .visible
                ? CommentTextCache.styledText(for: comment, textScaling: textScaling)
                : nil
        )
    }

    @ViewBuilder
    private func commentSeparator(for comment: Comment) -> some View {
        if comment.id != viewModel.visibleComments.last?.id {
            Divider()
                .padding(.leading, CGFloat(16 + min(comment.level, 6) * 14))
        }
    }

    @ViewBuilder
    private func commentsRows(for post: Post) -> some View {
        ForEach(viewModel.visibleComments, id: \.id) { comment in
            commentRow(for: comment, in: post)
            commentSeparator(for: comment)
        }
    }

    @ViewBuilder
    private func commentsSection(for post: Post) -> some View {
        if viewModel.isLoading {
            LoadingView()
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
        } else if viewModel.comments.isEmpty {
            EmptyCommentsView()
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
        } else {
            commentsRows(for: post)
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
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            Divider()
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
            Button { ContentSharePresenter.shared.shareHackerNewsPost(post) } label: {
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
