//
//  PostRowView.swift
//  Feed
//
//  Extracted from FeedView to keep file size manageable.
//

import DesignSystem
import Domain
import Shared
import SwiftUI

struct PostRowView: View {
    let post: Domain.Post
    let votingViewModel: VotingViewModel
    let onLinkTap: (() -> Void)?
    let onCommentsTap: (() -> Void)?
    let showThumbnails: Bool
    let compactMode: Bool
    let onPostUpdated: ((Domain.Post) -> Void)?
    let onBookmarkToggle: (() async -> Bool)?

    init(
        post: Domain.Post,
        votingViewModel: VotingViewModel,
        showThumbnails: Bool = true,
        compactMode: Bool = false,
        onLinkTap: (() -> Void)? = nil,
        onCommentsTap: (() -> Void)? = nil,
        onPostUpdated: ((Domain.Post) -> Void)? = nil,
        onBookmarkToggle: (() async -> Bool)? = nil
    ) {
        self.post = post
        self.votingViewModel = votingViewModel
        self.onLinkTap = onLinkTap
        self.onCommentsTap = onCommentsTap
        self.showThumbnails = showThumbnails
        self.compactMode = compactMode
        self.onPostUpdated = onPostUpdated
        self.onBookmarkToggle = onBookmarkToggle
    }

    var body: some View {
        if let onCommentsTap {
            Button(action: onCommentsTap) {
                PostDisplayView(
                    post: post,
                    votingState: votingViewModel.votingState(for: post),
                    showPostText: false,
                    showThumbnails: showThumbnails,
                    compactMode: compactMode,
                    onThumbnailTap: onLinkTap,
                    onUpvoteTap: { await handleUpvoteTap() },
                    onUnvoteTap: { await handleUnvoteTap() },
                    onBookmarkTap: {
                        guard let onBookmarkToggle else { return post.isBookmarked }
                        return await onBookmarkToggle()
                    },
                    onCommentsTap: onCommentsTap
                )
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityAddTraits(.isButton)
            .accessibilityHint("Open comments")
        } else {
            PostDisplayView(
                post: post,
                votingState: votingViewModel.votingState(for: post),
                showPostText: false,
                showThumbnails: showThumbnails,
                compactMode: compactMode,
                onThumbnailTap: onLinkTap,
                onUpvoteTap: { await handleUpvoteTap() },
                onUnvoteTap: { await handleUnvoteTap() },
                onBookmarkTap: {
                    guard let onBookmarkToggle else { return post.isBookmarked }
                    return await onBookmarkToggle()
                },
                onCommentsTap: onCommentsTap
            )
            .contentShape(Rectangle())
        }
    }

    private func handleUpvoteTap() async -> Bool {
        guard votingViewModel.canVote(item: post), !post.upvoted else { return false }

        var mutablePost = post
        await votingViewModel.upvote(post: &mutablePost)
        let wasUpvoted = mutablePost.upvoted

        if wasUpvoted {
            await MainActor.run {
                onPostUpdated?(mutablePost)
            }
        }

        return wasUpvoted
    }

    private func handleUnvoteTap() async -> Bool {
        guard votingViewModel.canUnvote(item: post), post.upvoted else { return true }

        var mutablePost = post
        await votingViewModel.unvote(post: &mutablePost)
        let wasUnvoted = !mutablePost.upvoted

        if wasUnvoted {
            if let existingLinks = mutablePost.voteLinks {
                mutablePost.voteLinks = VoteLinks(upvote: existingLinks.upvote, unvote: nil)
            }
            await MainActor.run {
                onPostUpdated?(mutablePost)
            }
        }

        return wasUnvoted
    }
}
