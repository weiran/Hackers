//
//  VotingService.swift
//  Domain
//
//  Copyright © 2025 Weiran Zhang. All rights reserved.
//

import Foundation

// MARK: - Voting Service Protocol

public protocol VotingService: Sendable {
    func votingState(for item: any Votable) -> VotingState
    func toggleVote(for item: any Votable) async throws
    func upvote(item: any Votable) async throws
    func unvote(item: any Votable) async throws
}

// MARK: - Default Implementation

public final class DefaultVotingService: VotingService, Sendable {
    private let voteUseCase: VoteUseCase

    public init(voteUseCase: VoteUseCase) {
        self.voteUseCase = voteUseCase
    }

    public func votingState(for item: any Votable) -> VotingState {
        let score: Int? = (item as? any ScoredVotable)?.score
        return VotingState(
            isUpvoted: item.upvoted,
            score: score,
            canVote: item.voteLinks?.upvote != nil || item.voteLinks?.unvote != nil,
            isVoting: false
        )
    }

    public func toggleVote(for item: any Votable) async throws {
        if item.upvoted {
            try await unvote(item: item)
        } else {
            try await upvote(item: item)
        }
    }

    public func upvote(item: any Votable) async throws {
        switch item {
        case let post as Post:
            try await voteUseCase.upvote(post: post)
        case let comment as Comment:
            // For comments, we need the parent post - this will be handled by the calling code
            throw HackersKitError.requestFailure
        default:
            throw HackersKitError.requestFailure
        }
    }

    public func unvote(item: any Votable) async throws {
        switch item {
        case let post as Post:
            try await voteUseCase.unvote(post: post)
        case let comment as Comment:
            // For comments, we need the parent post - this will be handled by the calling code
            throw HackersKitError.requestFailure
        default:
            throw HackersKitError.requestFailure
        }
    }
}

// MARK: - Comment-Specific Voting Service

public protocol CommentVotingService: Sendable {
    func upvoteComment(_ comment: Comment, for post: Post) async throws
    func unvoteComment(_ comment: Comment, for post: Post) async throws
    func toggleVoteOnComment(_ comment: Comment, for post: Post) async throws
}

extension DefaultVotingService: CommentVotingService {
    public func upvoteComment(_ comment: Comment, for post: Post) async throws {
        try await voteUseCase.upvote(comment: comment, for: post)
    }

    public func unvoteComment(_ comment: Comment, for post: Post) async throws {
        try await voteUseCase.unvote(comment: comment, for: post)
    }

    public func toggleVoteOnComment(_ comment: Comment, for post: Post) async throws {
        if comment.upvoted {
            try await unvoteComment(comment, for: post)
        } else {
            try await upvoteComment(comment, for: post)
        }
    }
}
