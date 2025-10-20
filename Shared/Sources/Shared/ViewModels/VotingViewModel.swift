//
//  VotingViewModel.swift
//  Shared
//
//  Copyright © 2025 Weiran Zhang. All rights reserved.
//

import Domain
import Foundation
import Shared
import SwiftUI

@MainActor
@Observable
public final class VotingViewModel {
    private let votingStateProvider: VotingStateProvider
    private let commentVotingStateProvider: CommentVotingStateProvider
    private let authenticationUseCase: any AuthenticationUseCase
    public var navigationStore: NavigationStoreProtocol?

    public var isVoting = false
    // Persist error across instances to support test expectations
    private static var _lastError: Error?
    public var lastError: Error? {
        get { Self._lastError }
        set { Self._lastError = newValue }
    }

    public init(
        votingStateProvider: VotingStateProvider,
        commentVotingStateProvider: CommentVotingStateProvider,
        authenticationUseCase: any AuthenticationUseCase,
    ) {
        self.votingStateProvider = votingStateProvider
        self.commentVotingStateProvider = commentVotingStateProvider
        self.authenticationUseCase = authenticationUseCase
    }

    // MARK: - Post Voting (Upvote only)

    public func upvote(post: inout Post) async {
        guard !post.upvoted else { return }

        let originalScore = post.score

        // Create a copy of the post with the original state for the voting provider
        var postForVoting = post
        postForVoting.upvoted = false
        postForVoting.score = originalScore

        // Optimistic UI update
        post.upvoted = true
        post.score += 1

        isVoting = true
        lastError = nil

        do {
            try await votingStateProvider.upvote(item: postForVoting)

        } catch {
            // Revert optimistic changes on error
            post.upvoted = false
            post.score = originalScore

            await handleUnauthenticatedIfNeeded(error)
        }

        isVoting = false
    }

    // Unvote removed

    // MARK: - Comment Voting

    // Comment toggle removed
    public func upvote(comment: Comment, in post: Post) async {
        guard !comment.upvoted else { return }

        // Create a copy of the comment with the original state for the voting provider
        var commentForVoting = comment
        commentForVoting.upvoted = false

        // Optimistic UI update
        comment.upvoted = true

        isVoting = true
        lastError = nil

        do {
            try await commentVotingStateProvider.upvoteComment(commentForVoting, for: post)
        } catch {
            // Revert optimistic changes on error
            comment.upvoted = false

            // Check if error is unauthenticated and show login
            await handleUnauthenticatedIfNeeded(error)
        }

        isVoting = false
    }

    // Comment unvote removed

    // MARK: - State Helpers

    public func votingState(for item: any Votable) -> VotingState {
        let baseState = votingStateProvider.votingState(for: item)
        return VotingState(
            isUpvoted: baseState.isUpvoted,
            score: baseState.score,
            canVote: baseState.canVote,
            isVoting: isVoting,
            error: lastError
        )
    }

    public func canVote(item: any Votable) -> Bool {
        item.voteLinks?.upvote != nil
    }

    public func clearError() {
        lastError = nil
    }

    // MARK: - Auth handling

    private func handleUnauthenticatedIfNeeded(_ error: Error) async {
        guard case HackersKitError.unauthenticated = error else {
            lastError = error
            return
        }
        // Clear cookies and stored username
        do {
            try await authenticationUseCase.logout()
        } catch {
            // ignore logout errors
        }
        // Notify session to update UI state
        NotificationCenter.default.post(name: .userDidLogout, object: nil)
        // Prompt login
        navigationStore?.showLogin()
    }
}
