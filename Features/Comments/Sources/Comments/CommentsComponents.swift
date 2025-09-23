//
//  CommentsComponents.swift
//  Comments
//
//  Extracted subviews and helpers from CommentsView to reduce file length
//

import DesignSystem
import Domain
import Shared
import SwiftUI

struct CommentsContentView: View {
    @State var viewModel: CommentsViewModel
    @State var votingViewModel: VotingViewModel
    @Binding var showTitle: Bool
    @Binding var hasMeasuredInitialOffset: Bool
    @Binding var visibleCommentPositions: [Int: CGRect]
    @Binding var pendingCommentID: Int?
    let handleLinkTap: () -> Void
    let toggleCommentVisibility: (Comment, @escaping (String) -> Void) -> Void

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
                    PostHeader(
                        post: post,
                        votingViewModel: votingViewModel,
                        onLinkTap: { handleLinkTap() },
                        onPostUpdate: { updated in
                            viewModel.post = updated
                        },
                    )
                    .id("header")
                    .background(GeometryReader { geometry in
                        Color.clear.preference(
                            key: ViewOffsetKey.self,
                            value: geometry.frame(in: .global).minY,
                        )
                    })
                    .onPreferenceChange(ViewOffsetKey.self) { offset in
                        let shouldShowTitle = offset < 50
                        if !hasMeasuredInitialOffset {
                            hasMeasuredInitialOffset = true
                            showTitle = shouldShowTitle
                        } else if showTitle != shouldShowTitle {
                            showTitle = shouldShowTitle
                        }
                    }
                    .listRowSeparator(.hidden)
                    .if(post.voteLinks?.upvote != nil && !post.upvoted) { view in
                        view.swipeActions(edge: .leading, allowsFullSwipe: true) {
                            Button {
                                Task {
                                    var mutablePost = post
                                    await votingViewModel.upvote(post: &mutablePost)
                                    await MainActor.run { viewModel.post = mutablePost }
                                }
                            } label: {
                                Image(systemName: "arrow.up")
                            }
                            .tint(AppColors.upvotedColor)
                            .accessibilityLabel("Upvote")
                        }
                    }

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
                        )
                    }
                }
                .listStyle(.plain)
                .transaction { transaction in
                    transaction.disablesAnimations = true
                }
                .onChange(of: pendingCommentID) { _ in
                    scrollToPendingComment(with: proxy)
                }
                .onChange(of: viewModel.visibleComments) { _ in
                    scrollToPendingComment(with: proxy)
                }
            }
        }
    }

    private func scrollToPendingComment(with proxy: ScrollViewProxy) {
        guard let targetID = pendingCommentID else { return }
        guard viewModel.visibleComments.contains(where: { $0.id == targetID }) else { return }

        DispatchQueue.main.async {
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

    var body: some View {
        ForEach(viewModel.visibleComments, id: \.id) { comment in
            CommentRow(
                comment: comment,
                post: post,
                votingViewModel: votingViewModel,
                onToggle: { toggleCommentVisibility(comment) },
                onHide: { viewModel.hideCommentBranch(comment) },
            )
            .id("comment-\(comment.id)")
            .background(GeometryReader { geometry in
                Color.clear.preference(
                    key: CommentPositionKey.self,
                    value: CommentPosition(id: comment.id, frame: geometry.frame(in: .global)),
                )
            })
            .onPreferenceChange(CommentPositionKey.self) { position in
                if let position {
                    visibleCommentPositions[position.id] = position.frame
                }
            }
            .listRowSeparator(.hidden)
            .if(comment.voteLinks?.upvote != nil && !comment.upvoted) { view in
                view.swipeActions(edge: .leading, allowsFullSwipe: true) {
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
            .swipeActions(edge: .trailing) {
                Button { viewModel.hideCommentBranch(comment) } label: {
                    Image(systemName: "minus.circle")
                }
            }
        }
    }
}

struct PostHeader: View {
    let post: Post
    let votingViewModel: VotingViewModel
    let onLinkTap: () -> Void
    let onPostUpdate: @Sendable (Post) -> Void

    var body: some View {
        PostDisplayView(
            post: post,
            votingState: votingViewModel.votingState(for: post),
            showPostText: true,
            onThumbnailTap: { onLinkTap() },
        )
        .contentShape(Rectangle())
        .onTapGesture { onLinkTap() }
        .contextMenu {
            VotingContextMenuItems.postVotingMenuItems(
                for: post,
                onVote: {
                    Task {
                        var mutablePost = post
                        await votingViewModel.upvote(post: &mutablePost)
                        await MainActor.run { onPostUpdate(mutablePost) }
                    }
                },
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
}

struct CommentRow: View {
    @ObservedObject var comment: Comment
    let post: Post
    let votingViewModel: VotingViewModel
    let onToggle: () -> Void
    let onHide: () -> Void

    private var styledCommentText: AttributedString {
        var attributed = CommentHTMLParser.parseHTMLText(comment.text)
        let linkColor = AppColors.appTintColor

        for run in attributed.runs {
            if run.link != nil {
                attributed[run.range].foregroundColor = linkColor
            }
        }

        return attributed
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Divider().padding(.bottom, 6)
            HStack {
                Text(comment.by)
                    .scaledFont(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(comment.by == post.by ? AppColors.appTintColor : .primary)
                Text(comment.age)
                    .scaledFont(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
                VoteIndicator(
                    votingState: VotingState(
                        isUpvoted: comment.upvoted,
                        score: nil,
                        canVote: comment.voteLinks?.upvote != nil,
                        isVoting: votingViewModel.isVoting,
                        error: votingViewModel.lastError,
                    ),
                    style: VoteIndicatorStyle(showScore: false, iconFont: .body, iconScale: 1.0),
                )
                if comment.visibility == .compact {
                    Image(systemName: "chevron.down")
                        .scaledFont(.caption)
                        .foregroundColor(.secondary)
                        .accessibilityHidden(true)
                }
            }
            if comment.visibility == .visible {
                Text(styledCommentText)
                    .scaledFont(.callout)
                    .foregroundColor(.primary)
            }
        }
        .listRowInsets(.init(top: 12, leading: CGFloat((comment.level + 1) * 16), bottom: 8, trailing: 16))
        .contentShape(Rectangle())
        .onTapGesture { onToggle() }
        .accessibilityAddTraits(.isButton)
        .accessibilityHint(comment.visibility == .visible ? "Double-tap to collapse" : "Double-tap to expand")
        .contextMenu {
            VotingContextMenuItems.commentVotingMenuItems(
                for: comment,
                onVote: {
                    Task { await votingViewModel.upvote(comment: comment, in: post) }
                },
            )
            Button { UIPasteboard.general.string = comment.text.strippingHTML() } label: {
                Label("Copy", systemImage: "doc.on.doc")
            }
            Divider()
            Button { ContentSharePresenter.shared.shareComment(comment) } label: {
                Label("Share", systemImage: "square.and.arrow.up")
            }
        }
        .id(String(comment.id) + String(comment.visibility.rawValue))
    }
}

struct ToolbarTitle: View {
    let post: Post
    let showTitle: Bool
    let onTap: () -> Void

    var body: some View {
        HStack {
            ThumbnailView(url: post.url)
                .frame(width: 33, height: 33)
                .clipShape(RoundedRectangle(cornerRadius: 6))
            Text(post.title)
                .scaledFont(.headline)
                .lineLimit(1)
                .truncationMode(.tail)
        }
        .onTapGesture { onTap() }
        .accessibilityAddTraits(.isButton)
        .accessibilityHint("Open link")
        .opacity(showTitle ? 1.0 : 0.0)
        .offset(y: showTitle ? 0 : 20)
        .animation(.easeInOut(duration: 0.3), value: showTitle)
    }
}

struct ShareMenu: View {
    let post: Post

    var body: some View {
        Menu {
            if post.url.host != nil {
                Button("Article Link") { ContentSharePresenter.shared.shareURL(post.url, title: post.title) }
                Button("Hacker News Link") { ContentSharePresenter.shared.shareURL(post.hackerNewsURL, title: post.title) }
            } else {
                Button("Hacker News Link") { ContentSharePresenter.shared.shareURL(post.hackerNewsURL, title: post.title) }
            }
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

struct CommentPosition: Equatable {
    let id: Int
    let frame: CGRect
}

struct CommentPositionKey: PreferenceKey {
    typealias Value = CommentPosition?
    static let defaultValue: CommentPosition? = nil
    static func reduce(value: inout Value, nextValue: () -> Value) { value = value ?? nextValue() }
}

// MARK: - Helpers

extension View {
    func plainListRow() -> some View {
        listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets())
    }
}
