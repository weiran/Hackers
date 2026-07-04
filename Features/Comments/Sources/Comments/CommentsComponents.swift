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

private enum CollapseScrollDecision {
    case none
    case scrollToRoot
    case deferUntilLayout
}

private enum CommentScrollIntent {
    case preserveCollapsedRoot(commentID: Int, afterRevision: Int)
    case revealComment(commentID: Int)
}

private enum CommentListTransitionKind {
    case collapsing
    case expanding
}

private struct CommentListTransition {
    let kind: CommentListTransitionKind
    let parentID: Int
    let rowIDs: Set<Int>
    var heightsByID: [Int: CGFloat]
    var targetHeightsByID: [Int: CGFloat]
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
}

struct CommentsContentView: View {
    private static let scrollMetricsUpdateDistance: CGFloat = 48

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
    @Binding var listAnimationsEnabled: Bool
    @State private var lastIsAtTop = true
    @State private var scrollPosition = ScrollPosition(idType: Int.self)
    @State private var rowFrames: [Int: CGRect] = [:]
    @State private var scrollMetrics = CommentScrollMetrics()
    @State private var visibleCommentTarget = VisibleCommentTarget()
    @State private var pendingScrollIntent: CommentScrollIntent?
    @State private var commentListTransition: CommentListTransition?
    @State private var commentListTransitionGeneration = 0
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

    private var tracksRowFrames: Bool {
        !presentationState.usesCustomHeaderBlur || pendingScrollIntent != nil || commentListTransition != nil
    }

    private var tracksScrollMetrics: Bool {
        !presentationState.usesCustomHeaderBlur || pendingScrollIntent != nil
    }

    private var visibleContentRect: CGRect {
        visibleContentRect(for: scrollMetrics)
    }

    private func visibleContentRect(for metrics: CommentScrollMetrics) -> CGRect {
        let rect = metrics.visibleRect
        guard rect.height > 0 else { return .zero }

        let topInset = max(metrics.contentInsets.top, commentScrollTopInset)
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
                guard tracksRowFrames else { return }
                guard rowFrames != newFrames else { return }
                rowFrames = newFrames
                updateCommentListTransitionTargets(with: newFrames)
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

    private func scrollPreservationIntent(for commentID: Int) -> CommentScrollIntent {
        .preserveCollapsedRoot(commentID: commentID, afterRevision: viewModel.visibleRevision + 1)
    }

    private func collapseScrollDecision(for state: CommentRowState) -> CollapseScrollDecision {
        guard !presentationState.usesCustomHeaderBlur || tracksRowFrames else {
            return .deferUntilLayout
        }

        guard let rootFrame = rowFrames[state.id],
              visibleContentRect.height > 0,
              scrollMetrics.contentSize.height > 0
        else {
            return .deferUntilLayout
        }

        let currentVisibleRect = visibleContentRect
        if rootFrame.minY < currentVisibleRect.minY || rootFrame.minY >= currentVisibleRect.maxY {
            return .scrollToRoot
        }

        let removedHeight = estimatedCollapsedHeightDelta(for: state, rootFrame: rootFrame)
        let predictedMaxOffsetY = maxContentOffsetY(afterRemoving: removedHeight)
        let predictedVisibleMinY = min(scrollMetrics.visibleRect.minY, predictedMaxOffsetY)
        let predictedVisibleTop = predictedVisibleMinY + visibleContentTopInset
        let predictedVisibleBottom = predictedVisibleMinY
            + scrollMetrics.visibleRect.height
            - scrollMetrics.contentInsets.bottom

        if rootFrame.minY >= predictedVisibleTop, rootFrame.minY < predictedVisibleBottom {
            return .none
        }

        return .scrollToRoot
    }

    private func maxContentOffsetY(afterRemoving removedHeight: CGFloat) -> CGFloat {
        let contentHeight = max(scrollMetrics.contentSize.height - removedHeight, 0)
        return max(contentHeight - scrollMetrics.visibleRect.height, 0)
    }

    private func estimatedCollapsedHeightDelta(for state: CommentRowState, rootFrame: CGRect) -> CGFloat {
        let descendants = visibleDescendants(of: state)
        let measuredDescendantIDs = descendants.map(\.id).filter { rowFrames[$0] != nil }
        let measuredDescendantHeight = measuredDescendantIDs.reduce(CGFloat.zero) { total, id in
            total + max(rowFrames[id]?.height ?? 0, 0)
        }
        let missingDescendantCount = max(descendants.count - measuredDescendantIDs.count, 0)
        let missingDescendantHeight = CGFloat(missingDescendantCount) * averageVisibleCommentRowHeight
        let rootHeightDelta = max(rootFrame.height - estimatedCompactCommentRowHeight, 0)

        return rootHeightDelta + measuredDescendantHeight + missingDescendantHeight
    }

    private func visibleDescendants(of state: CommentRowState) -> [Comment] {
        guard let rootIndex = viewModel.visibleComments.firstIndex(where: { $0.id == state.id }) else {
            return []
        }

        return viewModel.visibleComments[viewModel.visibleComments.index(after: rootIndex)...]
            .prefix { $0.level > state.level }
            .map { $0 }
    }

    private var averageVisibleCommentRowHeight: CGFloat {
        let visibleCommentFrames = viewModel.visibleComments.compactMap { rowFrames[$0.id]?.height }
        guard !visibleCommentFrames.isEmpty else { return estimatedCompactCommentRowHeight }
        return visibleCommentFrames.reduce(0, +) / CGFloat(visibleCommentFrames.count)
    }

    private var estimatedCompactCommentRowHeight: CGFloat {
        let metadataHeight = UIFont.preferredFont(forTextStyle: .subheadline).lineHeight
        let previewHeight = UIFont.preferredFont(forTextStyle: .body).lineHeight
        return max(68, ceil((metadataHeight + previewHeight) * textScaling + 40))
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
            guard let isRootVisible = collapsedRootVisibility(for: commentID) else { return }
            if isRootVisible {
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

    private func collapsedRootVisibility(for commentID: Int) -> Bool? {
        CollapseScrollVisibility.isMeasuredRootTopVisible(
            frame: rowFrames[commentID],
            visibleRect: visibleContentRect
        )
    }

    private func scrollCollapsedRootToTop(commentID: Int) {
        scrollPosition.scrollTo(id: commentID, anchor: .commentTop)
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

        performListAnimation {
            updates()
        }
    }

    private func performListAnimation(_ updates: () -> Void, completion: (() -> Void)? = nil) {
        listAnimationGeneration += 1
        let generation = listAnimationGeneration
        listAnimationsEnabled = true

        withAnimation(.easeInOut(duration: 0.3), completionCriteria: .logicallyComplete) {
            updates()
        } completion: {
            if listAnimationGeneration == generation {
                listAnimationsEnabled = false
            }
            completion?()
        }
    }

    private func performWithoutListAnimation(_ updates: () -> Void) {
        var transaction = Transaction()
        transaction.disablesAnimations = true

        withTransaction(transaction) {
            updates()
        }
    }

    private func toggleCommentVisibilityWithScrollPreservation(commentID: Int) {
        guard let state = rowState(forCommentID: commentID) else { return }

        if state.visibility == .visible {
            collapseCommentBranch(from: state)
        } else {
            expandCommentBranch(from: state)
        }
    }

    private func collapseCommentBranch(from state: CommentRowState) {
        let rows = viewModel.visibleComments.map(rowState)
        let branchRows = [state] + visibleDescendants(of: state).map(rowState)
        let branchIDs = Set(branchRows.map(\.id))
        let collapseScrollDecision = collapseScrollDecision(for: state)
        let deferredScrollIntent = scrollPreservationIntent(for: state.id)
        let initialHeights = measuredHeights(for: branchRows, in: rows)
        var targetHeights = initialHeights
        targetHeights[state.id] = compactRowGroupHeight(for: state, in: rows)
        for descendant in branchRows where descendant.id != state.id {
            targetHeights[descendant.id] = 0
        }

        performWithoutListAnimation {
            commentListTransition = CommentListTransition(
                kind: .collapsing,
                parentID: state.id,
                rowIDs: branchIDs,
                heightsByID: initialHeights,
                targetHeightsByID: targetHeights
            )
        }

        commentListTransitionGeneration += 1
        let transitionGeneration = commentListTransitionGeneration

        performListAnimation {
            commentListTransition?.heightsByID = targetHeights
        } completion: {
            finishCollapseTransition(
                generation: transitionGeneration,
                state: state,
                collapseScrollDecision: collapseScrollDecision,
                deferredScrollIntent: deferredScrollIntent
            )
        }
    }

    private func expandCommentBranch(from state: CommentRowState) {
        let rowsBefore = viewModel.visibleComments.map(rowState)
        let compactHeight = measuredRowGroupHeight(for: state, in: rowsBefore)
        var expandedState: CommentRowState?
        var branchRows: [CommentRowState] = []

        performWithoutListAnimation {
            guard let toggledComment = toggleCommentVisibility(state.id) else {
                pendingScrollIntent = nil
                commentListTransition = nil
                return
            }

            expandedState = rowState(for: toggledComment)
            guard let expandedState else { return }
            branchRows = [expandedState] + visibleDescendants(of: expandedState).map(rowState)
            let rowsAfter = viewModel.visibleComments.map(rowState)
            var initialHeights: [Int: CGFloat] = [:]
            var targetHeights: [Int: CGFloat] = [:]

            for branchRow in branchRows {
                if branchRow.id == state.id {
                    initialHeights[branchRow.id] = compactHeight
                } else {
                    initialHeights[branchRow.id] = 0
                }
                targetHeights[branchRow.id] = measuredRowGroupHeight(for: branchRow, in: rowsAfter)
            }

            commentListTransition = CommentListTransition(
                kind: .expanding,
                parentID: state.id,
                rowIDs: Set(branchRows.map(\.id)),
                heightsByID: initialHeights,
                targetHeightsByID: targetHeights
            )
        }

        guard commentListTransition != nil else { return }

        commentListTransitionGeneration += 1
        let transitionGeneration = commentListTransitionGeneration

        Task { @MainActor in
            await Task.yield()
            guard commentListTransitionGeneration == transitionGeneration,
                  let transition = commentListTransition
            else { return }

            performListAnimation {
                commentListTransition?.heightsByID = transition.targetHeightsByID
            } completion: {
                finishExpandTransition(generation: transitionGeneration)
            }
        }
    }

    private func finishCollapseTransition(
        generation: Int,
        state: CommentRowState,
        collapseScrollDecision: CollapseScrollDecision,
        deferredScrollIntent: CommentScrollIntent
    ) {
        guard commentListTransitionGeneration == generation else { return }

        performWithoutListAnimation {
            if case .deferUntilLayout = collapseScrollDecision {
                rowFrames = [:]
                pendingScrollIntent = deferredScrollIntent
            } else {
                pendingScrollIntent = nil
            }

            guard let toggledComment = toggleCommentVisibility(state.id) else {
                commentListTransition = nil
                pendingScrollIntent = nil
                return
            }

            commentListTransition = nil

            if case .scrollToRoot = collapseScrollDecision {
                scrollCollapsedRootToTop(commentID: toggledComment.id)
            }
        }

        if pendingScrollIntent != nil {
            resolvePendingScrollIntent(animated: true)
        }
    }

    private func finishExpandTransition(generation: Int) {
        guard commentListTransitionGeneration == generation else { return }

        performWithoutListAnimation {
            commentListTransition = nil
        }
    }

    private func measuredHeights(
        for branchRows: [CommentRowState],
        in visibleRows: [CommentRowState]
    ) -> [Int: CGFloat] {
        Dictionary(uniqueKeysWithValues: branchRows.map { state in
            (state.id, measuredRowGroupHeight(for: state, in: visibleRows))
        })
    }

    private func measuredRowGroupHeight(
        for state: CommentRowState,
        in visibleRows: [CommentRowState]
    ) -> CGFloat {
        rowFrames[state.id]?.height ?? fallbackRowGroupHeight(for: state, in: visibleRows)
    }

    private func fallbackRowGroupHeight(
        for state: CommentRowState,
        in visibleRows: [CommentRowState]
    ) -> CGFloat {
        let baseHeight = state.visibility == .compact
            ? estimatedCompactCommentRowHeight
            : averageVisibleCommentRowHeight
        return baseHeight + separatorHeight(for: state, in: visibleRows)
    }

    private func compactRowGroupHeight(
        for state: CommentRowState,
        in visibleRows: [CommentRowState]
    ) -> CGFloat {
        estimatedCompactCommentRowHeight + separatorHeight(for: state, in: visibleRows)
    }

    private func separatorHeight(for state: CommentRowState, in visibleRows: [CommentRowState]) -> CGFloat {
        state.id == visibleRows.last?.id ? 0 : 1
    }

    private func updateCommentListTransitionTargets(with newFrames: [Int: CGRect]) {
        guard var transition = commentListTransition else { return }

        var changed = false
        for rowID in transition.rowIDs {
            guard let measuredHeight = newFrames[rowID]?.height, measuredHeight > 0 else { continue }
            let targetHeight: CGFloat
            if transition.kind == .collapsing {
                guard rowID != transition.parentID else { continue }
                targetHeight = 0
            } else {
                targetHeight = measuredHeight
            }
            if abs((transition.targetHeightsByID[rowID] ?? 0) - targetHeight) > 0.5 {
                transition.targetHeightsByID[rowID] = targetHeight
                changed = true
            }
        }

        guard changed else { return }

        if transition.heightsByID != transition.targetHeightsByID {
            commentListTransition = transition
        } else {
            performListAnimation {
                commentListTransition?.targetHeightsByID = transition.targetHeightsByID
                commentListTransition?.heightsByID = transition.targetHeightsByID
            }
        }
    }

    private func rowHeightOverride(for state: CommentRowState) -> CGFloat? {
        commentListTransition?.heightsByID[state.id]
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
        .padding(.leading, CGFloat(16 + min(state.level, 6) * 14))
        .padding(.trailing, 16)
        .padding(.vertical, 16)
        .accessibilityIdentifier("comments.comment.\(state.id)")
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
        UIPasteboard.general.string = comment.text.strippingHTML()
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
        CommentRowState(
            id: comment.id,
            author: comment.by,
            age: comment.age,
            level: comment.level,
            visibility: comment.visibility,
            isPostAuthor: comment.by == viewModel.post?.by,
            isUpvoted: comment.upvoted,
            canVote: comment.voteLinks?.upvote != nil,
            canUnvote: comment.voteLinks?.unvote != nil,
            styledText: comment.visibility == .visible
                ? CommentTextCache.styledText(for: comment, textScaling: textScaling)
                : nil,
            compactText: comment.visibility == .compact ? comment.text.strippingHTML() : nil
        )
    }

    @ViewBuilder
    private func commentRowGroup(for state: CommentRowState, in post: Post, isLast: Bool) -> some View {
        let group = VStack(alignment: .leading, spacing: 0) {
            commentRow(for: state, in: post)
            if !isLast {
                Divider()
                    .padding(.leading, CGFloat(16 + min(state.level, 6) * 14))
            }
        }

        if let height = rowHeightOverride(for: state) {
            group
                .commentRowFrame(id: state.id, isEnabled: tracksRowFrames)
                .id(state.id)
                .transition(.identity)
                .frame(height: max(height, 0), alignment: .top)
                .clipped()
        } else {
            group
                .commentRowFrame(id: state.id, isEnabled: tracksRowFrames)
                .id(state.id)
                .transition(.identity)
        }
    }

    @ViewBuilder
    private func commentsRows(for post: Post) -> some View {
        let rows = viewModel.visibleComments.map(rowState)
        ForEach(rows) { state in
            commentRowGroup(for: state, in: post, isLast: state.id == rows.last?.id)
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
