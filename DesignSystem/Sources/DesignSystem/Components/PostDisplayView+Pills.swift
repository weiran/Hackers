//
//  PostDisplayView+Pills.swift
//  DesignSystem
//
//  Copyright © 2025 Weiran Zhang. All rights reserved.
//

import Domain
import SwiftUI

fileprivate struct PillConfiguration {
    let iconName: String?
    let text: String
    let textColor: Color
    let backgroundColor: Color
    let accessibilityLabel: String
    let accessibilityHint: String?
    let isLoading: Bool
    let isEnabled: Bool
    let numericValue: Int?
}

extension PostDisplayView {
    var inlineUpvoteStat: some View {
        let score = displayedScore
        let isUpvoted = displayedUpvoted
        let iconName = isUpvoted ? "arrow.up.circle.fill" : "arrow.up"
        let color: Color = isUpvoted
            ? AppColors.pillForeground(for: .upvote(isActive: true), colorScheme: colorScheme)
            : .secondary

        return HStack(spacing: 3) {
            Image(systemName: iconName)
                .scaledFont(.caption2)
                .foregroundStyle(color)
            Text("\(score)")
                .scaledFont(.caption)
                .foregroundStyle(color)
                .contentTransition(.numericText())
                .animation(.easeInOut(duration: 0.2), value: score)
        }
    }

    var inlineCommentsStat: some View {
        HStack(spacing: 3) {
            Image(systemName: "message")
                .scaledFont(.caption2)
                .foregroundStyle(.secondary)
            Text("\(post.commentsCount)")
                .scaledFont(.caption)
                .foregroundStyle(.secondary)
        }
    }

    var upvotePill: some View {
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
        let accessibilityHint: String?
        if isLoading {
            accessibilityLabel = "Submitting vote"
            accessibilityHint = nil
        } else if isUpvoted && canUnvote {
            accessibilityLabel = "\(score) points, upvoted"
            accessibilityHint = "Double tap to unvote"
        } else if isUpvoted {
            accessibilityLabel = "\(score) points, upvoted"
            accessibilityHint = nil
        } else {
            accessibilityLabel = "\(score) points"
            accessibilityHint = "Double tap to upvote"
        }

        let configuration = PillConfiguration(
            iconName: iconName,
            text: "\(score)",
            textColor: textColor,
            backgroundColor: backgroundColor,
            accessibilityLabel: accessibilityLabel,
            accessibilityHint: accessibilityHint,
            isLoading: isLoading,
            isEnabled: canInteract,
            numericValue: score
        )

        return pillView(
            configuration: configuration,
            action: canInteract ? makeUpvoteAction() : nil
        )
    }

    var commentsPill: some View {
        let style = AppColors.PillStyle.comments
        let commentTextColor = AppColors.pillForeground(for: style, colorScheme: colorScheme)
        let commentBackgroundColor = AppColors.pillBackground(for: style, colorScheme: colorScheme)
        // Brighter styling keeps the comments count from reading as a disabled control
        let configuration = PillConfiguration(
            iconName: "message",
            text: "\(post.commentsCount)",
            textColor: commentTextColor,
            backgroundColor: commentBackgroundColor,
            accessibilityLabel: "\(post.commentsCount) comments",
            accessibilityHint: nil,
            isLoading: false,
            isEnabled: true,
            numericValue: post.commentsCount
        )

        return pillView(configuration: configuration, action: onCommentsTap)
    }

    var bookmarkPill: some View {
        let isBookmarked = displayedBookmarked
        let style = AppColors.PillStyle.bookmark(isSaved: isBookmarked)
        let backgroundColor = AppColors.pillBackground(for: style, colorScheme: colorScheme)
        let textColor = AppColors.pillForeground(for: style, colorScheme: colorScheme)
        let iconName = isBookmarked ? "bookmark.fill" : "bookmark"
        let accessibilityLabel = isBookmarked ? "Remove bookmark" : "Save for later"
        let accessibilityHint = isBookmarked
            ? "Double tap to remove from bookmarks"
            : "Double tap to add to bookmarks"

        let configuration = PillConfiguration(
            iconName: iconName,
            text: isBookmarked ? "Saved" : "Save",
            textColor: textColor,
            backgroundColor: backgroundColor,
            accessibilityLabel: accessibilityLabel,
            accessibilityHint: accessibilityHint,
            isLoading: isSubmittingBookmark,
            isEnabled: !isSubmittingBookmark,
            numericValue: nil
        )

        return pillView(configuration: configuration, action: makeBookmarkAction())
    }

    func makeUpvoteAction() -> (() -> Void)? {
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

    func derivedVoteLinks(afterUpvoteFrom voteLinks: VoteLinks?) -> VoteLinks? {
        guard let voteLinks else { return nil }
        if voteLinks.unvote != nil {
            return voteLinks
        }
        guard let upvoteURL = voteLinks.upvote else {
            return voteLinks
        }
        let absolute = upvoteURL.absoluteString
        if absolute.contains("how=up"),
           let unvoteURL = URL(string: absolute.replacingOccurrences(of: "how=up", with: "how=un")) {
            return VoteLinks(upvote: upvoteURL, unvote: unvoteURL)
        }
        if absolute.contains("how%3Dup"),
           let unvoteURL = URL(string: absolute.replacingOccurrences(of: "how%3Dup", with: "how%3Dun")) {
            return VoteLinks(upvote: upvoteURL, unvote: unvoteURL)
        }
        return voteLinks
    }

    func makeBookmarkAction() -> (() -> Void)? {
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
    fileprivate func pillView(
        configuration: PillConfiguration,
        action: (() -> Void)? = nil
    ) -> some View {
        let content = pillContent(configuration: configuration)
        let shouldDisable = !configuration.isEnabled || configuration.isLoading
        let shouldBeInteractive = configuration.isEnabled && !configuration.isLoading && action != nil

        // If enabled but no action, render as static view to avoid disabled styling
        if configuration.isEnabled && !configuration.isLoading && action == nil {
            content
                .accessibilityElement(children: .combine)
                .accessibilityLabel(configuration.accessibilityLabel)
                .accessibilityHint(configuration.accessibilityHint ?? "")
        } else {
            Button(action: action ?? {}, label: {
                content
            })
            .buttonStyle(.plain)
            .disabled(!shouldBeInteractive)
            .allowsHitTesting(shouldBeInteractive)
            .opacity(shouldDisable ? 0.6 : 1.0)
            .accessibilityElement(children: .combine)
            .accessibilityLabel(configuration.accessibilityLabel)
            .accessibilityHint(configuration.accessibilityHint ?? "")
        }
    }

    @ViewBuilder
    fileprivate func pillContent(configuration: PillConfiguration) -> some View {
        let iconDimension: CGFloat = 12
        HStack(spacing: 4) {
            if let iconName = configuration.iconName {
                Image(systemName: iconName)
                    .scaledFont(.caption2)
                    .foregroundStyle(configuration.textColor)
                    .frame(width: iconDimension, height: iconDimension)
            }
            if let value = configuration.numericValue {
                Text(configuration.text)
                    .scaledFont(.caption)
                    .foregroundStyle(configuration.textColor)
                    .contentTransition(.numericText())
                    .animation(.easeInOut(duration: 0.2), value: value)
            } else {
                Text(configuration.text)
                    .scaledFont(.caption)
                    .foregroundStyle(configuration.textColor)
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        .background(Capsule().fill(configuration.backgroundColor))
        .overlay {
            if configuration.isLoading {
                Capsule()
                    .fill(configuration.backgroundColor.opacity(0.6))
            }
        }
        .overlay {
            if configuration.isLoading {
                ProgressView()
                    .scaleEffect(0.6)
                    .tint(configuration.textColor)
            }
        }
    }
}
