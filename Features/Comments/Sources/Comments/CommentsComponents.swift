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

private extension UnitPoint {
    static let commentTop = UnitPoint(x: 0.5, y: 0)
}

private enum CommentsScrollTarget: Hashable {
    case header
    case comment(Int)

    var commentID: Int? {
        guard case let .comment(id) = self else { return nil }
        return id
    }
}

private struct BottomControlsHeightKey: PreferenceKey {
    static let defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

struct CommentsContentView: View {
    private static let commentCollapseAnimation = Animation.easeInOut(duration: 0.3)

    @Environment(\.textScaling) private var textScaling
    @Environment(SessionService.self) private var sessionService
    let showsPostHeader: Bool
    let handleLinkTap: () -> Void
    let toggleCommentVisibility: (Int) -> Comment?
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
    let canComment: Bool
    let composer: CommentComposerModel
    @Binding var replyScrollTarget: Int?
    let onReply: (Int, String) -> Void
    let onSubmitComposerDraft: () -> Void
    @State private var visibleCommentTarget = VisibleCommentTarget()
    @State private var bottomControlsHeight: CGFloat = 0

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
            ScrollViewReader { proxy in
                ZStack(alignment: .bottom) {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 0) {
                            postHeaderSection(for: post)
                            commentsSection(for: post)
                        }
                        .scrollTargetLayout()
                    }
                    .onScrollTargetVisibilityChange(
                        idType: CommentsScrollTarget.self,
                        threshold: 0.1
                    ) { visibleTargets in
                        DispatchQueue.main.async { @MainActor in
                            updateVisibleCommentTarget(visibleTargets: visibleTargets)
                        }
                    }
                    // Scrolling leaves the editor and keyboard in place.
                    .scrollDismissesKeyboard(.never)
                    // A focused editor can cause the first tap after a scroll
                    // to be handled by the scroll view instead of the row's
                    // local gesture. Keep that non-scroll interaction path
                    // explicit so taps and holds still dismiss the composer.
                    .onTapGesture(perform: dismissComposerForInteraction)
                    .onLongPressGesture(minimumDuration: 0.5) {
                        dismissComposerForInteraction()
                    }
                    .modifier(CommentSwipeActionsContainerModifier())
                    .onScrollGeometryChange(for: CGFloat.self, of: { geometry in
                        geometry.contentOffset.y + geometry.contentInsets.top
                    }, action: { _, offsetY in
                        DispatchQueue.main.async { @MainActor in
                            updateHeaderState(offsetY: offsetY)
                        }
                    })
                    .accessibilityIdentifier(AccessibilityIdentifier.Comments.list)
                    .safeAreaInset(edge: .top, spacing: 0) {
                        commentScrollTopSafeAreaInset
                    }
                    .safeAreaInset(edge: .bottom, spacing: 0) {
                        if bottomControlsHeight > 0 {
                            Color.clear
                                .frame(height: bottomControlsHeight)
                                .allowsHitTesting(false)
                        }
                    }
                    CommentsFloatingControls(
                        canComment: canComment,
                        composer: composer,
                        showsNextCommentButton: viewModel.showNextCommentButton,
                        hasNextComment: visibleCommentTarget.hasNextComment,
                        onNextComment: { scrollToNextComment(using: proxy) },
                        onNextThread: { scrollToNextThread(using: proxy) },
                        onSubmit: onSubmitComposerDraft
                    )
                    .frame(maxWidth: .infinity)
                    .background(
                        GeometryReader { controlsProxy in
                            Color.clear.preference(
                                key: BottomControlsHeightKey.self,
                                value: controlsProxy.size.height
                            )
                        }
                    )
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .onPreferenceChange(BottomControlsHeightKey.self) { height in
                    bottomControlsHeight = height
                }
                .onChange(of: pendingCommentID) { _, _ in
                    scrollToPendingComment(using: proxy)
                }
                .onChange(of: viewModel.visibleRevision) { _, _ in
                    scrollToPendingComment(using: proxy)
                    scrollToReplyTarget(using: proxy)
                }
                .onChange(of: replyScrollTarget) { _, _ in
                    scrollToReplyTarget(using: proxy)
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
    }
}

private extension CommentsContentView {
    private func updateHeaderState(offsetY: CGFloat) {
        updateHeaderState(offsetY: offsetY, animatesTitleChange: true)
    }

    private func updateHeaderState(offsetY: CGFloat, animatesTitleChange: Bool) {
        let shouldShowTitle = titleVisibility.isVisible ? offsetY > 24 : offsetY > 56
        if shouldShowTitle != titleVisibility.isVisible {
            let updateTitle = {
                titleVisibility.setVisible(shouldShowTitle)
                updateTitleVisibility?(shouldShowTitle)
            }

            if animatesTitleChange {
                withAnimation(.easeInOut(duration: 0.3)) {
                    updateTitle()
                }
            } else {
                var transaction = Transaction()
                transaction.disablesAnimations = true
                withTransaction(transaction) {
                    updateTitle()
                }
            }
        }
    }

    private func updateVisibleCommentTarget(visibleTargets: [CommentsScrollTarget]) {
        let topID = visibleTargets.first?.commentID
        visibleCommentTarget.update(
            topCommentID: topID,
            hasNextComment: viewModel.hasNextVisibleComment(after: topID)
        )
    }

    private func scrollToPendingComment(using proxy: ScrollViewProxy) {
        guard let targetID = pendingCommentID else { return }
        guard viewModel.visibleComments.contains(where: { $0.id == targetID }) else { return }

        scrollToComment(withID: targetID, using: proxy)

        // The row may not have been laid out yet when visibleRevision changes.
        // Repeat once after the list has committed the inserted row.
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(450))
            guard viewModel.visibleComments.contains(where: { $0.id == targetID }) else { return }
            withAnimation(.easeInOut(duration: 0.3)) {
                proxy.scrollTo(CommentsScrollTarget.comment(targetID), anchor: .commentTop)
            }
        }
    }

    /// Scrolls the reply target to the top of the viewport once visible, then
    /// issues one corrective scroll after the keyboard settles.
    private func scrollToReplyTarget(using proxy: ScrollViewProxy) {
        guard let targetID = replyScrollTarget else { return }
        guard viewModel.visibleComments.contains(where: { $0.id == targetID }) else { return }

        withAnimation(.easeInOut(duration: 0.3)) {
            proxy.scrollTo(CommentsScrollTarget.comment(targetID), anchor: .commentTop)
        }
        replyScrollTarget = nil

        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(450))
            withAnimation(.easeInOut(duration: 0.3)) {
                proxy.scrollTo(CommentsScrollTarget.comment(targetID), anchor: .commentTop)
            }
        }
    }

    private func scrollToNextComment(using proxy: ScrollViewProxy) {
        guard let targetID = viewModel.nextVisibleCommentID(after: visibleCommentTarget.topCommentID) else { return }
        scrollToComment(withID: targetID, using: proxy)
    }

    private func scrollToNextThread(using proxy: ScrollViewProxy) {
        guard let targetID = viewModel.nextVisibleThreadID(after: visibleCommentTarget.topCommentID) else { return }
        scrollToComment(withID: targetID, using: proxy)
    }

    private func scrollToComment(withID targetID: Int, using proxy: ScrollViewProxy) {
        withAnimation(.easeInOut(duration: 0.3)) {
            proxy.scrollTo(CommentsScrollTarget.comment(targetID), anchor: .commentTop)
        }
        pendingCommentID = nil
    }

    private func toggleCommentVisibilityWithNativeAnimation(commentID: Int) {
        withAnimation(Self.commentCollapseAnimation) {
            _ = toggleCommentVisibility(commentID)
        }
    }

    private func commentRow(for state: CommentRowState, in post: Post) -> some View {
        CommentRow(
            state: state,
            onToggle: { toggleCommentVisibilityWithNativeAnimation(commentID: state.id) },
            onUpvote: { upvoteComment(withID: state.id, in: post) },
            onUnvote: { unvoteComment(withID: state.id, in: post) },
            onCopy: { copyComment(withID: state.id) },
            onShare: { shareComment(withID: state.id) },
            onReply: { onReply(state.id, state.author) },
            onInteraction: dismissComposerForInteraction
        )
        .if(viewModel.swipeCollapseThreads) { row in
            row.swipeActions(edge: .trailing, allowsFullSwipe: true) {
                Button {
                    dismissComposerForInteraction()
                    collapseThread(for: state)
                } label: {
                    Label(
                        state.visibility == .visible ? "Collapse Thread" : "Expand Thread",
                        systemImage: state.visibility == .visible ? "minus.circle" : "plus.circle"
                    )
                }
                .accessibilityIdentifier(AccessibilityIdentifier.Comments.collapseThreadAction(state.id))
            }
        }
    }

    /// Swipe-to-collapse keeps the pre-scroll-view-migration behaviour: collapsing any
    /// row hides its whole thread from the level-0 root, not just that row's subtree.
    private func collapseThread(for state: CommentRowState) {
        guard let comment = viewModel.comment(withID: state.id) else { return }
        withAnimation(Self.commentCollapseAnimation) {
            _ = viewModel.hideCommentBranch(comment)
        }
    }

    private func dismissComposerForInteraction() {
        guard composer.isExpanded else { return }
        composer.collapsePreservingDraft()
    }

    private func upvoteComment(withID commentID: Int, in post: Post) {
        guard let comment = viewModel.comment(withID: commentID) else { return }
        Task { await votingViewModel.upvote(comment: comment, in: post) { [viewModel] updated in
            viewModel.replace(comment: updated)
        } }
    }

    private func unvoteComment(withID commentID: Int, in post: Post) {
        guard let comment = viewModel.comment(withID: commentID) else { return }
        Task { await votingViewModel.unvote(comment: comment, in: post) { [viewModel] updated in
            viewModel.replace(comment: updated)
        } }
    }

    private func copyComment(withID commentID: Int) {
        guard let comment = viewModel.comment(withID: commentID) else { return }
        UIPasteboard.general.string = CommentHTMLParser.plainText(fromHTML: comment.text)
    }

    private func shareComment(withID commentID: Int) {
        guard let comment = viewModel.comment(withID: commentID) else { return }
        ContentSharePresenter.shared.shareComment(comment)
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
            isVoting: votingViewModel.votingState(for: comment).isVoting,
            isAuthenticated: sessionService.authenticationState == .authenticated,
            canVote: comment.voteLinks?.upvote != nil,
            canUnvote: comment.voteLinks?.unvote != nil,
            canReply: canComment && comment.id > 0,
            isCommentSubmissionInProgress: composer.isPosting,
            styledText: isCollapsed && !comment.isFlagged
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

    @ViewBuilder
    private func commentRowGroup(
        for state: CommentRowState,
        in post: Post,
        showsSeparator: Bool
    ) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            commentRow(for: state, in: post)
            commentSeparator(isVisible: showsSeparator)
        }
        .id(CommentsScrollTarget.comment(state.id))
        .transition(.opacity)
    }

    @ViewBuilder
    private func commentsRows(for post: Post) -> some View {
        let visibleComments = viewModel.visibleComments
        ForEach(visibleComments, id: \.id) { comment in
            let state = rowState(for: comment)
            commentRowGroup(
                for: state,
                in: post,
                showsSeparator: viewModel.showsRootSeparator(afterCommentID: state.id)
            )
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
        .id(CommentsScrollTarget.header)
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

/// Row `swipeActions` only work inside a `List` before iOS 27; `swipeActionsContainer`
/// extends them to the comments `ScrollView`. On earlier OSes the rows render without
/// swipe actions.
private struct CommentSwipeActionsContainerModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 27, *) {
            content.swipeActionsContainer()
        } else {
            content
        }
    }
}

/// Bottom floating controls: the shared composer plus the next-comment
/// button. The composer fills the remaining width next to a control that is
/// visible as soon as the comments panel appears and enabled once a target is
/// available.
private struct CommentsFloatingControls: View {
    let canComment: Bool
    @Bindable var composer: CommentComposerModel
    let showsNextCommentButton: Bool
    let hasNextComment: Bool
    let onNextComment: () -> Void
    let onNextThread: () -> Void
    let onSubmit: () -> Void

    var body: some View {
        if showsControls {
            HStack(alignment: .bottom, spacing: 12) {
                if canComment {
                    CommentComposerView(model: composer, onSubmit: onSubmit)
                }
                if showsNextButton {
                    NextCommentFloatingButton(
                        isEnabled: hasNextComment,
                        onNextComment: onNextComment,
                        onNextThread: onNextThread
                    )
                }
            }
            .frame(maxWidth: .infinity, alignment: showsNextButton && !canComment ? .trailing : .leading)
            // The viewport supplied by the sheet already starts at the system
            // horizontal safe area. Lay the control row out like a system
            // bottom toolbar while collapsed; the expanded editor uses a
            // tighter inset closer to the screen edges.
            .padding(.horizontal, composer.isExpanded ? 8 : 16)
            // Give the collapsed row a clear visual separation from the
            // preserved bottom safe area. The expanded editor uses a tighter
            // keyboard gap.
            .padding(.bottom, composer.isExpanded ? 8 : 24)
            .animation(.easeInOut(duration: 0.2), value: composer.isExpanded)
        }
    }

    private var showsControls: Bool {
        canComment || showsNextCommentButton
    }

    private var showsNextButton: Bool {
        // Keep the control in the row from the moment the panel appears. It
        // remains disabled until the first visible target is known.
        !composer.isExpanded && showsNextCommentButton
    }
}

private struct NextCommentFloatingButton: View {
    let isEnabled: Bool
    let onNextComment: () -> Void
    let onNextThread: () -> Void
    @State private var performedLongPress = false

    var body: some View {
        Button {
            guard !performedLongPress else {
                performedLongPress = false
                return
            }
            onNextComment()
        } label: {
            Image(systemName: "arrow.down")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(isEnabled ? Color.primary : Color.secondary)
                .frame(width: 48, height: 48)
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .glassEffect(.regular.interactive(isEnabled), in: .circle)
        .opacity(isEnabled ? 1 : 0.55)
        .disabled(!isEnabled)
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.45)
                .onEnded { _ in
                    guard isEnabled else { return }
                    performedLongPress = true
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    onNextThread()
                }
        )
        .accessibilityLabel("Next comment")
        .accessibilityHint("Long press for next thread")
        .accessibilityAction(named: Text("Next thread")) {
            guard isEnabled else { return }
            onNextThread()
        }
        .accessibilityIdentifier(AccessibilityIdentifier.Comments.nextCommentButton)
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
    let onPostUpdated: @MainActor @Sendable (Post) -> Void
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
