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

    public init(
        post: Post,
        votingState: VotingState? = nil,
        showPostText: Bool = false,
        showThumbnails: Bool = true,
        onThumbnailTap: (() -> Void)? = nil,
    ) {
        self.post = post
        self.votingState = votingState
        self.showPostText = showPostText
        self.showThumbnails = showThumbnails
        self.onThumbnailTap = onThumbnailTap
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 12) {
                // Thumbnail with proper loading
                if showThumbnails {
                    ThumbnailView(url: post.url)
                        .frame(width: 55, height: 55)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .contentShape(Rectangle())
                        .onTapGesture {
                            onThumbnailTap?()
                        }
                        .accessibilityAddTraits(.isButton)
                        .accessibilityLabel("Open link")
                }

                VStack(alignment: .leading, spacing: 4) {
                    // Title
                    Text(post.title)
                        .scaledFont(.headline)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    // Metadata row
                    HStack(spacing: 3) {
                        // Use new VoteIndicator if voting state is provided
                        if let votingState {
                            VoteIndicator(
                                votingState: votingState,
                                style: VoteIndicatorStyle(
                                    iconFont: .caption2,
                                    scoreFont: .subheadline,
                                    spacing: 0,
                                    defaultColor: .secondary,
                                    upvotedColor: AppColors.upvotedColor,
                                ),
                            )
                        } else {
                            // Fallback to old display
                            HStack(spacing: 0) {
                                Text("\(post.score)")
                                    .foregroundColor(post.upvoted ? AppColors.upvotedColor : .secondary)
                                Image(systemName: "arrow.up")
                                    .foregroundColor(post.upvoted ? AppColors.upvotedColor : .secondary)
                                    .scaledFont(.caption2)
                                    .accessibilityHidden(true)
                            }
                        }

                        Text("•")
                            .foregroundColor(.secondary)
                            .accessibilityHidden(true)

                        HStack(spacing: 0) {
                            Text("\(post.commentsCount)")
                                .foregroundColor(.secondary)
                            Image(systemName: "message")
                                .foregroundColor(.secondary)
                                .scaledFont(.caption2)
                                .accessibilityHidden(true)
                        }

                        if let host = post.url.host,
                           !post.url.absoluteString.starts(with: HackerNewsConstants.itemPrefix)
                        {
                            Text("•")
                                .foregroundColor(.secondary)
                                .accessibilityHidden(true)
                            Text(host)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    }
                    .scaledFont(.subheadline)
                }
            }

            if showPostText, let text = post.text, !text.isEmpty {
                Text(text)
                    .foregroundColor(.primary)
                    .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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

            if !post.url.absoluteString.starts(with: HackerNewsConstants.itemPrefix) {
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
