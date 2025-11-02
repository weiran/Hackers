//
//  VotingContextMenuItems.swift
//  DesignSystem
//
//  Copyright © 2025 Weiran Zhang. All rights reserved.
//

import Domain
import SwiftUI

public enum VotingContextMenuItems {
    // MARK: - Post Voting Menu Items

    @ViewBuilder
    public static func postVotingMenuItems(
        for post: Post,
        onVote: @escaping @Sendable () -> Void,
        onUnvote: @escaping @Sendable () -> Void = {},
    ) -> some View {
        // Show upvote if available and not already upvoted
        if post.voteLinks?.upvote != nil, !post.upvoted {
            Button {
                onVote()
            } label: {
                Label("Upvote", systemImage: "arrow.up")
            }
        }
        // Show unvote if available and already upvoted
        if post.voteLinks?.unvote != nil, post.upvoted {
            Button {
                onUnvote()
            } label: {
                Label("Unvote", systemImage: "arrow.uturn.down")
            }
        }
    }

    // MARK: - Comment Voting Menu Items

    @ViewBuilder
    public static func commentVotingMenuItems(
        for comment: Comment,
        onVote: @escaping @Sendable () -> Void,
        onUnvote: @escaping @Sendable () -> Void = {},
    ) -> some View {
        // Show upvote if available and not already upvoted
        if comment.voteLinks?.upvote != nil, !comment.upvoted {
            Button {
                onVote()
            } label: {
                Label("Upvote", systemImage: "arrow.up")
            }
        }
        // Show unvote if available and already upvoted
        if comment.voteLinks?.unvote != nil, comment.upvoted {
            Button {
                onUnvote()
            } label: {
                Label("Unvote", systemImage: "arrow.uturn.down")
            }
        }
    }

    // MARK: - Generic Votable Menu Items

    @ViewBuilder
    public static func votingMenuItems(
        for item: some Votable,
        onVote: @escaping @Sendable () -> Void,
        onUnvote: @escaping @Sendable () -> Void = {},
    ) -> some View {
        // Show upvote if available and not already upvoted
        if item.voteLinks?.upvote != nil, !item.upvoted {
            Button {
                onVote()
            } label: {
                Label("Upvote", systemImage: "arrow.up")
            }
        }
        // Show unvote if available and already upvoted
        if item.voteLinks?.unvote != nil, item.upvoted {
            Button {
                onUnvote()
            } label: {
                Label("Unvote", systemImage: "arrow.uturn.down")
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
        unvoteLabel: String = "Unvote",
    ) {
        self.upvoteIconName = upvoteIconName
        self.unvoteIconName = unvoteIconName
        self.upvoteLabel = upvoteLabel
        self.unvoteLabel = unvoteLabel
    }

    public static let `default` = VotingMenuStyle()
}

// MARK: - Convenience Extensions

public extension View {
    func votingContextMenu(
        for item: some Votable,
        onVote: @escaping @Sendable () -> Void,
        onUnvote: @escaping @Sendable () -> Void = {},
        additionalItems: @escaping () -> some View = { EmptyView() },
    ) -> some View {
        contextMenu {
            VotingContextMenuItems.votingMenuItems(for: item, onVote: onVote, onUnvote: onUnvote)
            additionalItems()
        }
    }
}
