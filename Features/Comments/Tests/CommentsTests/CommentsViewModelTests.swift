//
//  CommentsViewModelTests.swift
//  CommentsTests
//
//  Copyright © 2025 Weiran Zhang. All rights reserved.
//

import Testing
@testable import Comments
import Domain
import Shared
import Foundation

@Suite("CommentsViewModel Tests")
struct CommentsViewModelTests {
    let mockPostUseCase: MockPostUseCase
    let mockCommentUseCase: MockCommentUseCase
    let mockVoteUseCase: MockVoteUseCase
    let testPost: Post
    let sut: CommentsViewModel

    init() {
        self.mockPostUseCase = MockPostUseCase()
        self.mockCommentUseCase = MockCommentUseCase()
        self.mockVoteUseCase = MockVoteUseCase()

        self.testPost = Post(
            id: 1,
            url: URL(string: "https://example.com")!,
            title: "Test Post",
            age: "1 hour ago",
            commentsCount: 5,
            by: "testuser",
            score: 100,
            postType: .news,
            upvoted: false
        )

        self.sut = CommentsViewModel(
            post: testPost,
            postUseCase: mockPostUseCase,
            commentUseCase: mockCommentUseCase,
            voteUseCase: mockVoteUseCase
        )
    }

    // MARK: - Loading Comments Tests

    @Test("Loading comments successfully populates comments and visible comments")
    @MainActor
    func loadCommentsSuccess() async {
        // Given
        let expectedComments = createTestComments()
        let postWithComments = createPostWithComments(comments: expectedComments)
        mockPostUseCase.mockPost = postWithComments

        // When
        await sut.loadComments()

        // Then
        #expect(sut.comments.count == expectedComments.count)
        #expect(sut.visibleComments.count == expectedComments.count)
        #expect(!sut.isLoading)
        #expect(sut.error == nil)
    }

    @Test("Loading comments calls onCommentsLoaded callback")
    @MainActor
    func loadCommentsCallsCallback() async {
        // Given
        let expectedComments = createTestComments()
        let postWithComments = createPostWithComments(comments: expectedComments)
        mockPostUseCase.mockPost = postWithComments

        var callbackCalled = false
        var receivedComments: [Domain.Comment] = []
        sut.onCommentsLoaded = { (comments: [Domain.Comment]) in
            callbackCalled = true
            receivedComments = comments
        }

        // When
        await sut.loadComments()

        // Then
        #expect(callbackCalled)
        #expect(receivedComments.count == expectedComments.count)
    }

    @Test("Loading comments handles failure gracefully")
    @MainActor
    func loadCommentsFailure() async {
        // Given
        mockPostUseCase.shouldThrowError = true

        // When
        await sut.loadComments()

        // Then
        #expect(sut.comments.isEmpty)
        #expect(sut.visibleComments.isEmpty)
        #expect(!sut.isLoading)
        #expect(sut.error != nil)
    }

    @Test("Loading comments does not proceed when already loading")
    @MainActor
    func loadCommentsSkipsWhenAlreadyLoading() async {
        // Given - Create a slow-loading scenario
        mockPostUseCase.shouldDelay = true
        mockPostUseCase.getPostCallCount = 0

        // Start first load (but don't await it)
        let firstLoadTask = Task {
            await sut.loadComments()
        }

        // Brief delay to ensure first load has started
        try? await Task.sleep(nanoseconds: 10_000_000) // 0.01 seconds

        // When - Try to load again while first load is in progress
        await sut.loadComments()

        // Wait for first load to complete
        await firstLoadTask.value

        // Then - Should only have called getPost once
        #expect(mockPostUseCase.getPostCallCount == 1)
    }

    // MARK: - Voting Tests

    @Test("Upvoting post updates state correctly", arguments: [
        (initial: false, upvote: true, expectedUpvoted: true, expectedScoreDelta: 1)
    ])
    @MainActor
    func voteOnPost(initial: Bool, upvote: Bool, expectedUpvoted: Bool, expectedScoreDelta: Int) async throws {
        // Given
        sut.post.upvoted = initial
        let initialScore = sut.post.score

        // When
        try await sut.voteOnPost(upvote: upvote)

        // Then
        #expect(sut.post.upvoted == expectedUpvoted)
        #expect(sut.post.score == initialScore + expectedScoreDelta)
        #expect(mockVoteUseCase.upvotePostCalled)
    }

    @Test("Failed vote on post reverts changes")
    @MainActor
    func voteOnPostFailureRevertsChanges() async {
        // Given
        mockVoteUseCase.shouldThrowError = true
        let initialUpvoted = sut.post.upvoted
        let initialScore = sut.post.score

        // When & Then
        await #expect(throws: MockError.self) {
            try await sut.voteOnPost(upvote: true)
        }

        #expect(sut.post.upvoted == initialUpvoted)
        #expect(sut.post.score == initialScore)
    }

    @Test("Upvoting comment updates state", arguments: [false])
    @MainActor
    func voteOnComment(initialUpvoted: Bool) async throws {
        // Given
        let comment = createTestComment(id: 1, upvoted: initialUpvoted)
        let expectedUpvoted = true

        // When
        try await sut.voteOnComment(comment, upvote: expectedUpvoted)

        // Then
        #expect(comment.upvoted == expectedUpvoted)
        #expect(mockVoteUseCase.upvoteCommentCalled)
    }

    // MARK: - Comment Visibility Tests

    @Suite("Comment Visibility")
    struct CommentVisibilityTests {
        let mockPostUseCase: MockPostUseCase
        let mockCommentUseCase: MockCommentUseCase
        let mockVoteUseCase: MockVoteUseCase
        let testPost: Post
        let sut: CommentsViewModel

        init() {
            self.mockPostUseCase = MockPostUseCase()
            self.mockCommentUseCase = MockCommentUseCase()
            self.mockVoteUseCase = MockVoteUseCase()

            self.testPost = Post(
                id: 1,
                url: URL(string: "https://example.com")!,
                title: "Test",
                age: "1h",
                commentsCount: 0,
                by: "user",
                score: 0,
                postType: .news,
                upvoted: false
            )

            self.sut = CommentsViewModel(
                post: testPost,
                postUseCase: mockPostUseCase,
                commentUseCase: mockCommentUseCase,
                voteUseCase: mockVoteUseCase
            )
        }

        private func createTestComment(id: Int, level: Int = 0) -> Domain.Comment {
            return Domain.Comment(
                id: id,
                age: "1 hour ago",
                text: "Test comment \(id)",
                by: "user\(id)",
                level: level,
                upvoted: false,
                visibility: Domain.CommentVisibilityType.visible
            )
        }

        private func createPostWithComments(comments: [Domain.Comment]) -> Post {
            var post = testPost
            post.comments = comments.isEmpty ? nil : comments
            return post
        }

        @Test("Toggle comment from visible to compact hides children")
        @MainActor
        func toggleVisibleToCompact() async {
            // Given - Set up mock to return comments
            let parentComment = createTestComment(id: 1, level: 0)
            let childComment = createTestComment(id: 2, level: 1)
            let testPostWithComments = createPostWithComments(comments: [parentComment, childComment])
            mockPostUseCase.mockPost = testPostWithComments

            // Load comments
            await sut.loadComments()

            // Verify initial state
            #expect(sut.comments.count == 2)
            let loadedParent = sut.comments.first(where: { $0.id == 1 })!
            let loadedChild = sut.comments.first(where: { $0.id == 2 })!

            #expect(loadedParent.visibility == Domain.CommentVisibilityType.visible)
            #expect(loadedChild.visibility == Domain.CommentVisibilityType.visible)

            // When
            sut.toggleCommentVisibility(loadedParent)

            // Then
            #expect(loadedParent.visibility == Domain.CommentVisibilityType.compact)
            #expect(loadedChild.visibility == Domain.CommentVisibilityType.hidden)
            #expect(sut.visibleComments.count == 1)
        }

        @Test("Toggle comment from compact to visible shows children")
        @MainActor
        func toggleCompactToVisible() async {
            // Given - Set up mock with comments in compact state
            let parentComment = createTestComment(id: 1, level: 0)
            let childComment = createTestComment(id: 2, level: 1)
            parentComment.visibility = Domain.CommentVisibilityType.compact
            childComment.visibility = Domain.CommentVisibilityType.hidden

            let testPostWithComments = createPostWithComments(comments: [parentComment, childComment])
            mockPostUseCase.mockPost = testPostWithComments

            // Load comments
            await sut.loadComments()

            // Verify initial state
            let loadedParent = sut.comments.first(where: { $0.id == 1 })!
            let loadedChild = sut.comments.first(where: { $0.id == 2 })!

            // When
            sut.toggleCommentVisibility(loadedParent)

            // Then
            #expect(loadedParent.visibility == Domain.CommentVisibilityType.visible)
            #expect(loadedChild.visibility == Domain.CommentVisibilityType.visible)
            #expect(sut.visibleComments.count == 2)
        }

        @Test("Hide comment branch collapses entire tree")
        @MainActor
        func hideCommentBranch() async {
            // Given - Set up mock with comment hierarchy
            let rootComment = createTestComment(id: 1, level: 0)
            let childComment1 = createTestComment(id: 2, level: 1)
            let childComment2 = createTestComment(id: 3, level: 2)

            let testPostWithComments = createPostWithComments(comments: [rootComment, childComment1, childComment2])
            mockPostUseCase.mockPost = testPostWithComments

            // Load comments
            await sut.loadComments()

            // Verify initial state
            #expect(sut.comments.count == 3)
            let loadedChild2 = sut.comments.first(where: { $0.id == 3 })!

            // When
            sut.hideCommentBranch(loadedChild2)

            // Then
            let loadedRoot = sut.comments.first(where: { $0.id == 1 })!
            let loadedChild1 = sut.comments.first(where: { $0.id == 2 })!

            #expect(loadedRoot.visibility == Domain.CommentVisibilityType.compact)
            #expect(loadedChild1.visibility == Domain.CommentVisibilityType.hidden)
            #expect(loadedChild2.visibility == Domain.CommentVisibilityType.hidden)
            #expect(sut.visibleComments.count == 1)
        }
    }

    // MARK: - Helper Methods

    private func createTestComments() -> [Domain.Comment] {
        return [
            createTestComment(id: 1, level: 0),
            createTestComment(id: 2, level: 1),
            createTestComment(id: 3, level: 1),
            createTestComment(id: 4, level: 2),
            createTestComment(id: 5, level: 0)
        ]
    }

    private func createTestComment(id: Int, level: Int = 0, upvoted: Bool = false) -> Domain.Comment {
        return Domain.Comment(
            id: id,
            age: "1 hour ago",
            text: "Test comment \(id)",
            by: "user\(id)",
            level: level,
            upvoted: upvoted,
            visibility: Domain.CommentVisibilityType.visible
        )
    }

    private func createPostWithComments(comments: [Domain.Comment]) -> Post {
        var post = testPost
        post.comments = comments.isEmpty ? nil : comments
        return post
    }
}

// MARK: - Mock Classes

final class MockPostUseCase: PostUseCase, @unchecked Sendable {
    var mockPost: Post?
    var shouldThrowError = false
    var shouldDelay = false
    var getPostCallCount = 0

    func getPost(id: Int) async throws -> Post {
        getPostCallCount += 1
        if shouldDelay {
            try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        }
        if shouldThrowError {
            throw MockError.testError
        }
        return mockPost ?? Post(
            id: id,
            url: URL(string: "https://example.com")!,
            title: "Mock Post",
            age: "1 hour ago",
            commentsCount: 0,
            by: "mockuser",
            score: 0,
            postType: .news,
            upvoted: false
        )
    }

    func getPosts(type: PostType, page: Int, nextId: Int?) async throws -> [Post] {
        return []
    }
}

final class MockCommentUseCase: CommentUseCase, @unchecked Sendable {
    func getComments(for post: Post) async throws -> [Domain.Comment] {
        return []
    }
}

final class MockVoteUseCase: VoteUseCase, @unchecked Sendable {
    var upvotePostCalled = false
    var upvoteCommentCalled = false
    var shouldThrowError = false

    func upvote(post: Post) async throws {
        upvotePostCalled = true
        if shouldThrowError {
            throw MockError.testError
        }
    }

    func upvote(comment: Domain.Comment, for post: Post) async throws {
        upvoteCommentCalled = true
        if shouldThrowError {
            throw MockError.testError
        }
    }
}

enum MockError: Error {
    case testError
}

// Helper function to create test comment outside of struct
private func createTestComment(id: Int, level: Int = 0, upvoted: Bool = false) -> Domain.Comment {
    return Domain.Comment(
        id: id,
        age: "1 hour ago",
        text: "Test comment \(id)",
        by: "user\(id)",
        level: level,
        upvoted: upvoted,
        visibility: .visible
    )
}
