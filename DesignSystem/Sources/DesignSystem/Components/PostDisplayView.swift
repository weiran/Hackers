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
    let onUnvoteTap: (() async -> Bool)?
    let onBookmarkTap: (() async -> Bool)?
    let onCommentsTap: (() -> Void)?

    @Environment(\.colorScheme) private var colorScheme
    @State private var isSubmittingUpvote = false
    @State private var isSubmittingBookmark = false
    @State private var displayedScore: Int
    @State private var displayedUpvoted: Bool
    @State private var displayedBookmarked: Bool
    @State private var displayedVoteLinks: VoteLinks?

    public init(
        post: Post,
        votingState: VotingState? = nil,
        showPostText: Bool = false,
        showThumbnails: Bool = true,
        onThumbnailTap: (() -> Void)? = nil,
        onUpvoteTap: (() async -> Bool)? = nil,
        onUnvoteTap: (() async -> Bool)? = nil,
        onBookmarkTap: (() async -> Bool)? = nil,
        onCommentsTap: (() -> Void)? = nil
    ) {
        self.post = post
        self.votingState = votingState
        self.showPostText = showPostText
        self.showThumbnails = showThumbnails
        self.onThumbnailTap = onThumbnailTap
        self.onUpvoteTap = onUpvoteTap
        self.onUnvoteTap = onUnvoteTap
        self.onBookmarkTap = onBookmarkTap
        self.onCommentsTap = onCommentsTap
        _displayedScore = State(initialValue: post.score)
        _displayedUpvoted = State(initialValue: post.upvoted)
        _displayedBookmarked = State(initialValue: post.isBookmarked)
        _displayedVoteLinks = State(initialValue: post.voteLinks)
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center, spacing: 12) {
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
                        Text(truncatedHost(host).uppercased())
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
            displayedVoteLinks = post.voteLinks
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
        .onChange(of: post.voteLinks) { newValue in
            displayedVoteLinks = newValue
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
        let currentVoteLinks = displayedVoteLinks ?? post.voteLinks
        let canVote = currentVoteLinks?.upvote != nil
        let canUnvote = currentVoteLinks?.unvote != nil
        let canInteract = ((canVote && !isUpvoted) || (canUnvote && isUpvoted)) && !isLoading
        // Avoid keeping a disabled Button so the upvoted state retains the bright tint
        let (backgroundColor, textColor): (Color, Color) = {
            let style = AppColors.PillStyle.upvote(isActive: isUpvoted)
            let background = AppColors.pillBackground(for: style, colorScheme: colorScheme)
            let foreground = AppColors.pillForeground(for: style, colorScheme: colorScheme)
            return (background, foreground)
        }()
        let iconName = isUpvoted ? "arrow.up.circle.fill" : "arrow.up"
        let accessibilityLabel: String
        let accessibilityHint: String
        if isLoading {
            accessibilityLabel = "Submitting vote"
            accessibilityHint = ""
        } else if isUpvoted && canUnvote {
            accessibilityLabel = "\(score) points, upvoted"
            accessibilityHint = "Double tap to unvote"
        } else if isUpvoted {
            accessibilityLabel = "\(score) points, upvoted"
            accessibilityHint = ""
        } else {
            accessibilityLabel = "\(score) points"
            accessibilityHint = "Double tap to upvote"
        }

        return pillView(
            iconName: iconName,
            text: "\(score)",
            textColor: textColor,
            backgroundColor: backgroundColor,
            accessibilityLabel: accessibilityLabel,
            accessibilityHint: accessibilityHint,
            isHighlighted: isUpvoted,
            isLoading: isLoading,
            isEnabled: canInteract,
            numericValue: score,
            action: canInteract ? makeUpvoteAction() : nil
        )
    }

    private var commentsPill: some View {
        let style = AppColors.PillStyle.comments
        let commentTextColor = AppColors.pillForeground(for: style, colorScheme: colorScheme)
        let commentBackgroundColor = AppColors.pillBackground(for: style, colorScheme: colorScheme)
        // Brighter styling keeps the comments count from reading as a disabled control
        return pillView(
            iconName: "message",
            text: "\(post.commentsCount)",
            textColor: commentTextColor,
            backgroundColor: commentBackgroundColor,
            accessibilityLabel: "\(post.commentsCount) comments",
            isHighlighted: false,
            isLoading: false,
            isEnabled: true,
            numericValue: post.commentsCount,
            action: onCommentsTap
        )
    }

    private var bookmarkPill: some View {
        let isBookmarked = displayedBookmarked
        let style = AppColors.PillStyle.bookmark(isSaved: isBookmarked)
        let backgroundColor = AppColors.pillBackground(for: style, colorScheme: colorScheme)
        let textColor = AppColors.pillForeground(for: style, colorScheme: colorScheme)
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
        return {
            guard !isSubmittingUpvote else { return }

            let isCurrentlyUpvoted = displayedUpvoted
            let currentVoteLinks = displayedVoteLinks ?? post.voteLinks
            let canUnvote = currentVoteLinks?.unvote != nil

            // If already upvoted and can unvote, perform unvote
            if isCurrentlyUpvoted && canUnvote {
                guard let onUnvoteTap else { return }
                isSubmittingUpvote = true
                let previousScore = displayedScore
                let previousUpvoted = displayedUpvoted
                let previousVoteLinks = currentVoteLinks
                displayedUpvoted = false
                displayedScore -= 1
                displayedVoteLinks = VoteLinks(upvote: previousVoteLinks?.upvote, unvote: nil)
                Task {
                    let success = await onUnvoteTap()
                    await MainActor.run {
                        if !success {
                            displayedScore = previousScore
                            displayedUpvoted = previousUpvoted
                            displayedVoteLinks = previousVoteLinks
                        }
                        isSubmittingUpvote = false
                    }
                }
            } else {
                // Perform upvote
                guard let onUpvoteTap else { return }
                isSubmittingUpvote = true
                let previousScore = displayedScore
                let previousUpvoted = displayedUpvoted
                let previousVoteLinks = currentVoteLinks
                displayedUpvoted = true
                displayedScore += 1
                displayedVoteLinks = derivedVoteLinks(afterUpvoteFrom: previousVoteLinks)
                Task {
                    let success = await onUpvoteTap()
                    await MainActor.run {
                        if !success {
                            displayedScore = previousScore
                            displayedUpvoted = previousUpvoted
                            displayedVoteLinks = previousVoteLinks
                        }
                        isSubmittingUpvote = false
                    }
                }
            }
        }
    }

    private func derivedVoteLinks(afterUpvoteFrom voteLinks: VoteLinks?) -> VoteLinks? {
        guard let voteLinks else { return nil }
        if voteLinks.unvote != nil {
            return voteLinks
        }
        guard let upvoteURL = voteLinks.upvote else {
            return voteLinks
        }
        let absolute = upvoteURL.absoluteString
        if absolute.contains("how=up"),
           let unvoteURL = URL(string: absolute.replacingOccurrences(of: "how=up", with: "how=un"))
        {
            return VoteLinks(upvote: upvoteURL, unvote: unvoteURL)
        }
        if absolute.contains("how%3Dup"),
           let unvoteURL = URL(string: absolute.replacingOccurrences(of: "how%3Dup", with: "how%3Dun"))
        {
            return VoteLinks(upvote: upvoteURL, unvote: unvoteURL)
        }
        return voteLinks
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
        .overlay {
            if isLoading {
                Capsule()
                    .fill(backgroundColor.opacity(0.6))
            }
        }
        .overlay {
            if isLoading {
                ProgressView()
                    .scaleEffect(0.6)
                    .tint(textColor)
            }
        }

        let shouldDisable = !isEnabled || isLoading
        let shouldBeInteractive = isEnabled && !isLoading && action != nil

        // If enabled but no action, render as static view to avoid disabled styling
        if isEnabled && !isLoading && action == nil {
            content
                .accessibilityElement(children: .combine)
                .accessibilityLabel(accessibilityLabel)
                .accessibilityHint(accessibilityHint ?? "")
        } else {
            Button(action: action ?? {}) {
                content
            }
            .buttonStyle(.plain)
            .disabled(!shouldBeInteractive)
            .allowsHitTesting(shouldBeInteractive)
            .opacity(shouldDisable ? 0.6 : 1.0)
            .accessibilityElement(children: .combine)
            .accessibilityLabel(accessibilityLabel)
            .accessibilityHint(accessibilityHint ?? "")
        }
    }
}

public struct PostContextMenu: View {
    let post: Post
    let onVote: () -> Void
    let onUnvote: () -> Void
    let onOpenLink: () -> Void
    let onShare: () -> Void

    public init(
        post: Post,
        onVote: @escaping () -> Void,
        onUnvote: @escaping () -> Void = {},
        onOpenLink: @escaping () -> Void,
        onShare: @escaping () -> Void,
    ) {
        self.post = post
        self.onVote = onVote
        self.onUnvote = onUnvote
        self.onOpenLink = onOpenLink
        self.onShare = onShare
    }

    public var body: some View {
        Group {
            if post.voteLinks?.upvote != nil, !post.upvoted {
                Button {
                    onVote()
                } label: {
                    Label("Upvote", systemImage: "arrow.up")
                }
            }

            if post.voteLinks?.unvote != nil, post.upvoted {
                Button {
                    onUnvote()
                } label: {
                    Label("Unvote", systemImage: "arrow.uturn.down")
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
