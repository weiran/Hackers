//
//  VotingViewModelTests.swift
//  SharedTests
//
//  Copyright © 2025 Weiran Zhang. All rights reserved.
//

import Testing
import Foundation
import Domain
@testable import Shared

@Suite("VotingViewModel Tests")
struct VotingViewModelTests {
    
    let mockVotingService = MockVotingService()
    let mockCommentVotingService = MockCommentVotingService()
    
    @MainActor
    var votingViewModel: VotingViewModel {
        VotingViewModel(
            votingService: mockVotingService,
            commentVotingService: mockCommentVotingService
        )
    }

    // MARK: - Mock Services
    
    final class MockVotingService: VotingService, @unchecked Sendable {
        var toggleVoteCalled = false
        var upvoteCalled = false
        var unvoteCalled = false
        var shouldThrow = false
        
        func votingState(for item: any Votable) -> VotingState {
            return VotingState(
                isUpvoted: item.upvoted,
                score: (item as? any ScoredVotable)?.score,
                canVote: item.voteLinks?.upvote != nil || item.voteLinks?.unvote != nil
            )
        }
        
        func toggleVote(for item: any Votable) async throws {
            toggleVoteCalled = true
            if shouldThrow {
                throw HackersKitError.requestFailure
            }
        }
        
        func upvote(item: any Votable) async throws {
            upvoteCalled = true
            if shouldThrow {
                throw HackersKitError.requestFailure
            }
        }
        
        func unvote(item: any Votable) async throws {
            unvoteCalled = true
            if shouldThrow {
                throw HackersKitError.requestFailure
            }
        }
    }
    
    final class MockCommentVotingService: CommentVotingService, @unchecked Sendable {
        var upvoteCommentCalled = false
        var unvoteCommentCalled = false
        var toggleVoteCalled = false
        var shouldThrow = false
        
        func upvoteComment(_ comment: Domain.Comment, for post: Post) async throws {
            upvoteCommentCalled = true
            if shouldThrow {
                throw HackersKitError.requestFailure
            }
        }
        
        func unvoteComment(_ comment: Domain.Comment, for post: Post) async throws {
            unvoteCommentCalled = true
            if shouldThrow {
                throw HackersKitError.requestFailure
            }
        }
        
        func toggleVoteOnComment(_ comment: Domain.Comment, for post: Post) async throws {
            toggleVoteCalled = true
            if shouldThrow {
                throw HackersKitError.requestFailure
            }
        }
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
            voteLinks: voteLinks
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
            upvoted: false
        )

        // When - This should work because the method is marked @MainActor
        await votingViewModel.toggleVote(for: comment, in: post)

        // Then
        #expect(mockCommentVotingService.toggleVoteCalled, "Toggle vote should be called")
        #expect(comment.upvoted == true, "Comment should be marked as upvoted after toggle")
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
            voteLinks: voteLinks
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
            upvoted: false
        )
        
        mockCommentVotingService.shouldThrow = true

        // When
        await votingViewModel.toggleVote(for: comment, in: post)

        // Then - Should revert the optimistic update
        #expect(mockCommentVotingService.toggleVoteCalled, "Toggle vote should be called")
        #expect(comment.upvoted == false, "Comment should be reverted to original state after error")
        #expect(votingViewModel.lastError != nil, "Error should be set")
    }
}