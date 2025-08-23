//
//  CommentsView.swift
//  Comments
//
//  Copyright © 2025 Weiran Zhang. All rights reserved.
//

import SwiftUI
import Domain
import Shared
import DesignSystem

public struct CommentsView<NavigationStore: NavigationStoreProtocol>: View {
    @State private var viewModel: CommentsViewModel
    @State private var showingVoteError = false
    @State private var voteErrorMessage = ""
    @State private var showingAuthenticationDialog = false
    @State private var showTitle = false
    @State private var hasMeasuredInitialOffset = false
    @State private var visibleCommentPositions: [Int: CGRect] = [:]
    @State private var navigateToPostId: Int?
    @EnvironmentObject private var navigationStore: NavigationStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    public init(post: Post, viewModel: CommentsViewModel? = nil) {
        self._viewModel = State(initialValue: viewModel ?? CommentsViewModel(post: post))
    }

    public var body: some View {
        CommentsContentView(
            viewModel: viewModel,
            showTitle: $showTitle,
            hasMeasuredInitialOffset: $hasMeasuredInitialOffset,
            visibleCommentPositions: $visibleCommentPositions,
            navigateToPostId: $navigateToPostId,
            handlePostVote: handlePostVote,
            handleCommentVote: handleCommentVote,
            handleLinkTap: handleLinkTap,
            toggleCommentVisibility: toggleCommentVisibility
        )
        .navigationTitle("Comments")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                ToolbarTitle(
                    post: viewModel.post,
                    showTitle: showTitle,
                    onTap: handleLinkTap
                )
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                ShareMenu(post: viewModel.post)
            }
        }
        .task {
            await viewModel.loadComments()
        }
        .refreshable {
            await viewModel.refreshComments()
        }
        .alert("Vote Error", isPresented: $showingVoteError) {
            Button("OK") { }
        } message: {
            Text(voteErrorMessage)
        }
        .alert("Authentication Required", isPresented: $showingAuthenticationDialog) {
            Button("Cancel") { }
            Button("Login") {
                // TODO: Implement login flow
            }
        } message: {
            Text("Please log in to vote on posts and comments.")
        }
    }

    @MainActor
    private func handlePostVote() async {
        let isUpvote = !viewModel.post.upvoted

        do {
            try await viewModel.voteOnPost(upvote: isUpvote)
        } catch {
            handleVoteError(error)
        }
    }

    @MainActor
    private func handleCommentVote(_ comment: Comment) async {
        let isUpvote = !comment.upvoted

        do {
            try await viewModel.voteOnComment(comment, upvote: isUpvote)
        } catch {
            handleVoteError(error)
        }
    }

    private func handleVoteError(_ error: Error) {
        if let hackersError = error as? HackersKitError {
            switch hackersError {
            case .unauthenticated:
                showingAuthenticationDialog = true
            default:
                voteErrorMessage = "Failed to vote. Please try again."
                showingVoteError = true
            }
        } else {
            voteErrorMessage = "Failed to vote. Please try again."
            showingVoteError = true
        }
    }

    private func handleLinkTap() {
        LinkOpener.openURL(viewModel.post.url, with: viewModel.post)
    }

    private func toggleCommentVisibility(_ comment: Comment, scrollTo: @escaping (String) -> Void) {
        withAnimation(.easeInOut(duration: 0.3)) {
            let wasVisible = comment.visibility == .visible
            viewModel.toggleCommentVisibility(comment)

            if wasVisible && !isCommentVisibleOnScreen(comment) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    scrollTo("comment-\(comment.id)")
                }
            }
        }
    }

    private func isCommentVisibleOnScreen(_ comment: Comment) -> Bool {
        guard let commentFrame = visibleCommentPositions[comment.id] else {
            return false
        }

        guard let window = PresentationService.shared.windowScene?.windows.first else {
            return false
        }

        let screenBounds = window.bounds
        return screenBounds.contains(CGPoint(x: commentFrame.midX, y: commentFrame.minY))
    }
}

private struct CommentsContentView: View {
    @State var viewModel: CommentsViewModel
    @Binding var showTitle: Bool
    @Binding var hasMeasuredInitialOffset: Bool
    @Binding var visibleCommentPositions: [Int: CGRect]
    @Binding var navigateToPostId: Int?
    let handlePostVote: () async -> Void
    let handleCommentVote: (Comment) async -> Void
    let handleLinkTap: () -> Void
    let toggleCommentVisibility: (Comment, @escaping (String) -> Void) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ScrollViewReader { proxy in
                List {
                    PostHeader(
                        post: viewModel.post,
                        onVote: { await handlePostVote() },
                        onLinkTap: { handleLinkTap() }
                    )
                    .id("header")
                    .background(GeometryReader { geometry in
                        Color.clear.preference(
                            key: ViewOffsetKey.self,
                            value: geometry.frame(in: .global).minY
                        )
                    })
                    .onPreferenceChange(ViewOffsetKey.self) { offset in
                        if !hasMeasuredInitialOffset {
                            hasMeasuredInitialOffset = true
                            showTitle = offset < 50
                        } else {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showTitle = offset < 50
                            }
                        }
                    }
                    .listRowSeparator(.hidden)
                    .swipeActions(edge: .leading, allowsFullSwipe: true) {
                        Button {
                            Task { await handlePostVote() }
                        } label: {
                            Image(systemName: viewModel.post.upvoted ? "arrow.uturn.down" : "arrow.up")
                        }
                        .tint(viewModel.post.upvoted ? .secondary : Color("upvotedColor"))
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
                            visibleCommentPositions: $visibleCommentPositions,
                            handleCommentVote: handleCommentVote,
                            toggleCommentVisibility: { comment in
                                toggleCommentVisibility(comment) { id in
                                    proxy.scrollTo(id, anchor: .top)
                                }
                            }
                        )
                    }
                }
                .listStyle(.plain)
            }
        }
    }
}

private struct CommentsForEach: View {
    @State var viewModel: CommentsViewModel
    @Binding var visibleCommentPositions: [Int: CGRect]
    let handleCommentVote: (Comment) async -> Void
    let toggleCommentVisibility: (Comment) -> Void

    var body: some View {
        ForEach(viewModel.visibleComments, id: \.id) { comment in
            CommentRow(
                comment: comment,
                post: viewModel.post,
                onToggle: { toggleCommentVisibility(comment) },
                onVote: { await handleCommentVote(comment) },
                onHide: { viewModel.hideCommentBranch(comment) }
            )
            .id("comment-\(comment.id)")
            .background(GeometryReader { geometry in
                Color.clear.preference(
                    key: CommentPositionKey.self,
                    value: CommentPosition(id: comment.id, frame: geometry.frame(in: .global))
                )
            })
            .onPreferenceChange(CommentPositionKey.self) { position in
                if let position = position {
                    visibleCommentPositions[position.id] = position.frame
                }
            }
            .listRowSeparator(.hidden)
            .swipeActions(edge: .leading, allowsFullSwipe: true) {
                Button {
                    Task { await handleCommentVote(comment) }
                } label: {
                    Image(systemName: comment.upvoted ? "arrow.uturn.down" : "arrow.up")
                }
                .tint(comment.upvoted ? .secondary : Color("upvotedColor"))
            }
            .swipeActions(edge: .trailing) {
                Button {
                    viewModel.hideCommentBranch(comment)
                } label: {
                    Image(systemName: "minus.circle")
                }
            }
        }
    }
}

private struct PostHeader: View {
    let post: Post
    let onVote: () async -> Void
    let onLinkTap: () -> Void

    var body: some View {
        PostDisplayView(
            post: post,
            showPostText: true,
            onThumbnailTap: { onLinkTap() }
        )
        .contentShape(Rectangle())
        .onTapGesture {
            onLinkTap()
        }
        .contextMenu {
            PostContextMenu(
                post: post,
                onVote: { Task { await onVote() } },
                onOpenLink: onLinkTap,
                onShare: { ShareService.shared.shareURL(post.url, title: post.title) }
            )
        }
    }
}

private struct CommentRow: View {
    @ObservedObject var comment: Comment
    let post: Post
    let onToggle: () -> Void
    let onVote: () async -> Void
    let onHide: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Divider()
                .padding(.bottom, 6)

            HStack {
                Text(comment.by)
                    .scaledFont(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(comment.by == post.by ? Color(UIColor(named: "appTintColor")!) : .primary)

                Text(comment.age)
                    .scaledFont(.subheadline)
                    .foregroundColor(.secondary)

                Spacer()

                if comment.upvoted {
                    Image(systemName: "arrow.up.circle.fill")
                        .foregroundColor(Color("upvotedColor"))
                        .scaledFont(.body)
                }

                if comment.visibility == .compact {
                    Image(systemName: "chevron.down")
                        .scaledFont(.caption)
                        .foregroundColor(.secondary)
                }
            }

            if comment.visibility == .visible {
                if let parsedText = comment.parsedText {
                    Text(parsedText)
                        .foregroundColor(.primary)
                }
            }
        }
        .listRowInsets(.init(top: 10, leading: CGFloat((comment.level + 1) * 16), bottom: 10, trailing: 16))
        .contentShape(Rectangle())
        .onTapGesture {
            onToggle()
        }
        .contextMenu {
            CommentContextMenu(
                comment: comment,
                onVote: { Task { await onVote() } },
                onShare: { ShareService.shared.shareComment(comment) },
                onCopy: { UIPasteboard.general.string = comment.text.strippingHTML() }
            )
        }
        .id(String(comment.id) + String(comment.visibility.rawValue))
    }
}

private struct ToolbarTitle: View {
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
        .onTapGesture {
            onTap()
        }
        .opacity(showTitle ? 1.0 : 0.0)
        .offset(y: showTitle ? 0 : 20)
        .animation(.easeInOut(duration: 0.3), value: showTitle)
    }
}

private struct ShareMenu: View {
    let post: Post

    var body: some View {
        Menu {
            if post.url.host != nil {
                Button("Article Link") {
                    ShareService.shared.shareURL(post.url, title: post.title)
                }
                Button("Hacker News Link") {
                    ShareService.shared.shareURL(post.hackerNewsURL, title: post.title)
                }
            } else {
                Button("Hacker News Link") {
                    ShareService.shared.shareURL(post.hackerNewsURL, title: post.title)
                }
            }
        } label: {
            Image(systemName: "square.and.arrow.up")
        }
    }
}

private struct LoadingView: View {
    var body: some View {
        VStack {
            Spacer()
            ProgressView()
            Text("Loading comments...")
                .scaledFont(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}

private struct EmptyCommentsView: View {
    var body: some View {
        Text("No comments yet")
            .scaledFont(.subheadline)
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity)
    }
}

private struct CommentContextMenu: View {
    @ObservedObject var comment: Comment
    let onVote: () -> Void
    let onShare: () -> Void
    let onCopy: () -> Void

    var body: some View {
        Group {
            Button {
                onVote()
            } label: {
                Label(comment.upvoted ? "Unvote" : "Upvote",
                      systemImage: comment.upvoted ? "arrow.uturn.down" : "arrow.up")
            }

            Button {
                onCopy()
            } label: {
                Label("Copy", systemImage: "doc.on.doc")
            }

            Divider()

            Button {
                onShare()
            } label: {
                Label("Share", systemImage: "square.and.arrow.up")
            }
        }
    }
}

struct ViewOffsetKey: PreferenceKey {
    typealias Value = CGFloat
    static let defaultValue = CGFloat.zero
    static func reduce(value: inout Value, nextValue: () -> Value) {
        value += nextValue()
    }
}

struct CommentPosition: Equatable {
    let id: Int
    let frame: CGRect
}

struct CommentPositionKey: PreferenceKey {
    typealias Value = CommentPosition?
    static let defaultValue: CommentPosition? = nil
    static func reduce(value: inout CommentPosition?, nextValue: () -> CommentPosition?) {
        value = nextValue() ?? value
    }
}

struct PlainListRowStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
    }
}

extension View {
    func plainListRow() -> some View {
        modifier(PlainListRowStyle())
    }
}
