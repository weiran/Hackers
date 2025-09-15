//
//  VotingViewModelTests.swift
//  SharedTests
//
//  Copyright © 2025 Weiran Zhang. All rights reserved.
//

import Domain
import Foundation
@testable import Shared
import Testing

@Suite("VotingViewModel Tests")
struct VotingViewModelTests {
    let mockVotingService = MockVotingService()
    let mockCommentVotingService = MockCommentVotingService()

    @MainActor
    var votingViewModel: VotingViewModel {
        VotingViewModel(
            votingService: mockVotingService,
            commentVotingService: mockCommentVotingService,
            authenticationUseCase: MockAuthenticationUseCase(),
        )
    }

    // MARK: - Mock Services

    final class MockVotingService: VotingService, @unchecked Sendable {
        var upvoteCalled = false
        var shouldThrow = false

        func votingState(for item: any Votable) -> VotingState {
            VotingState(
                isUpvoted: item.upvoted,
                score: (item as? any ScoredVotable)?.score,
                canVote: item.voteLinks?.upvote != nil,
            )
        }

        func upvote(item _: any Votable) async throws {
            upvoteCalled = true
            if shouldThrow {
                throw HackersKitError.requestFailure
            }
        }
    }

    final class MockCommentVotingService: CommentVotingService, @unchecked Sendable {
        var upvoteCommentCalled = false
        var shouldThrow = false

        func upvoteComment(_: Domain.Comment, for _: Post) async throws {
            upvoteCommentCalled = true
            if shouldThrow {
                throw HackersKitError.requestFailure
            }
        }
    }

    final class MockAuthenticationUseCase: AuthenticationUseCase, @unchecked Sendable {
        func authenticate(username _: String, password _: String) async throws {}
        func logout() async throws {}
        func isAuthenticated() async -> Bool { false }
        func getCurrentUser() async -> User? { nil }
    }

    // MARK: - Comment Voting Tests

    @Test("Comment voting with MainActor")
    @MainActor
    func commentVotingWithMainActor() async throws {
        // Given
        let voteLinks = VoteLinks(upvote: URL(string: "/vote?up")!, unvote: nil)
        let comment = Domain.Comment(
            id: 123,
            age: "1h",
            text: "Test comment",
            by: "user",
            level: 0,
            upvoted: false,
            voteLinks: voteLinks,
        )

        let post = Post(
            id: 456,
            url: URL(string: "https://example.com")!,
            title: "Test Post",
            age: "2h",
            commentsCount: 1,
            by: "author",
            score: 10,
            postType: .news,
            upvoted: false,
        )

        // When - upvote comment
        await votingViewModel.upvote(comment: comment, in: post)

        // Then
        #expect(mockCommentVotingService.upvoteCommentCalled, "Upvote should be called")
        #expect(comment.upvoted == true, "Comment should be marked as upvoted after upvote")
    }

    @Test("Comment voting error handling")
    @MainActor
    func commentVotingErrorHandling() async throws {
        // Given
        let voteLinks = VoteLinks(upvote: URL(string: "/vote?up")!, unvote: nil)
        let comment = Domain.Comment(
            id: 123,
            age: "1h",
            text: "Test comment",
            by: "user",
            level: 0,
            upvoted: false,
            voteLinks: voteLinks,
        )

        let post = Post(
            id: 456,
            url: URL(string: "https://example.com")!,
            title: "Test Post",
            age: "2h",
            commentsCount: 1,
            by: "author",
            score: 10,
            postType: .news,
            upvoted: false,
        )

        mockCommentVotingService.shouldThrow = true

        // When
        await votingViewModel.upvote(comment: comment, in: post)

        // Then - Should revert the optimistic update
        #expect(mockCommentVotingService.upvoteCommentCalled, "Upvote should be called")
        #expect(comment.upvoted == false, "Comment should be reverted to original state after error")
        #expect(votingViewModel.lastError != nil, "Error should be set")
    }
}
