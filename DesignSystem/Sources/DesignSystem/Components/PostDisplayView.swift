//
//  PostDisplayView.swift
//  DesignSystem
//
//  Copyright © 2025 Weiran Zhang. All rights reserved.
//

import Domain
import Shared
import SwiftUI

public struct PostDisplayView: View {
    let post: Post
    let votingState: VotingState?
    let showPostText: Bool
    let showThumbnails: Bool
    let onThumbnailTap: (() -> Void)?
    let onUpvoteTap: (() async -> Bool)?
    let onBookmarkTap: (() async -> Bool)?
    let onCommentsTap: (() -> Void)?

    @State private var isSubmittingUpvote = false
    @State private var isSubmittingBookmark = false
    @State private var displayedScore: Int
    @State private var displayedUpvoted: Bool
    @State private var displayedBookmarked: Bool

    public init(
        post: Post,
        votingState: VotingState? = nil,
        showPostText: Bool = false,
        showThumbnails: Bool = true,
        onThumbnailTap: (() -> Void)? = nil,
        onUpvoteTap: (() async -> Bool)? = nil,
        onBookmarkTap: (() async -> Bool)? = nil,
        onCommentsTap: (() -> Void)? = nil
    ) {
        self.post = post
        self.votingState = votingState
        self.showPostText = showPostText
        self.showThumbnails = showThumbnails
        self.onThumbnailTap = onThumbnailTap
        self.onUpvoteTap = onUpvoteTap
        self.onBookmarkTap = onBookmarkTap
        self.onCommentsTap = onCommentsTap
        _displayedScore = State(initialValue: post.score)
        _displayedUpvoted = State(initialValue: post.upvoted)
        _displayedBookmarked = State(initialValue: post.isBookmarked)
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 12) {
                // Thumbnail with proper loading
                ThumbnailView(url: post.url, isEnabled: showThumbnails)
                    .frame(width: 55, height: 55)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .contentShape(Rectangle())
                    .onTapGesture {
                        onThumbnailTap?()
                    }
                    .accessibilityAddTraits(.isButton)
                    .accessibilityLabel("Open link")

                VStack(alignment: .leading, spacing: 6) {
                    if let host = post.url.host,
                       !isHackerNewsItemURL(post.url)
                    {
                        Text(truncatedHost(host))
                            .scaledFont(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }

                    // Title
                    Text(post.title)
                        .scaledFont(.headline)
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    // Metadata row
                    HStack(spacing: 8) {
                        upvotePill
                        commentsPill
                        Spacer(minLength: 8)
                        if onBookmarkTap != nil {
                            bookmarkPill
                        }
                    }
                    .scaledFont(.caption)
                    .padding(.top, 4)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .onChange(of: post.id) { _ in
            displayedScore = post.score
            displayedUpvoted = post.upvoted
            displayedBookmarked = post.isBookmarked
        }
        .onChange(of: post.score) { newValue in
            displayedScore = newValue
        }
        .onChange(of: post.upvoted) { newValue in
            displayedUpvoted = newValue
        }
        .onChange(of: post.isBookmarked) { newValue in
            displayedBookmarked = newValue
        }
        .onChange(of: votingState?.score) { newValue in
            if let newValue {
                displayedScore = newValue
            }
        }
        .onChange(of: votingState?.isUpvoted) { newValue in
            if let newValue {
                displayedUpvoted = newValue
            }
        }
    }

    private var upvotePill: some View {
        let score = displayedScore
        let isUpvoted = displayedUpvoted
        let isLoading = isSubmittingUpvote
        let canVote = post.voteLinks?.upvote != nil
        let canInteract = canVote && !isUpvoted && !isLoading
        // Avoid keeping a disabled Button so the upvoted state retains the bright tint
        let (backgroundColor, textColor): (Color, Color) = {
            if isUpvoted {
                return (AppColors.upvotedColor.opacity(0.1), AppColors.upvotedColor)
            } else {
                return (Color.secondary.opacity(0.1), .secondary)
            }
        }()
        let iconName = isUpvoted ? "arrow.up.circle.fill" : "arrow.up"
        let accessibilityLabel: String
        if isLoading {
            accessibilityLabel = "Submitting vote"
        } else if isUpvoted {
            accessibilityLabel = "\(score) points, upvoted"
        } else {
            accessibilityLabel = "\(score) points"
        }

        return pillView(
            iconName: iconName,
            text: "\(score)",
            textColor: textColor,
            backgroundColor: backgroundColor,
            accessibilityLabel: accessibilityLabel,
            accessibilityHint: "Double tap to upvote",
            isHighlighted: isUpvoted,
            isLoading: isLoading,
            isEnabled: canInteract,
            numericValue: score,
            action: canInteract ? makeUpvoteAction() : nil
        )
    }

    private var commentsPill: some View {
        let commentTextColor: Color = .secondary
        let commentBackgroundColor = Color.secondary.opacity(0.1)
        // Brighter styling keeps the comments count from reading as a disabled control
        return pillView(
            iconName: "message",
            text: "\(post.commentsCount)",
            textColor: commentTextColor,
            backgroundColor: commentBackgroundColor,
            accessibilityLabel: "\(post.commentsCount) comments",
            isHighlighted: false,
            isLoading: false,
            numericValue: post.commentsCount,
            action: onCommentsTap
        )
    }

    private var bookmarkPill: some View {
        let isBookmarked = displayedBookmarked
        let backgroundColor: Color = {
            if isBookmarked {
                return AppColors.appTintColor.opacity(0.12)
            }
            return Color.secondary.opacity(0.06)
        }()
        let textColor: Color = isBookmarked ? AppColors.appTintColor : .secondary
        let iconName = isBookmarked ? "bookmark.fill" : "bookmark"
        let accessibilityLabel = isBookmarked ? "Remove bookmark" : "Save for later"
        let accessibilityHint = isBookmarked
            ? "Double tap to remove from bookmarks"
            : "Double tap to add to bookmarks"

        return pillView(
            iconName: iconName,
            text: isBookmarked ? "Saved" : "Save",
            textColor: textColor,
            backgroundColor: backgroundColor,
            accessibilityLabel: accessibilityLabel,
            accessibilityHint: accessibilityHint,
            isHighlighted: isBookmarked,
            isLoading: isSubmittingBookmark,
            isEnabled: !isSubmittingBookmark,
            action: makeBookmarkAction()
        )
    }

    private func makeUpvoteAction() -> (() -> Void)? {
        guard let onUpvoteTap else { return nil }
        return {
            guard !isSubmittingUpvote else { return }
            isSubmittingUpvote = true
            let previousScore = displayedScore
            let previousUpvoted = displayedUpvoted
            displayedUpvoted = true
            displayedScore += 1
            Task {
                let success = await onUpvoteTap()
                await MainActor.run {
                    if !success {
                        displayedScore = previousScore
                        displayedUpvoted = previousUpvoted
                    }
                    isSubmittingUpvote = false
                }
            }
        }
    }

    private func makeBookmarkAction() -> (() -> Void)? {
        guard let onBookmarkTap else { return nil }
        return {
            guard !isSubmittingBookmark else { return }
            isSubmittingBookmark = true
            let previousState = displayedBookmarked
            let optimisticState = !previousState
            displayedBookmarked = optimisticState

            Task {
                let result = await onBookmarkTap()
                await MainActor.run {
                    if result != optimisticState {
                        displayedBookmarked = result
                    }
                    isSubmittingBookmark = false
                }
            }
        }
    }

    @ViewBuilder
    private func pillView(
        iconName: String?,
        text: String,
        textColor: Color,
        backgroundColor: Color,
        accessibilityLabel: String,
        accessibilityHint: String? = nil,
        isHighlighted _: Bool,
        isLoading: Bool,
        isEnabled: Bool = true,
        numericValue: Int? = nil,
        action: (() -> Void)? = nil
    ) -> some View {
        let iconDimension: CGFloat = 12
        let content = HStack(spacing: 4) {
            if let iconName {
                Image(systemName: iconName)
                    .scaledFont(.caption2)
                    .foregroundColor(textColor)
                    .frame(width: iconDimension, height: iconDimension)
            }
            if let value = numericValue {
                Text(text)
                    .scaledFont(.caption)
                    .foregroundColor(textColor)
                    .contentTransition(.numericText())
                    .animation(.easeInOut(duration: 0.2), value: value)
            } else {
                Text(text)
                    .scaledFont(.caption)
                    .foregroundColor(textColor)
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        .background(
            Capsule()
                .fill(backgroundColor)
        )
        Button(action: action ?? {}) {
            content
                .glassEffect()
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(accessibilityHint ?? "")

    }
}

public struct PostContextMenu: View {
    let post: Post
    let onVote: () -> Void
    let onOpenLink: () -> Void
    let onShare: () -> Void

    public init(
        post: Post,
        onVote: @escaping () -> Void,
        onOpenLink: @escaping () -> Void,
        onShare: @escaping () -> Void,
    ) {
        self.post = post
        self.onVote = onVote
        self.onOpenLink = onOpenLink
        self.onShare = onShare
    }

    public var body: some View {
        Group {
            if post.voteLinks?.upvote != nil {
                Button {
                    onVote()
                } label: {
                    Label("Upvote", systemImage: "arrow.up")
                }
            }

            Divider()

            if !isHackerNewsItemURL(post.url) {
                Button {
                    onOpenLink()
                } label: {
                    Label("Open Link", systemImage: "safari")
                }
            }

            Button {
                onShare()
            } label: {
                Label("Share", systemImage: "square.and.arrow.up")
            }
        }
    }
}

private func truncatedHost(_ host: String) -> String {
    guard host.hasPrefix("www.") else { return host }
    return String(host.dropFirst(4))
}

private func isHackerNewsItemURL(_ url: URL) -> Bool {
    guard let hnHost = url.host else { return false }
    return hnHost == Shared.HackerNewsConstants.host && url.path == "/item"
}
