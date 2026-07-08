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

private final class CommentScrollMetricsStore {
    var latest = CommentScrollMetrics()
}

@Observable
private final class VisibleCommentTarget {
    var topCommentID: Int?
    var hasNextComment = false

    func update(topCommentID: Int?, hasNextComment: Bool) {
        guard self.topCommentID != topCommentID || self.hasNextComment != hasNextComment else { return }
        self.topCommentID = topCommentID
        self.hasNextComment = hasNextComment
    }
}

private enum CommentScrollIntent {
    case revealComment(commentID: Int)
}

private struct CollapsingCommentBranch {
    let transitionID: UUID
    let rootID: Int
    let compactRoot: CommentRowState
    let rowIDs: Set<Int>
    let expandedHeight: CGFloat
    let showsSeparatorAfter: Bool
}

private struct CollapsingBranchCompactHeightPreferenceKey: PreferenceKey {
    static let defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

enum CollapseScrollVisibility {
    static func isMeasuredRootTopVisible(frame: CGRect?, visibleRect: CGRect) -> Bool? {
        guard let frame else { return nil }
        return isRootTopVisible(frame: frame, visibleRect: visibleRect)
    }

    static func isRootTopVisible(frame: CGRect, visibleRect: CGRect) -> Bool {
        guard visibleRect.height > 0 else { return true }
        return frame.minY >= visibleRect.minY && frame.minY < visibleRect.maxY
    }
}

private enum CommentScrollCoordinateSpace {
    static let content = "comments.scroll.content"
}

private extension UnitPoint {
    static let commentTop = UnitPoint(x: 0.5, y: 0)
}

private extension View {
    @ViewBuilder
    func commentRowFrame(id: Int, isEnabled: Bool) -> some View {
        if isEnabled {
            background {
                GeometryReader { geometry in
                    Color.clear.preference(
                        key: CommentRowFramePreferenceKey.self,
                        value: [id: geometry.frame(in: .named(CommentScrollCoordinateSpace.content))]
                    )
                }
            }
        } else {
            self
        }
    }

    func collapsingBranchCompactHeight() -> some View {
        background {
            GeometryReader { geometry in
                Color.clear.preference(
                    key: CollapsingBranchCompactHeightPreferenceKey.self,
                    value: geometry.size.height
                )
            }
        }
    }
}

struct CommentsContentView: View {
    private static let scrollMetricsUpdateDistance: CGFloat = 48
    private static let commentCollapseAnimation = Animation.easeInOut(duration: 0.3)

    @Environment(\.textScaling) private var textScaling
    let showsPostHeader: Bool
    let handleLinkTap: () -> Void
    let toggleCommentVisibility: (Int) -> Comment?
    let updateIsAtTop: ((Bool) -> Void)?
    let updateTitleVisibility: ((Bool) -> Void)?
    let presentationState: CommentsPresentationState
    let postHeaderMatchedGeometryNamespace: Namespace.ID?
    let isPostHeaderMatchedGeometrySource: Bool
    let titleVisibility: CommentsHeaderTitleVisibility
    let onPostHeaderDragChanged: ((DragGesture.Value) -> Void)?
    let onPostHeaderDragEnded: ((DragGesture.Value) -> Void)?
    @State var viewModel: CommentsViewModel
    @State var votingViewModel: VotingViewModel
    @Binding var pendingCommentID: Int?
    @State private var lastIsAtTop = true
    @State private var scrollPosition = ScrollPosition(idType: Int.self)
    @State private var rowFrames: [Int: CGRect] = [:]
    @State private var scrollMetrics = CommentScrollMetrics()
    @State private var latestScrollMetrics = CommentScrollMetricsStore()
    @State private var visibleCommentTarget = VisibleCommentTarget()
    @State private var pendingScrollIntent: CommentScrollIntent?
    @State private var collapsingBranch: CollapsingCommentBranch?

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

    private var tracksRowFrames: Bool {
        true
    }

    private var tracksScrollMetrics: Bool {
        !presentationState.usesCustomHeaderBlur || pendingScrollIntent != nil
    }

    private var visibleContentRect: CGRect {
        visibleContentRect(for: scrollMetrics)
    }

    private var visibleContentTopInset: CGFloat {
        visibleContentTopInset(for: scrollMetrics)
    }

    private func visibleContentTopInset(for metrics: CommentScrollMetrics) -> CGFloat {
        max(metrics.contentInsets.top, commentScrollTopInset)
    }

    private func visibleContentRect(for metrics: CommentScrollMetrics) -> CGRect {
        let rect = metrics.visibleRect
        guard rect.height > 0 else { return .zero }

        let topInset = visibleContentTopInset(for: metrics)
        let minY = rect.minY + topInset
        let maxY = max(minY, rect.maxY - metrics.contentInsets.bottom)
        return CGRect(x: rect.minX, y: minY, width: rect.width, height: maxY - minY)
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
            .onScrollTargetVisibilityChange(idType: Int.self, threshold: 0.1) { visibleIDs in
                updateVisibleCommentTarget(visibleIDs: visibleIDs)
            }
            .onScrollGeometryChange(for: CommentScrollMetrics.self, of: { geometry in
                CommentScrollMetrics(
                    contentOffset: geometry.contentOffset,
                    contentInsets: geometry.contentInsets,
                    contentSize: geometry.contentSize,
                    visibleRect: geometry.visibleRect
                )
            }, action: { _, newValue in
                latestScrollMetrics.latest = newValue
                updateHeaderState(for: newValue)
                updateStoredScrollMetricsIfNeeded(newValue)
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
                        visibleCommentTarget: visibleCommentTarget,
                        onNextComment: scrollToNextComment,
                        onNextThread: scrollToNextThread
                    )
                    .padding(.trailing, 28)
                    .padding(.bottom, 28)
                }
            }
            .onChange(of: pendingCommentID) { _, _ in
                scrollToPendingComment()
            }
            .onChange(of: viewModel.visibleRevision) { _, _ in
                scrollToPendingComment()
            }
            .onPreferenceChange(CommentRowFramePreferenceKey.self) { newFrames in
                guard tracksRowFrames else { return }
                guard rowFrames != newFrames else { return }
                rowFrames = newFrames
                if pendingScrollIntent != nil {
                    resolvePendingScrollIntent(animated: true)
                }
            }
            .task(id: viewModel.visibleRevision) {
                await CommentTextCache.prewarm(
                    comments: viewModel.visibleComments.prefix(30),
                    textScaling: textScaling,
                    chunkSize: 5
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

    private func updateStoredScrollMetricsIfNeeded(_ newValue: CommentScrollMetrics) {
        let shouldUpdateMetrics: Bool
        if tracksScrollMetrics {
            shouldUpdateMetrics = shouldStoreScrollMetrics(newValue) || pendingScrollIntent != nil
        } else {
            shouldUpdateMetrics = shouldStoreStaticScrollMetrics(newValue)
        }
        guard shouldUpdateMetrics else { return }

        scrollMetrics = newValue
        if pendingScrollIntent != nil {
            resolvePendingScrollIntent(animated: true)
        }
    }

    private func shouldStoreScrollMetrics(_ newValue: CommentScrollMetrics) -> Bool {
        guard scrollMetrics.visibleRect != .zero else { return true }
        guard scrollMetrics.contentInsets == newValue.contentInsets,
              scrollMetrics.contentSize == newValue.contentSize,
              scrollMetrics.visibleRect.size == newValue.visibleRect.size
        else {
            return true
        }

        let previousOffset = scrollMetrics.contentOffset.y + scrollMetrics.contentInsets.top
        let newOffset = newValue.contentOffset.y + newValue.contentInsets.top
        return abs(newOffset - previousOffset) >= Self.scrollMetricsUpdateDistance
    }

    private func shouldStoreStaticScrollMetrics(_ newValue: CommentScrollMetrics) -> Bool {
        guard scrollMetrics.visibleRect != .zero else { return true }

        return scrollMetrics.contentInsets != newValue.contentInsets
            || scrollMetrics.contentSize != newValue.contentSize
            || scrollMetrics.visibleRect.size != newValue.visibleRect.size
    }

    private func updateVisibleCommentTarget(visibleIDs: [Int]) {
        let topID = visibleIDs.first
        visibleCommentTarget.update(
            topCommentID: topID,
            hasNextComment: viewModel.hasNextVisibleComment(after: topID)
        )
    }

    private func resolvePendingScrollIntent(animated: Bool) {
        guard let intent = pendingScrollIntent else { return }

        switch intent {
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

    private func maxContentOffsetY(afterRemoving removedHeight: CGFloat, metrics: CommentScrollMetrics) -> CGFloat {
        let contentHeight = max(metrics.contentSize.height - removedHeight, 0)
        return max(contentHeight - metrics.visibleRect.height, 0)
    }

    private func clampedScrollY(forRootTop rootTop: CGFloat, maxOffsetY: CGFloat, metrics: CommentScrollMetrics) -> CGFloat {
        min(max(rootTop - visibleContentTopInset(for: metrics), 0), maxOffsetY)
    }

    private func coordinatedCollapseScrollTarget(
        for branch: CollapsingCommentBranch,
        expandedHeight: CGFloat,
        compactHeight: CGFloat
    ) -> CGFloat? {
        let metrics = latestScrollMetrics.latest
        let visibleRect = visibleContentRect(for: metrics)
        guard let rootFrame = rowFrames[branch.rootID],
              visibleRect.height > 0,
              metrics.contentSize.height > 0,
              metrics.visibleRect.height > 0
        else { return nil }

        guard rootFrame.minY < visibleRect.minY || rootFrame.minY >= visibleRect.maxY else {
            return nil
        }

        let removedHeight = max(expandedHeight - compactHeight, 0)
        let targetY = clampedScrollY(
            forRootTop: rootFrame.minY,
            maxOffsetY: maxContentOffsetY(afterRemoving: removedHeight, metrics: metrics),
            metrics: metrics
        )
        guard abs(targetY - metrics.visibleRect.minY) > 0.5 else { return nil }
        return targetY
    }

    private func scrollToPendingComment() {
        guard let targetID = pendingCommentID else { return }
        guard viewModel.visibleComments.contains(where: { $0.id == targetID }) else { return }

        scrollToComment(withID: targetID)
    }

    private func scrollToNextComment() {
        guard let targetID = viewModel.nextVisibleCommentID(after: visibleCommentTarget.topCommentID) else { return }
        scrollToComment(withID: targetID)
    }

    private func scrollToNextThread() {
        guard let targetID = viewModel.nextVisibleThreadID(after: visibleCommentTarget.topCommentID) else { return }
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

        withAnimation(.easeInOut(duration: 0.3)) {
            updates()
        }
    }

    private func toggleCommentVisibilityWithScrollPreservation(commentID: Int) {
        guard collapsingBranch == nil else { return }
        guard let state = rowState(forCommentID: commentID) else { return }
        if state.visibility == .visible {
            pendingScrollIntent = nil
            let branch = collapsingBranch(from: state)

            var transaction = Transaction()
            transaction.disablesAnimations = true
            withTransaction(transaction) {
                guard toggleCommentVisibility(state.id) != nil else {
                    pendingScrollIntent = nil
                    return
                }
                collapsingBranch = branch
            }
        } else {
            pendingScrollIntent = nil
            rowFrames[state.id] = nil

            withAnimation(Self.commentCollapseAnimation) {
                guard toggleCommentVisibility(state.id) != nil else {
                    pendingScrollIntent = nil
                    return
                }
            }
        }
    }

    private func collapsingBranch(from state: CommentRowState) -> CollapsingCommentBranch {
        let descendants = visibleDescendants(of: state)
        let rowIDs = Set([state.id] + descendants.map(\.id))
        let allIDs = [state.id] + descendants.map(\.id)
        let expandedHeight = measuredThreadHeight(forCommentIDs: allIDs, rootID: state.id)
        let lastID = allIDs.last ?? state.id
        let showsSeparatorAfter = showsRootSeparator(afterCommentID: lastID)

        return CollapsingCommentBranch(
            transitionID: UUID(),
            rootID: state.id,
            compactRoot: compactState(from: state),
            rowIDs: rowIDs,
            expandedHeight: expandedHeight,
            showsSeparatorAfter: showsSeparatorAfter
        )
    }

    private func measuredThreadHeight(forCommentIDs commentIDs: [Int], rootID: Int) -> CGFloat {
        guard let rootFrame = rowFrames[rootID] else { return 0 }

        let measuredFrames = commentIDs.compactMap { rowFrames[$0] }
        guard !measuredFrames.isEmpty else { return rootFrame.height }

        let maxY = measuredFrames.map(\.maxY).max() ?? rootFrame.maxY
        return max(rootFrame.height, maxY - rootFrame.minY)
    }

    private func visibleDescendants(of state: CommentRowState) -> [Comment] {
        guard let rootIndex = viewModel.visibleComments.firstIndex(where: { $0.id == state.id }) else {
            return []
        }

        return viewModel.visibleComments[viewModel.visibleComments.index(after: rootIndex)...]
            .prefix { $0.level > state.level }
            .map { $0 }
    }

    private func compactState(from state: CommentRowState) -> CommentRowState {
        CommentRowState(
            id: state.id,
            author: state.author,
            age: state.age,
            level: state.level,
            visibility: .compact,
            isPostAuthor: state.isPostAuthor,
            isUpvoted: state.isUpvoted,
            canVote: state.canVote,
            canUnvote: state.canUnvote,
            styledText: nil
        )
    }

    private func commentRow(for state: CommentRowState, in post: Post) -> some View {
        CommentRow(
            state: state,
            onToggle: { toggleCommentVisibilityWithScrollPreservation(commentID: state.id) },
            onUpvote: { upvoteComment(withID: state.id, in: post) },
            onUnvote: { unvoteComment(withID: state.id, in: post) },
            onCopy: { copyComment(withID: state.id) },
            onShare: { shareComment(withID: state.id) }
        )
    }

    private func upvoteComment(withID commentID: Int, in post: Post) {
        guard let comment = viewModel.comment(withID: commentID) else { return }
        Task { await votingViewModel.upvote(comment: comment, in: post) }
    }

    private func unvoteComment(withID commentID: Int, in post: Post) {
        guard let comment = viewModel.comment(withID: commentID) else { return }
        Task { await votingViewModel.unvote(comment: comment, in: post) }
    }

    private func copyComment(withID commentID: Int) {
        guard let comment = viewModel.comment(withID: commentID) else { return }
        UIPasteboard.general.string = CommentHTMLParser.plainText(fromHTML: comment.text)
    }

    private func shareComment(withID commentID: Int) {
        guard let comment = viewModel.comment(withID: commentID) else { return }
        ContentSharePresenter.shared.shareComment(comment)
    }

    private func rowState(forCommentID commentID: Int) -> CommentRowState? {
        guard let comment = viewModel.visibleComment(withID: commentID) else { return nil }
        return rowState(for: comment)
    }

    private func rowState(for comment: Comment) -> CommentRowState {
        let isCollapsed = viewModel.isCommentCollapsed(withID: comment.id)
        return CommentRowState(
            id: comment.id,
            author: comment.by,
            age: comment.age,
            level: comment.level,
            visibility: isCollapsed ? .compact : .visible,
            isPostAuthor: comment.by == viewModel.post?.by,
            isUpvoted: comment.upvoted,
            canVote: comment.voteLinks?.upvote != nil,
            canUnvote: comment.voteLinks?.unvote != nil,
            styledText: isCollapsed
                ? nil
                : CommentTextCache.styledText(for: comment, textScaling: textScaling)
        )
    }

    @ViewBuilder
    private func commentSeparator(isVisible: Bool) -> some View {
        if isVisible {
            Divider()
        }
    }

    private func commentRowTransition(for state: CommentRowState) -> AnyTransition {
        state.level == 0 ? .opacity : .commentTopReveal
    }

    @ViewBuilder
    private func commentRowGroup(for state: CommentRowState, in post: Post, showsSeparator: Bool) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            commentRow(for: state, in: post)
            commentSeparator(isVisible: showsSeparator)
        }
        .commentRowFrame(id: state.id, isEnabled: tracksRowFrames)
        .id(state.id)
        .transition(commentRowTransition(for: state))
    }

    @ViewBuilder
    private func collapsingCommentBranchView(_ branch: CollapsingCommentBranch, in post: Post) -> some View {
        CollapsingCommentBranchView(
            branch: branch,
            animation: Self.commentCollapseAnimation,
            onAnimationStarted: { expandedHeight, compactHeight in
                guard let targetY = coordinatedCollapseScrollTarget(
                    for: branch,
                    expandedHeight: expandedHeight,
                    compactHeight: compactHeight
                ) else { return }

                withAnimation(Self.commentCollapseAnimation) {
                    scrollPosition.scrollTo(y: targetY)
                }
            },
            onFinished: {
                if collapsingBranch?.rootID == branch.rootID {
                    var transaction = Transaction()
                    transaction.disablesAnimations = true
                    withTransaction(transaction) {
                        collapsingBranch = nil
                    }
                }
            },
            compactContent: {
                commentRowGroup(
                    for: branch.compactRoot,
                    in: post,
                    showsSeparator: branch.showsSeparatorAfter
                )
            }
        )
        .commentRowFrame(id: branch.rootID, isEnabled: tracksRowFrames)
        .id(branch.transitionID)
    }

    @ViewBuilder
    private func commentsRows(for post: Post) -> some View {
        let visibleComments = viewModel.visibleComments
        ForEach(visibleComments, id: \.id) { comment in
            let state = rowState(for: comment)
            if let collapsingBranch, collapsingBranch.rootID == state.id {
                collapsingCommentBranchView(collapsingBranch, in: post)
            } else if collapsingBranch?.rowIDs.contains(state.id) != true {
                commentRowGroup(
                    for: state,
                    in: post,
                    showsSeparator: showsRootSeparator(afterCommentID: state.id)
                )
            }
        }
    }

    private func showsRootSeparator(afterCommentID commentID: Int) -> Bool {
        guard
            let index = viewModel.visibleComments.firstIndex(where: { $0.id == commentID }),
            index < viewModel.visibleComments.index(before: viewModel.visibleComments.endIndex)
        else {
            return false
        }

        let nextIndex = viewModel.visibleComments.index(after: index)
        return viewModel.visibleComments[nextIndex].level == 0
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
            if onPostHeaderDragChanged != nil || onPostHeaderDragEnded != nil {
                postHeader(for: post)
                    .simultaneousGesture(postHeaderDragGesture)
            } else {
                postHeader(for: post)
            }
            Divider()
        }
    }

    private func postHeader(for post: Post) -> some View {
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
        .contentShape(Rectangle())
    }

    private var postHeaderDragGesture: some Gesture {
        DragGesture(minimumDistance: 18, coordinateSpace: .global)
            .onChanged { value in
                onPostHeaderDragChanged?(value)
            }
            .onEnded { value in
                onPostHeaderDragEnded?(value)
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

private struct CollapsingCommentBranchView<CompactContent: View>: View {
    let branch: CollapsingCommentBranch
    let animation: Animation
    let onAnimationStarted: (CGFloat, CGFloat) -> Void
    let onFinished: () -> Void
    @ViewBuilder let compactContent: () -> CompactContent

    @State private var hasStartedCollapse = false
    @State private var hasScheduledCollapse = false
    @State private var hasFinishedCollapse = false
    @State private var compactHeight: CGFloat?
    @State private var animatedHeight: CGFloat?

    private var currentHeight: CGFloat? {
        animatedHeight ?? max(branch.expandedHeight, compactHeight ?? 0)
    }

    var body: some View {
        compactContent()
            .fixedSize(horizontal: false, vertical: true)
            .collapsingBranchCompactHeight()
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .frame(height: currentHeight, alignment: .top)
        .clipped()
        .allowsHitTesting(false)
        .onPreferenceChange(CollapsingBranchCompactHeightPreferenceKey.self) { height in
            if height > 0 {
                compactHeight = height
            }
            startCollapseWhenMeasured()
        }
        .onAppear {
            startCollapseWhenMeasured()
        }
    }

    private func startCollapseWhenMeasured() {
        guard !hasStartedCollapse, !hasScheduledCollapse else { return }
        guard compactHeight != nil else { return }

        hasScheduledCollapse = true
        Task { @MainActor in
            guard !hasStartedCollapse else { return }
            guard let compactHeight else {
                hasScheduledCollapse = false
                return
            }

            hasStartedCollapse = true
            let expandedHeight = max(branch.expandedHeight, compactHeight)
            animatedHeight = expandedHeight
            onAnimationStarted(expandedHeight, compactHeight)
            withAnimation(animation, completionCriteria: .logicallyComplete) {
                animatedHeight = compactHeight
            } completion: {
                finishCollapseIfNeeded()
            }
        }
    }

    private func finishCollapseIfNeeded() {
        guard hasStartedCollapse, !hasFinishedCollapse else { return }
        hasFinishedCollapse = true
        onFinished()
    }
}

private struct NextCommentFloatingButton: View {
    let visibleCommentTarget: VisibleCommentTarget
    let onNextComment: () -> Void
    let onNextThread: () -> Void

    private var isEnabled: Bool {
        visibleCommentTarget.hasNextComment
    }

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
