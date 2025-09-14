//
//  VotingViewModel.swift
//  Shared
//
//  Copyright © 2025 Weiran Zhang. All rights reserved.
//

import Foundation
import SwiftUI
import Domain

@MainActor
@Observable
public final class VotingViewModel {
    private let votingService: VotingService
    private let commentVotingService: CommentVotingService
    public var navigationStore: NavigationStoreProtocol?

    public var isVoting = false
    public var lastError: Error?

    public init(
        votingService: VotingService,
        commentVotingService: CommentVotingService
    ) {
        self.votingService = votingService
        self.commentVotingService = commentVotingService
    }

    // MARK: - Post Voting

    public func toggleVote(for post: inout Post) async {
        
        let originalUpvoted = post.upvoted
        let originalScore = post.score

        // Create a copy of the post with the original state for the voting service
        var postForVoting = post
        postForVoting.upvoted = originalUpvoted
        postForVoting.score = originalScore

        // Optimistic UI update
        post.upvoted.toggle()
        post.score += post.upvoted ? 1 : -1

        isVoting = true
        lastError = nil

        do {
            try await votingService.toggleVote(for: postForVoting)
            
        } catch {
            
            // Revert optimistic changes on error
            post.upvoted = originalUpvoted
            post.score = originalScore
            
            // Check if error is unauthenticated and show login
            if case HackersKitError.unauthenticated = error {
                navigationStore?.showLogin()
            } else {
                lastError = error
            }
        }

        isVoting = false
    }

    public func upvote(post: inout Post) async {
        guard !post.upvoted else { return }
        

        let originalScore = post.score

        // Create a copy of the post with the original state for the voting service
        var postForVoting = post
        postForVoting.upvoted = false
        postForVoting.score = originalScore

        // Optimistic UI update
        post.upvoted = true
        post.score += 1

        isVoting = true
        lastError = nil

        do {
            try await votingService.upvote(item: postForVoting)
            
        } catch {
            
            // Revert optimistic changes on error
            post.upvoted = false
            post.score = originalScore
            
            // Check if error is unauthenticated and show login
            if case HackersKitError.unauthenticated = error {
                navigationStore?.showLogin()
            } else {
                lastError = error
            }
        }

        isVoting = false
    }

    public func unvote(post: inout Post) async {
        guard post.upvoted else { return }
        

        let originalScore = post.score

        // Optimistic UI update
        post.upvoted = false
        post.score -= 1

        isVoting = true
        lastError = nil

        do {
            try await votingService.unvote(item: post)
            
        } catch {
            
            // Revert optimistic changes on error
            post.upvoted = true
            post.score = originalScore
            
            // Check if error is unauthenticated and show login
            if case HackersKitError.unauthenticated = error {
                navigationStore?.showLogin()
            } else {
                lastError = error
            }
        }

        isVoting = false
    }

    // MARK: - Comment Voting

    @MainActor
    public func toggleVote(for comment: Comment, in post: Post) async {
        let originalUpvoted = comment.upvoted
        

        // Create a copy of the comment with the original state for the voting service
        var commentForVoting = comment
        commentForVoting.upvoted = originalUpvoted

        // Optimistic UI update
        comment.upvoted.toggle()

        isVoting = true
        lastError = nil

        do {
            try await commentVotingService.toggleVoteOnComment(commentForVoting, for: post)
            
        } catch {
            
            // Revert optimistic changes on error
            comment.upvoted = originalUpvoted
            
            // Check if error is unauthenticated and show login
            if case HackersKitError.unauthenticated = error {
                navigationStore?.showLogin()
            } else {
                lastError = error
            }
        }

        isVoting = false
    }

    @MainActor
    public func upvote(comment: Comment, in post: Post) async {
        guard !comment.upvoted else { return }
        

        // Create a copy of the comment with the original state for the voting service
        var commentForVoting = comment
        commentForVoting.upvoted = false

        // Optimistic UI update
        comment.upvoted = true

        isVoting = true
        lastError = nil

        do {
            try await commentVotingService.upvoteComment(commentForVoting, for: post)
            
        } catch {
            
            // Revert optimistic changes on error
            comment.upvoted = false
            
            // Check if error is unauthenticated and show login
            if case HackersKitError.unauthenticated = error {
                navigationStore?.showLogin()
            } else {
                lastError = error
            }
        }

        isVoting = false
    }

    @MainActor
    public func unvote(comment: Comment, in post: Post) async {
        guard comment.upvoted else { return }
        

        // Optimistic UI update
        comment.upvoted = false

        isVoting = true
        lastError = nil

        do {
            try await commentVotingService.unvoteComment(comment, for: post)
            
        } catch {
            
            // Revert optimistic changes on error
            comment.upvoted = true
            
            // Check if error is unauthenticated and show login
            if case HackersKitError.unauthenticated = error {
                navigationStore?.showLogin()
            } else {
                lastError = error
            }
        }

        isVoting = false
    }

    // MARK: - State Helpers

    public func votingState(for item: any Votable) -> VotingState {
        let score: Int? = (item as? any ScoredVotable)?.score
        return VotingState(
            isUpvoted: item.upvoted,
            score: score,
            canVote: item.voteLinks?.upvote != nil || item.voteLinks?.unvote != nil,
            isVoting: isVoting,
            error: lastError
        )
    }

    public func canVote(item: any Votable) -> Bool {
        return item.voteLinks?.upvote != nil || item.voteLinks?.unvote != nil
    }

    public func clearError() {
        lastError = nil
    }
}
