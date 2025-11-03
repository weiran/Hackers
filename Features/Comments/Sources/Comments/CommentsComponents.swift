//
//  CommentsComponents.swift
//  Comments
//
//  Extracted subviews and helpers from CommentsView to reduce file length
//

import DesignSystem
import Domain
import Foundation
import Shared
import SwiftUI
import UIKit

struct CommentsContentView: View {
    @State var viewModel: CommentsViewModel
    @State var votingViewModel: VotingViewModel
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
                    PostHeader(
                        post: post,
                        votingViewModel: votingViewModel,
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
                    .if((post.voteLinks?.upvote != nil && !post.upvoted) || (post.voteLinks?.unvote != nil && post.upvoted)) { view in
                        view.swipeActions(edge: .leading, allowsFullSwipe: true) {
                            if post.upvoted && post.voteLinks?.unvote != nil {
                                Button {
                                    Task {
                                        var mutablePost = post
                                        await votingViewModel.unvote(post: &mutablePost)
                                        await MainActor.run {
                                            if !mutablePost.upvoted {
                                                if let existingLinks = mutablePost.voteLinks {
                                                    mutablePost.voteLinks = VoteLinks(upvote: existingLinks.upvote, unvote: nil)
                                                }
                                                viewModel.post = mutablePost
                                            }
                                        }
                                    }
                                } label: {
                                    Image(systemName: "arrow.uturn.down")
                                }
                                .tint(.orange)
                                .accessibilityLabel("Unvote")
                            } else {
                                Button {
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
                            }
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
                            hideCommentBranch: { comment in
                                hideCommentBranch(comment) { id in
                                    proxy.scrollTo(id, anchor: .top)
                                }
                            },
                        )
                    }
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
            .listRowSeparator(.hidden)
            .if((comment.voteLinks?.upvote != nil && !comment.upvoted) || (comment.voteLinks?.unvote != nil && comment.upvoted)) { view in
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
}

struct PostHeader: View {
    let post: Post
    let votingViewModel: VotingViewModel
    let showThumbnails: Bool
    let onLinkTap: () -> Void
    let onPostUpdated: @Sendable (Post) -> Void
    let onBookmarkToggle: @Sendable () async -> Bool

    var body: some View {
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
        .onTapGesture { onLinkTap() }
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
        guard votingViewModel.canUnvote(item: post), post.upvoted else { return true }

        var mutablePost = post
        await votingViewModel.unvote(post: &mutablePost)
        let wasUnvoted = !mutablePost.upvoted

        if wasUnvoted {
            if let existingLinks = mutablePost.voteLinks {
                mutablePost.voteLinks = VoteLinks(upvote: existingLinks.upvote, unvote: nil)
            }
            await MainActor.run {
                onPostUpdated(mutablePost)
            }
        }

        return wasUnvoted
    }
}

struct CommentRow: View {
    @ObservedObject var comment: Comment
    let post: Post
    let votingViewModel: VotingViewModel
    let onToggle: () -> Void
    let onHide: () -> Void
    @Environment(\.textScaling) private var textScaling

    private var baseCommentText: AttributedString {
        if let cached = comment.parsedText {
            return cached
        }

        let parsed = CommentHTMLParser.parseHTMLText(comment.text)
        comment.parsedText = parsed
        return parsed
    }

    private func styledText(for textScaling: CGFloat) -> AttributedString {
        StyledCommentTextCache.text(
            commentID: comment.id,
            textScaling: textScaling,
            baseText: baseCommentText
        )
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
                if comment.upvoted {
                    VoteIndicator(
                        votingState: VotingState(
                            isUpvoted: comment.upvoted,
                            score: nil,
                            canVote: comment.voteLinks?.upvote != nil,
                            canUnvote: comment.voteLinks?.unvote != nil,
                            isVoting: votingViewModel.isVoting,
                            error: votingViewModel.lastError,
                        ),
                        style: VoteIndicatorStyle(showScore: false, iconFont: .body, iconScale: 1.0),
                    )
                }
                if comment.visibility == .compact {
                    Image(systemName: "chevron.down")
                        .scaledFont(.caption)
                        .foregroundColor(.secondary)
                        .accessibilityHidden(true)
                }
            }
            if comment.visibility == .visible {
                Text(styledText(for: textScaling))
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
                onUnvote: {
                    Task { await votingViewModel.unvote(comment: comment, in: post) }
                }
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

/// Precomputes fonts for each inline presentation style so comment text scaling stays consistent.
@MainActor
private struct CommentFontProvider {
    private static var cache: [CGFloat: CommentFontProvider] = [:]

    private let base: Font
    private let bold: Font
    private let italic: Font
    private let boldItalic: Font
    private let code: Font
    private let codeBold: Font
    private let codeItalic: Font
    private let codeBoldItalic: Font

    static func cached(textScaling: CGFloat) -> CommentFontProvider {
        if let cached = cache[textScaling] {
            return cached
        }
        let provider = CommentFontProvider(textScaling: textScaling)
        cache[textScaling] = provider
        return provider
    }

    private init(textScaling: CGFloat) {
        let basePointSize = UIFont.preferredFont(forTextStyle: .callout).pointSize * textScaling
        let codePointSize = UIFont.preferredFont(forTextStyle: .subheadline).pointSize * textScaling

        base = Self.makeFont(size: basePointSize, weight: .regular, italic: false, monospaced: false)
        bold = Self.makeFont(size: basePointSize, weight: .semibold, italic: false, monospaced: false)
        italic = Self.makeFont(size: basePointSize, weight: .regular, italic: true, monospaced: false)
        boldItalic = Self.makeFont(size: basePointSize, weight: .semibold, italic: true, monospaced: false)

        code = Self.makeFont(size: codePointSize, weight: .regular, italic: false, monospaced: true)
        codeBold = Self.makeFont(size: codePointSize, weight: .semibold, italic: false, monospaced: true)
        codeItalic = Self.makeFont(size: codePointSize, weight: .regular, italic: true, monospaced: true)
        codeBoldItalic = Self.makeFont(size: codePointSize, weight: .semibold, italic: true, monospaced: true)
    }

    func font(isCode: Bool, isBold: Bool, isItalic: Bool) -> Font {
        switch (isCode, isBold, isItalic) {
        case (true, true, true):
            return codeBoldItalic
        case (true, true, false):
            return codeBold
        case (true, false, true):
            return codeItalic
        case (true, false, false):
            return code
        case (false, true, true):
            return boldItalic
        case (false, true, false):
            return bold
        case (false, false, true):
            return italic
        default:
            return base
        }
    }

    private static func makeFont(
        size: CGFloat,
        weight: UIFont.Weight,
        italic: Bool,
        monospaced: Bool
    ) -> Font {
        var font: UIFont
        if monospaced {
            font = UIFont.monospacedSystemFont(ofSize: size, weight: weight)
        } else {
            font = UIFont.systemFont(ofSize: size, weight: weight)
        }

        if italic {
            if let italicDescriptor = font.fontDescriptor.withSymbolicTraits(.traitItalic) {
                font = UIFont(descriptor: italicDescriptor, size: size)
            } else {
                font = UIFont.italicSystemFont(ofSize: size)
            }
        }

        return Font(font)
    }
}

@MainActor
private enum StyledCommentTextCache {
    private struct CacheKey: Hashable {
        let commentID: Int
        let scale: CGFloat
    }

    private struct Entry {
        let base: AttributedString
        let styled: AttributedString
    }

    private static var cache: [CacheKey: Entry] = [:]

    static func text(commentID: Int, textScaling: CGFloat, baseText: AttributedString) -> AttributedString {
        let key = CacheKey(commentID: commentID, scale: textScaling)
        if let cached = cache[key], cached.base == baseText {
            return cached.styled
        }

        var attributed = baseText
        let fontProvider = CommentFontProvider.cached(textScaling: textScaling)
        let linkColor = AppColors.appTintColor

        for run in attributed.runs {
            let range = run.range
            let intents = run.inlinePresentationIntent ?? []
            attributed[range].font = fontProvider.font(
                isCode: intents.contains(.code),
                isBold: intents.contains(.stronglyEmphasized),
                isItalic: intents.contains(.emphasized)
            )
        }

        for run in attributed.runs where run.link != nil {
            attributed[run.range].foregroundColor = linkColor
        }

        cache[key] = Entry(base: baseText, styled: attributed)
        return attributed
    }
}

struct ToolbarTitle: View {
    let post: Post
    let showTitle: Bool
    let showThumbnails: Bool
    let onTap: () -> Void

    var body: some View {
        HStack {
            ThumbnailView(url: post.url, isEnabled: showThumbnails)
                .frame(width: 33, height: 33)
                .clipShape(RoundedRectangle(cornerRadius: 10))
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
