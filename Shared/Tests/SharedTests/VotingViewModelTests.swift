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
        var errorToThrow: Error?

        func votingState(for item: any Votable) -> VotingState {
            VotingState(
                isUpvoted: item.upvoted,
                score: (item as? any ScoredVotable)?.score,
                canVote: item.voteLinks?.upvote != nil,
            )
        }

        func upvote(item _: any Votable) async throws {
            upvoteCalled = true
            if let errorToThrow { throw errorToThrow }
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
        var logoutCalled = false
        func authenticate(username _: String, password _: String) async throws {}
        func logout() async throws { logoutCalled = true }
        func isAuthenticated() async -> Bool { false }
        func getCurrentUser() async -> User? { nil }
    }

    @MainActor
    final class MockNavigationStore: NavigationStoreProtocol {
        init() {}

        @MainActor var selectedPost: Post?
        @MainActor var showingLogin: Bool = false
        @MainActor var showingSettings: Bool = false
        @MainActor var showLoginCalled = false

        @MainActor func showPost(_ post: Post) { selectedPost = post }
        @MainActor func showLogin() { showingLogin = true; showLoginCalled = true }
        @MainActor func showSettings() { showingSettings = true }
        @MainActor func selectPostType(_: PostType) {}
    }

    // MARK: - Unauthenticated flow

    @Test("Unauthenticated upvote triggers logout and login prompt")
    @MainActor
    func unauthenticatedUpvoteFlow() async throws {
        // Given
        let mockAuth = MockAuthenticationUseCase()
        let nav = MockNavigationStore()
        let viewModel = VotingViewModel(
            votingService: mockVotingService,
            commentVotingService: mockCommentVotingService,
            authenticationUseCase: mockAuth,
        )
        viewModel.navigationStore = nav

        mockVotingService.errorToThrow = HackersKitError.unauthenticated

        var post = Post(
            id: 1,
            url: URL(string: "https://example.com")!,
            title: "Post",
            age: "1h",
            commentsCount: 0,
            by: "user",
            score: 10,
            postType: .news,
            upvoted: false,
            voteLinks: VoteLinks(upvote: URL(string: "/vote?up"), unvote: nil)
        )

        // When
        await viewModel.upvote(post: &post)

        // Then
        #expect(mockVotingService.upvoteCalled, "Upvote should be attempted")
        #expect(mockAuth.logoutCalled, "Logout should be called on unauthenticated error")
        #expect(nav.showLoginCalled, "Navigation should prompt login")
        #expect(viewModel.lastError == nil, "lastError should not be set for unauthenticated flow")
        #expect(post.upvoted == false && post.score == 10, "Optimistic state should be reverted")
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
