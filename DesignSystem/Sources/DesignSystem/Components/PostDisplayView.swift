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

    @State private var isSubmittingUpvote = false
    @State private var displayedScore: Int
    @State private var displayedUpvoted: Bool

    public init(
        post: Post,
        votingState: VotingState? = nil,
        showPostText: Bool = false,
        showThumbnails: Bool = true,
        onThumbnailTap: (() -> Void)? = nil,
        onUpvoteTap: (() async -> Bool)? = nil
    ) {
        self.post = post
        self.votingState = votingState
        self.showPostText = showPostText
        self.showThumbnails = showThumbnails
        self.onThumbnailTap = onThumbnailTap
        self.onUpvoteTap = onUpvoteTap
        _displayedScore = State(initialValue: post.score)
        _displayedUpvoted = State(initialValue: post.upvoted)
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
        .onChange(of: post.id) { _ in
            displayedScore = post.score
            displayedUpvoted = post.upvoted
        }
        .onChange(of: post.score) { newValue in
            displayedScore = newValue
        }
        .onChange(of: post.upvoted) { newValue in
            displayedUpvoted = newValue
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
        let (backgroundColor, textColor): (Color, Color) = {
            if isUpvoted {
                return (
                    AppColors.upvotedColor.opacity(0.2),
                    Color(red: 0.8, green: 0.48, blue: 0.0)
                )
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
        .contentTransition(.opacity)
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        .background(
            Capsule()
                .fill(backgroundColor)
        )
        .scaleEffect(isHighlighted ? 1.05 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHighlighted)

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
