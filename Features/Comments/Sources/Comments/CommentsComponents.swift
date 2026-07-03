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

private struct CommentRowFramePreferenceKey: PreferenceKey {
    static let defaultValue: [Int: CGRect] = [:]

    static func reduce(value: inout [Int: CGRect], nextValue: () -> [Int: CGRect]) {
        value.merge(nextValue(), uniquingKeysWith: { _, new in new })
    }
}

private struct CommentScrollMetrics: Equatable {
    var contentOffset: CGPoint = .zero
    var contentInsets: EdgeInsets = EdgeInsets()
    var contentSize: CGSize = .zero
    var visibleRect: CGRect = .zero
}

private enum CollapseScrollDecision {
    case none
    case scrollToY(CGFloat)
    case deferUntilLayout
}

private enum CommentScrollIntent {
    case preserveCollapsedRoot(commentID: Int, afterRevision: Int)
    case revealComment(commentID: Int)
}

private enum CommentScrollCoordinateSpace {
    static let content = "comments.scroll.content"
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
                    value: [id: geometry.frame(in: .named(CommentScrollCoordinateSpace.content))]
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
    @State private var listAnimationGeneration = 0

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

    private var visibleContentTopInset: CGFloat {
        max(scrollMetrics.contentInsets.top, commentScrollTopInset)
    }

    private var visibleContentRect: CGRect {
        let rect = scrollMetrics.visibleRect
        guard rect.height > 0 else { return .zero }

        let minY = rect.minY + visibleContentTopInset
        let maxY = max(minY, rect.maxY - scrollMetrics.contentInsets.bottom)
        return CGRect(x: rect.minX, y: minY, width: rect.width, height: maxY - minY)
    }

    private var topVisibleCommentID: Int? {
        viewModel.visibleComments.first { comment in
            guard let frame = rowFrames[comment.id] else { return false }
            return frame.maxY > visibleContentRect.minY && frame.minY < visibleContentRect.maxY
        }?.id
    }

    private var hasNextCommentTarget: Bool {
        viewModel.nextVisibleCommentID(after: topVisibleCommentID) != nil
    }

    private func content(for post: Post) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    postHeaderSection(for: post)
                    commentsSection(for: post)
                }
                .scrollTargetLayout()
                .coordinateSpace(name: CommentScrollCoordinateSpace.content)
            }
            .scrollPosition($scrollPosition)
            .onScrollGeometryChange(for: CommentScrollMetrics.self, of: { geometry in
                CommentScrollMetrics(
                    contentOffset: geometry.contentOffset,
                    contentInsets: geometry.contentInsets,
                    contentSize: geometry.contentSize,
                    visibleRect: geometry.visibleRect
                )
            }, action: { _, newValue in
                scrollMetrics = newValue
                updateHeaderState(for: newValue)
                resolvePendingScrollIntent(animated: true)
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
            .safeAreaInset(edge: .bottom, alignment: .trailing, spacing: 0) {
                if !viewModel.visibleComments.isEmpty {
                    NextCommentFloatingButton(
                        isEnabled: hasNextCommentTarget,
                        onNextComment: scrollToNextComment,
                        onNextThread: scrollToNextThread
                    )
                    .padding(.trailing, 28)
                    .padding(.bottom, 28)
                }
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
                resolvePendingScrollIntent(animated: true)
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
        .preserveCollapsedRoot(commentID: comment.id, afterRevision: viewModel.visibleRevision + 1)
    }

    private func collapseScrollDecision(for comment: Comment) -> CollapseScrollDecision {
        guard let rootFrame = rowFrames[comment.id],
              visibleContentRect.height > 0,
              scrollMetrics.contentSize.height > 0
        else {
            return .deferUntilLayout
        }

        let currentVisibleRect = visibleContentRect
        if rootFrame.minY < currentVisibleRect.minY || rootFrame.minY >= currentVisibleRect.maxY {
            return .scrollToY(clampedScrollY(forRootTop: rootFrame.minY, maxOffsetY: maxContentOffsetY))
        }

        let removedHeight = estimatedCollapsedHeightDelta(for: comment, rootFrame: rootFrame)
        let predictedMaxOffsetY = maxContentOffsetY(afterRemoving: removedHeight)
        let predictedVisibleMinY = min(scrollMetrics.visibleRect.minY, predictedMaxOffsetY)
        let predictedVisibleTop = predictedVisibleMinY + visibleContentTopInset
        let predictedVisibleBottom = predictedVisibleMinY
            + scrollMetrics.visibleRect.height
            - scrollMetrics.contentInsets.bottom

        if rootFrame.minY >= predictedVisibleTop, rootFrame.minY < predictedVisibleBottom {
            return .none
        }

        return .scrollToY(clampedScrollY(forRootTop: rootFrame.minY, maxOffsetY: predictedMaxOffsetY))
    }

    private var maxContentOffsetY: CGFloat {
        maxContentOffsetY(afterRemoving: 0)
    }

    private func maxContentOffsetY(afterRemoving removedHeight: CGFloat) -> CGFloat {
        let contentHeight = max(scrollMetrics.contentSize.height - removedHeight, 0)
        return max(contentHeight - scrollMetrics.visibleRect.height, 0)
    }

    private func clampedScrollY(forRootTop rootTop: CGFloat, maxOffsetY: CGFloat) -> CGFloat {
        min(max(rootTop - visibleContentTopInset, 0), maxOffsetY)
    }

    private func estimatedCollapsedHeightDelta(for comment: Comment, rootFrame: CGRect) -> CGFloat {
        let descendants = visibleDescendants(of: comment)
        let measuredDescendantIDs = descendants.map(\.id).filter { rowFrames[$0] != nil }
        let measuredDescendantHeight = measuredDescendantIDs.reduce(CGFloat.zero) { total, id in
            total + max(rowFrames[id]?.height ?? 0, 0)
        }
        let missingDescendantCount = max(descendants.count - measuredDescendantIDs.count, 0)
        let missingDescendantHeight = CGFloat(missingDescendantCount) * averageVisibleCommentRowHeight
        let separatorHeight = CGFloat(descendants.count)
        let rootHeightDelta = max(rootFrame.height - estimatedCompactCommentRowHeight, 0)

        return rootHeightDelta + measuredDescendantHeight + missingDescendantHeight + separatorHeight
    }

    private func visibleDescendants(of comment: Comment) -> [Comment] {
        guard let rootIndex = viewModel.visibleComments.firstIndex(where: { $0.id == comment.id }) else {
            return []
        }

        return viewModel.visibleComments[viewModel.visibleComments.index(after: rootIndex)...]
            .prefix { $0.level > comment.level }
            .map { $0 }
    }

    private var averageVisibleCommentRowHeight: CGFloat {
        let visibleCommentFrames = viewModel.visibleComments.compactMap { rowFrames[$0.id]?.height }
        guard !visibleCommentFrames.isEmpty else { return estimatedCompactCommentRowHeight }
        return visibleCommentFrames.reduce(0, +) / CGFloat(visibleCommentFrames.count)
    }

    private var estimatedCompactCommentRowHeight: CGFloat {
        max(44, ceil(UIFont.preferredFont(forTextStyle: .subheadline).lineHeight * textScaling + 32))
    }

    private func resolvePendingScrollIntent(animated: Bool) {
        guard let intent = pendingScrollIntent else { return }

        switch intent {
        case .preserveCollapsedRoot(let commentID, let afterRevision):
            guard viewModel.visibleRevision >= afterRevision else { return }
            guard viewModel.visibleComments.contains(where: { $0.id == commentID }) else {
                pendingScrollIntent = nil
                return
            }

            if let frame = rowFrames[commentID], isCollapsedRootVisible(frame) {
                pendingScrollIntent = nil
            } else {
                performScrollUpdate(animated: animated) {
                    scrollCollapsedRootToTop(commentID: commentID)
                    pendingScrollIntent = nil
                }
            }
        case .revealComment(let commentID):
            if viewModel.visibleComments.contains(where: { $0.id == commentID }) {
                performScrollUpdate(animated: animated) {
                    scrollPosition.scrollTo(id: commentID, anchor: .commentTop)
                    pendingScrollIntent = nil
                    pendingCommentID = nil
                }
            }
        }
    }

    private func isCollapsedRootVisible(_ frame: CGRect) -> Bool {
        let visibleRect = visibleContentRect
        guard visibleRect.height > 0 else { return true }
        return frame.minY >= visibleRect.minY && frame.minY < visibleRect.maxY
    }

    private func scrollCollapsedRootToTop(commentID: Int) {
        guard let frame = rowFrames[commentID] else {
            scrollPosition.scrollTo(id: commentID, anchor: .commentTop)
            return
        }

        scrollPosition.scrollTo(y: frame.minY - visibleContentTopInset)
    }

    private func scrollToPendingComment() {
        guard let targetID = pendingCommentID else { return }
        guard viewModel.visibleComments.contains(where: { $0.id == targetID }) else { return }

        scrollToComment(withID: targetID)
    }

    private func scrollToNextComment() {
        guard let targetID = viewModel.nextVisibleCommentID(after: topVisibleCommentID) else { return }
        scrollToComment(withID: targetID)
    }

    private func scrollToNextThread() {
        guard let targetID = viewModel.nextVisibleThreadID(after: topVisibleCommentID) else { return }
        scrollToComment(withID: targetID)
    }

    private func scrollToComment(withID targetID: Int) {
        pendingScrollIntent = .revealComment(commentID: targetID)
        resolvePendingScrollIntent(animated: true)
    }

    private func performScrollUpdate(animated: Bool, _ updates: () -> Void) {
        guard animated else {
            updates()
            return
        }

        performListAnimation {
            updates()
        }
    }

    private func performListAnimation(_ updates: () -> Void) {
        listAnimationGeneration += 1
        let generation = listAnimationGeneration
        listAnimationsEnabled = true

        withAnimation(.easeInOut(duration: 0.3), completionCriteria: .logicallyComplete) {
            updates()
        } completion: {
            if listAnimationGeneration == generation {
                listAnimationsEnabled = false
            }
        }
    }

    private func toggleCommentVisibilityWithScrollPreservation(_ comment: Comment) {
        let shouldPreserveRoot = comment.visibility == .visible
        let collapseScrollDecision = shouldPreserveRoot ? collapseScrollDecision(for: comment) : .none
        if case .deferUntilLayout = collapseScrollDecision {
            pendingScrollIntent = scrollPreservationIntent(for: comment)
        } else {
            pendingScrollIntent = nil
        }

        performListAnimation {
            toggleCommentVisibility(comment)
            if case .scrollToY(let targetY) = collapseScrollDecision {
                scrollPosition.scrollTo(y: targetY)
            }
        }
    }

    private func commentRow(for comment: Comment, in post: Post) -> some View {
        CommentRow(
            state: rowState(for: comment),
            onToggle: { toggleCommentVisibilityWithScrollPreservation(comment) },
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

private struct NextCommentFloatingButton: View {
    let isEnabled: Bool
    let onNextComment: () -> Void
    let onNextThread: () -> Void

    var body: some View {
        Image(systemName: "arrow.down")
            .font(.system(size: 20, weight: .semibold))
            .foregroundStyle(isEnabled ? Color.primary : Color.secondary)
            .frame(width: 48, height: 48)
            .glassEffect(.regular.interactive(isEnabled), in: .circle)
            .opacity(isEnabled ? 1 : 0.55)
            .contentShape(Circle())
            .gesture(
                LongPressGesture(minimumDuration: 0.45)
                    .exclusively(before: TapGesture())
                    .onEnded { value in
                        guard isEnabled else { return }
                        switch value {
                        case .first:
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            onNextThread()
                        case .second:
                            onNextComment()
                        }
                    }
            )
            .accessibilityLabel("Next comment")
            .accessibilityHint("Long press for next thread")
            .accessibilityAddTraits(.isButton)
            .accessibilityAction(.default) {
                guard isEnabled else { return }
                onNextComment()
            }
            .accessibilityAction(named: Text("Next thread")) {
                guard isEnabled else { return }
                onNextThread()
            }
            .accessibilityIdentifier("comments.nextCommentButton")
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
