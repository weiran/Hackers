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
    let compactMode: Bool
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
        compactMode: Bool = false,
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
        self.compactMode = compactMode
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
                Button(action: { onThumbnailTap?() }, label: {
                    ThumbnailView(url: post.url, isEnabled: showThumbnails)
                        .frame(width: 55, height: 55)
                        .clipShape(.rect(cornerRadius: 16))
                        .contentShape(Rectangle())
                })
                .buttonStyle(.plain)
                .accessibilityAddTraits(.isButton)
                .accessibilityLabel("Open link")

                VStack(alignment: .leading, spacing: 6) {
                    if compactMode {
                        // Compact mode: URL with inline stats
                        if let host = post.url.host,
                           !isHackerNewsItemURL(post.url) {
                            HStack(spacing: 6) {
                                Text(truncatedHost(host).uppercased())
                                    .scaledFont(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)

                                Text("•")
                                    .scaledFont(.caption)
                                    .foregroundStyle(.secondary)

                                inlineUpvoteStat

                                Text("•")
                                    .scaledFont(.caption)
                                    .foregroundStyle(.secondary)

                                inlineCommentsStat
                            }
                        } else {
                            // For HN item URLs, show stats without URL
                            HStack(spacing: 6) {
                                inlineUpvoteStat

                                Text("•")
                                    .scaledFont(.caption)
                                    .foregroundStyle(.secondary)

                                inlineCommentsStat
                            }
                        }
                    } else {
                        // Normal mode: URL line
                        if let host = post.url.host,
                           !isHackerNewsItemURL(post.url) {
                            Text(truncatedHost(host).uppercased())
                                .scaledFont(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }

                    // Title
                    Text(post.title)
                        .scaledFont(.headline)
                        .foregroundStyle(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    // Metadata row (only in normal mode)
                    if !compactMode {
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
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .onChange(of: post.id) { _, _ in
            displayedScore = post.score
            displayedUpvoted = post.upvoted
            displayedBookmarked = post.isBookmarked
            displayedVoteLinks = post.voteLinks
        }
        .onChange(of: post.score) { _, newValue in
            displayedScore = newValue
        }
        .onChange(of: post.upvoted) { _, newValue in
            displayedUpvoted = newValue
        }
        .onChange(of: post.isBookmarked) { _, newValue in
            displayedBookmarked = newValue
        }
        .onChange(of: post.voteLinks) { _, newValue in
            displayedVoteLinks = newValue
        }
        .onChange(of: votingState?.score) { _, newValue in
            if let newValue {
                displayedScore = newValue
            }
        }
        .onChange(of: votingState?.isUpvoted) { _, newValue in
            if let newValue {
                displayedUpvoted = newValue
            }
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
