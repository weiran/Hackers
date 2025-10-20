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
    let onUpvoteTap: (() async -> Void)?

    @State private var isSubmittingUpvote = false

    public init(
        post: Post,
        votingState: VotingState? = nil,
        showPostText: Bool = false,
        showThumbnails: Bool = true,
        onThumbnailTap: (() -> Void)? = nil,
        onUpvoteTap: (() async -> Void)? = nil
    ) {
        self.post = post
        self.votingState = votingState
        self.showPostText = showPostText
        self.showThumbnails = showThumbnails
        self.onThumbnailTap = onThumbnailTap
        self.onUpvoteTap = onUpvoteTap
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
                    }
                    .scaledFont(.caption)
                    .padding(.top, 2)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var upvotePill: some View {
        let score = votingState?.score ?? post.score
        let isUpvoted = votingState?.isUpvoted ?? post.upvoted
        let isLoading = isSubmittingUpvote
        let canVote = post.voteLinks?.upvote != nil
        let textColor = isUpvoted ? AppColors.upvotedColor : Color.secondary
        let backgroundColor = Color.secondary.opacity(0.1)
        let iconName = isLoading ? nil : (isUpvoted ? "arrow.up.circle.fill" : "arrow.up")
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
            isHighlighted: isUpvoted,
            isLoading: isLoading,
            isEnabled: canVote && !isUpvoted && !isLoading,
            numericValue: score,
            action: makeUpvoteAction()
        )
    }

    private var commentsPill: some View {
        pillView(
            iconName: "message",
            text: "\(post.commentsCount)",
            textColor: .secondary,
            backgroundColor: Color.secondary.opacity(0.1),
            accessibilityLabel: "\(post.commentsCount) comments",
            isHighlighted: false,
            isLoading: false,
            numericValue: post.commentsCount
        )
    }

    private func makeUpvoteAction() -> (() -> Void)? {
        guard let onUpvoteTap else { return nil }
        return {
            guard !isSubmittingUpvote else { return }
            isSubmittingUpvote = true
            Task {
                await onUpvoteTap()
                await MainActor.run {
                    isSubmittingUpvote = false
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
        isHighlighted: Bool,
        isLoading: Bool,
        isEnabled: Bool = true,
        numericValue: Int? = nil,
        action: (() -> Void)? = nil
    ) -> some View {
        let iconDimension: CGFloat = 12
        let content = HStack(spacing: 4) {
            if isLoading {
                ProgressView()
                    .progressViewStyle(.circular)
                    .frame(width: iconDimension, height: iconDimension)
                    .tint(textColor)
            } else if let iconName {
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

        if let action {
            Button(action: action) {
                content
            }
            .buttonStyle(.plain)
            .disabled(!isEnabled || isLoading)
            .accessibilityElement(children: .combine)
            .accessibilityLabel(accessibilityLabel)
            .accessibilityHint(Text("Double tap to upvote"))
        } else {
            content
                .accessibilityElement(children: .combine)
                .accessibilityLabel(accessibilityLabel)
        }
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
