//
//  VotingContextMenuItems.swift
//  DesignSystem
//
//  Copyright © 2025 Weiran Zhang. All rights reserved.
//

import SwiftUI
import Domain

public enum VotingContextMenuItems {

    // MARK: - Post Voting Menu Items

    @ViewBuilder
    public static func postVotingMenuItems(
        for post: Post,
        onVote: @escaping @Sendable () -> Void
    ) -> some View {
        if post.upvoted {
            // Only show unvote if unvote link is available
            if post.voteLinks?.unvote != nil {
                Button {
                    onVote()
                } label: {
                    Label("Unvote", systemImage: "arrow.uturn.down")
                }
            }
        } else {
            // Only show upvote if upvote link is available
            if post.voteLinks?.upvote != nil {
                Button {
                    onVote()
                } label: {
                    Label("Upvote", systemImage: "arrow.up")
                }
            }
        }
    }

    // MARK: - Comment Voting Menu Items

    @ViewBuilder
    public static func commentVotingMenuItems(
        for comment: Comment,
        onVote: @escaping @Sendable () -> Void
    ) -> some View {
        if comment.voteLinks?.upvote != nil || comment.voteLinks?.unvote != nil {
            Button {
                onVote()
            } label: {
                Label(
                    comment.upvoted ? "Unvote" : "Upvote",
                    systemImage: comment.upvoted ? "arrow.uturn.down" : "arrow.up"
                )
            }
        }
    }

    // MARK: - Generic Votable Menu Items

    @ViewBuilder
    public static func votingMenuItems<T: Votable>(
        for item: T,
        onVote: @escaping @Sendable () -> Void
    ) -> some View {
        if item.upvoted {
            // Only show unvote if unvote link is available
            if item.voteLinks?.unvote != nil {
                Button {
                    onVote()
                } label: {
                    Label("Unvote", systemImage: "arrow.uturn.down")
                }
            }
        } else {
            // Only show upvote if upvote link is available
            if item.voteLinks?.upvote != nil {
                Button {
                    onVote()
                } label: {
                    Label("Upvote", systemImage: "arrow.up")
                }
            }
        }
    }
}

// MARK: - Voting Menu Style

public struct VotingMenuStyle: Sendable {
    public let upvoteIconName: String
    public let unvoteIconName: String
    public let upvoteLabel: String
    public let unvoteLabel: String

    public init(
        upvoteIconName: String = "arrow.up",
        unvoteIconName: String = "arrow.uturn.down",
        upvoteLabel: String = "Upvote",
        unvoteLabel: String = "Unvote"
    ) {
        self.upvoteIconName = upvoteIconName
        self.unvoteIconName = unvoteIconName
        self.upvoteLabel = upvoteLabel
        self.unvoteLabel = unvoteLabel
    }

    public static let `default` = VotingMenuStyle()
}

// MARK: - Convenience Extensions

extension View {
    public func votingContextMenu<T: Votable>(
        for item: T,
        onVote: @escaping @Sendable () -> Void,
        additionalItems: @escaping () -> some View = { EmptyView() }
    ) -> some View {
        self.contextMenu {
            VotingContextMenuItems.votingMenuItems(for: item, onVote: onVote)
            additionalItems()
        }
    }
}
