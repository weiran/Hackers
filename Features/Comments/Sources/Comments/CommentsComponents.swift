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

struct CommentsContentView: View {
    @State var viewModel: CommentsViewModel
    @State var votingViewModel: VotingViewModel
    let showsPostHeader: Bool
    @Binding var showTitle: Bool
    @Binding var visibleCommentPositions: [Int: CGRect]
    @Binding var pendingCommentID: Int?
    @Binding var listAnimationsEnabled: Bool
    let handleLinkTap: () -> Void
    let toggleCommentVisibility: (Comment, @escaping (String) -> Void) -> Void
    let hideCommentBranch: (Comment, @escaping (String) -> Void) -> Void
    var body: some View {
        Group {
            if let post = viewModel.post {
                content(for: post)
            }
        }
    }
    private func content(for post: Post) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            ScrollViewReader { proxy in
                List {
                    postHeaderSection(for: post)
                    commentsSection(for: post, proxy: proxy)
                }
                .onScrollGeometryChange(for: Bool.self, of: { geometry in
                    geometry.contentOffset.y + geometry.contentInsets.top > 40
                }, action: { _, newValue in
                    showTitle = newValue
                })
                .listStyle(.plain)
                .transaction { transaction in
                    transaction.disablesAnimations = !listAnimationsEnabled
                }
                .onChange(of: pendingCommentID) { _, _ in
                    scrollToPendingComment(with: proxy)
                }
                .onChange(of: viewModel.visibleComments) { _, _ in
                    scrollToPendingComment(with: proxy)
                }
            }
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
                onLinkTap: { handleLinkTap() },
                onPostUpdated: { updatedPost in
                    viewModel.post = updatedPost
                },
                onBookmarkToggle: { await viewModel.toggleBookmark() }
            )
            .id("header")
            .background(GeometryReader { geometry in
                Color.clear.preference(
                    key: ViewOffsetKey.self,
                    value: geometry.frame(in: .global).minY,
                )
            })
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
                viewModel: viewModel,
                votingViewModel: votingViewModel,
                post: post,
                visibleCommentPositions: $visibleCommentPositions,
                toggleCommentVisibility: { comment in
                    toggleCommentVisibility(comment) { id in
                        proxy.scrollTo(id, anchor: .top)
                    }
                },
                hideCommentBranch: { comment in
                    hideCommentBranch(comment) { id in
                        proxy.scrollTo(id, anchor: .top)
                    }
                },
            )
        }
    }
    private func scrollToPendingComment(with proxy: ScrollViewProxy) {
        guard let targetID = pendingCommentID else { return }
        guard viewModel.visibleComments.contains(where: { $0.id == targetID }) else { return }

        Task { @MainActor in
            withAnimation(.easeInOut) {
                proxy.scrollTo("comment-\(targetID)", anchor: .top)
            }
            pendingCommentID = nil
        }
    }
}
struct CommentsForEach: View {
    @State var viewModel: CommentsViewModel
    @State var votingViewModel: VotingViewModel
    let post: Post
    @Binding var visibleCommentPositions: [Int: CGRect]
    let toggleCommentVisibility: (Comment) -> Void
    let hideCommentBranch: (Comment) -> Void
    var body: some View {
        ForEach(viewModel.visibleComments, id: \.id) { comment in
            CommentRow(
                comment: comment,
                post: post,
                votingViewModel: votingViewModel,
                onToggle: { toggleCommentVisibility(comment) },
                onHide: { hideCommentBranch(comment) },
            )
            .id("comment-\(comment.id)")
            .background(GeometryReader { geometry in
                Color.clear.preference(
                    key: CommentPositionsPreferenceKey.self,
                    value: [comment.id: geometry.frame(in: .global)],
                )
            })
            .listRowSeparator(.visible)
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
        .onPreferenceChange(CommentPositionsPreferenceKey.self) { positions in
            if visibleCommentPositions != positions {
                visibleCommentPositions = positions
            }
        }
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
                onBookmarkTap: { await onBookmarkToggle() }
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
struct ToolbarTitle: View {
    let post: Post
    let showTitle: Bool
    let showThumbnails: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                ThumbnailView(url: post.url, isEnabled: showThumbnails)
                    .frame(width: 33, height: 33)
                    .clipShape(.rect(cornerRadius: 10))
                Text(post.title)
                    .scaledFont(.headline)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(.isButton)
        .accessibilityHint("Open link")
        .opacity(showTitle ? 1.0 : 0.0)
        .offset(y: showTitle ? 0 : 20)
        .animation(.easeInOut(duration: 0.3), value: showTitle)
    }
}
struct BookmarkToolbarButton: View {
    let isBookmarked: Bool
    let toggleBookmark: @Sendable () async -> Bool
    @State private var isSubmitting = false

    var body: some View {
        Button {
            guard !isSubmitting else { return }
            isSubmitting = true
            Task { @MainActor in
                _ = await toggleBookmark()
                isSubmitting = false
            }
        } label: {
            Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
        }
        .accessibilityLabel(isBookmarked ? "Remove Bookmark" : "Save Bookmark")
        .accessibilityHint(
            isBookmarked
                ? "Double-tap to remove from bookmarks"
                : "Double-tap to add to bookmarks"
        )
        .disabled(isSubmitting)
    }
}
struct ShareMenu: View {
    let post: Post

    var body: some View {
        Button {
            ContentSharePresenter.shared.shareURL(post.hackerNewsURL, title: post.title)
        } label: {
            Image(systemName: "square.and.arrow.up")
                .accessibilityLabel("Share")
        }
    }
}
struct LoadingView: View {
    var body: some View {
        AppLoadingStateView(message: "Loading...")
    }
}
struct EmptyCommentsView: View {
    var body: some View {
        AppEmptyStateView(iconSystemName: "bubble.left", title: "No comments yet")
    }
}
struct ViewOffsetKey: PreferenceKey {
    typealias Value = CGFloat
    static let defaultValue = CGFloat.zero
    static func reduce(value: inout Value, nextValue: () -> Value) { value += nextValue() }
}
struct CommentPositionsPreferenceKey: PreferenceKey {
    typealias Value = [Int: CGRect]
    static let defaultValue: [Int: CGRect] = [:]
    static func reduce(value: inout Value, nextValue: () -> Value) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}
// MARK: - Helpers
extension View {
    func plainListRow() -> some View {
        listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets())
    }
}
