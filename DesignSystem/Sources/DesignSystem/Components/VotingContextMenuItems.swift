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
        // Only show upvote if available and not already upvoted
        if post.voteLinks?.upvote != nil && !post.upvoted {
            Button {
                onVote()
            } label: {
                Label("Upvote", systemImage: "arrow.up")
            }
        }
    }

    // MARK: - Comment Voting Menu Items

    @ViewBuilder
    public static func commentVotingMenuItems(
        for comment: Comment,
        onVote: @escaping @Sendable () -> Void
    ) -> some View {
        // Only show upvote if available and not already upvoted
        if comment.voteLinks?.upvote != nil && !comment.upvoted {
            Button {
                onVote()
            } label: {
                Label("Upvote", systemImage: "arrow.up")
            }
        }
    }

    // MARK: - Generic Votable Menu Items

    @ViewBuilder
    public static func votingMenuItems<T: Votable>(
        for item: T,
        onVote: @escaping @Sendable () -> Void
    ) -> some View {
        // Only show upvote if available and not already upvoted
        if item.voteLinks?.upvote != nil && !item.upvoted {
            Button {
                onVote()
            } label: {
                Label("Upvote", systemImage: "arrow.up")
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
