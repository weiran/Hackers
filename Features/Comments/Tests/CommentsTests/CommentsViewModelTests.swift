//
//  CommentsViewModelTests.swift
//  CommentsTests
//
//  Copyright © 2025 Weiran Zhang. All rights reserved.
//

@testable import Comments
import Domain
import Foundation
import Shared
import Testing

@Suite("CommentsViewModel Tests")
struct CommentsViewModelTests {
    let mockPostUseCase: MockPostUseCase
    let mockCommentUseCase: MockCommentUseCase
    let mockVoteUseCase: MockVoteUseCase
    let testPost: Post
    let sut: CommentsViewModel

    init() {
        mockPostUseCase = MockPostUseCase()
        mockCommentUseCase = MockCommentUseCase()
        mockVoteUseCase = MockVoteUseCase()

        testPost = Post(
            id: 1,
            url: URL(string: "https://example.com")!,
            title: "Test Post",
            age: "1 hour ago",
            commentsCount: 5,
            by: "testuser",
            score: 100,
            postType: .news,
            upvoted: false,
        )

        sut = CommentsViewModel(
            post: testPost,
            postUseCase: mockPostUseCase,
            commentUseCase: mockCommentUseCase,
            voteUseCase: mockVoteUseCase,
        )
    }

    @Test("Initializes in loading state when post is absent")
    func initializesWithoutPost() {
        // When
        let viewModel = CommentsViewModel(
            postID: 42,
            initialPost: nil,
            postUseCase: mockPostUseCase,
            commentUseCase: mockCommentUseCase,
            voteUseCase: mockVoteUseCase
        )

        // Then
        #expect(viewModel.post == nil)
        #expect(viewModel.isPostLoading)
        #expect(viewModel.comments.isEmpty)
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
        #expect(!sut.isPostLoading)
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
        #expect(!sut.isPostLoading)
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
        mockPostUseCase.shouldDelay = false
    }

    @Test("Refreshing comments replaces data and clears loading flag")
    @MainActor
    func refreshCommentsUpdatesThread() async {
        let firstComment = createTestComment(id: 11, level: 0)
        let secondComment = createTestComment(id: 22, level: 0)
        mockPostUseCase.postQueue = [
            createPostWithComments(comments: [firstComment]),
            createPostWithComments(comments: [secondComment])
        ]

        let viewModel = CommentsViewModel(
            postID: testPost.id,
            initialPost: nil,
            postUseCase: mockPostUseCase,
            commentUseCase: mockCommentUseCase,
            voteUseCase: mockVoteUseCase
        )

        await viewModel.loadComments()
        #expect(viewModel.comments.first?.id == 11)

        await viewModel.refreshComments()

        #expect(viewModel.comments.first?.id == 22)
        #expect(viewModel.isPostLoading == false)
        #expect(viewModel.error == nil)
    }

    @Test("Show thumbnails responds to settings notifications")
    @MainActor
    func showThumbnailsSyncsWithSettings() async throws {
        let settingsUseCase = StubSettingsUseCase(showThumbnails: false)
        let viewModel = CommentsViewModel(
            post: testPost,
            postUseCase: mockPostUseCase,
            commentUseCase: mockCommentUseCase,
            voteUseCase: mockVoteUseCase,
            settingsUseCase: settingsUseCase
        )

        #expect(viewModel.showThumbnails == false)

        settingsUseCase.showThumbnails = true
        try await Task.sleep(nanoseconds: 10_000_000)

        #expect(viewModel.showThumbnails == true)
    }

    // MARK: - Voting Tests

    @Test("Upvoting post updates state correctly", arguments: [
        (initial: false, upvote: true, expectedUpvoted: true, expectedScoreDelta: 1)
    ])
    @MainActor
    func voteOnPost(initial: Bool, upvote: Bool, expectedUpvoted: Bool, expectedScoreDelta: Int) async throws {
        // Given
        guard var post = sut.post else {
            #expect(false, "Expected post to be available during voteOnPost test")
            return
        }
        post.upvoted = initial
        let initialScore = post.score
        sut.post = post

        // When
        try await sut.voteOnPost(upvote: upvote)

        // Then
        #expect(sut.post?.upvoted == expectedUpvoted)
        #expect(sut.post?.score == initialScore + expectedScoreDelta)
        #expect(mockVoteUseCase.upvotePostCalled)
    }

    @Test("Failed vote on post reverts changes")
    @MainActor
    func voteOnPostFailureRevertsChanges() async {
        // Given
        mockVoteUseCase.shouldThrowError = true
        guard let initialPost = sut.post else {
            #expect(false, "Expected post to be available during voteOnPostFailureRevertsChanges test")
            return
        }
        let initialUpvoted = initialPost.upvoted
        let initialScore = initialPost.score

        // When & Then
        await #expect(throws: MockError.self) {
            try await sut.voteOnPost(upvote: true)
        }

        #expect(sut.post?.upvoted == initialUpvoted)
        #expect(sut.post?.score == initialScore)
    }

    @Test("Upvoting comment updates state", arguments: [false])
    @MainActor
    func voteOnComment(initialUpvoted: Bool) async throws {
        // Given
        let comment = createTestComment(id: 1, upvoted: initialUpvoted)
        let expectedUpvoted = true
        mockVoteUseCase.upvoteCommentCalled = false

        // When
        try await sut.voteOnComment(comment, upvote: expectedUpvoted)

        // Then
        #expect(comment.upvoted == expectedUpvoted)
        #expect(mockVoteUseCase.upvoteCommentCalled)
    }

    @Test("Vote failure on comment reverts optimistic state")
    @MainActor
    func voteOnCommentFailureReverts() async {
        mockVoteUseCase.shouldThrowError = true
        let comment = createTestComment(id: 9, upvoted: false)
        mockVoteUseCase.upvoteCommentCalled = false

        await #expect(throws: MockError.self) {
            try await sut.voteOnComment(comment, upvote: true)
        }

        #expect(comment.upvoted == false)
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
            mockPostUseCase = MockPostUseCase()
            mockCommentUseCase = MockCommentUseCase()
            mockVoteUseCase = MockVoteUseCase()

            testPost = Post(
                id: 1,
                url: URL(string: "https://example.com")!,
                title: "Test",
                age: "1h",
                commentsCount: 0,
                by: "user",
                score: 0,
                postType: .news,
                upvoted: false,
            )

            sut = CommentsViewModel(
                post: testPost,
                postUseCase: mockPostUseCase,
                commentUseCase: mockCommentUseCase,
                voteUseCase: mockVoteUseCase,
            )
        }

        private func createTestComment(id: Int, level: Int = 0) -> Domain.Comment {
            Domain.Comment(
                id: id,
                age: "1 hour ago",
                text: "Test comment \(id)",
                by: "user\(id)",
                level: level,
                upvoted: false,
                visibility: Domain.CommentVisibilityType.visible,
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
            let collapsedRoot = sut.hideCommentBranch(loadedChild2)

            // Then
            let loadedRoot = sut.comments.first(where: { $0.id == 1 })!
            let loadedChild1 = sut.comments.first(where: { $0.id == 2 })!

            #expect(collapsedRoot === loadedRoot)
            #expect(loadedRoot.visibility == Domain.CommentVisibilityType.compact)
            #expect(loadedChild1.visibility == Domain.CommentVisibilityType.hidden)
            #expect(loadedChild2.visibility == Domain.CommentVisibilityType.hidden)
            #expect(sut.visibleComments.count == 1)
        }

        @Test("Reveal comment shows hidden ancestors")
        @MainActor
        func revealCommentUnhidesAncestors() async {
            // Given - Comment chain with collapsed ancestors
            let rootComment = createTestComment(id: 1, level: 0)
            let childComment = createTestComment(id: 2, level: 1)
            let grandchildComment = createTestComment(id: 3, level: 2)

            rootComment.visibility = .compact
            childComment.visibility = .hidden
            grandchildComment.visibility = .hidden

            let post = createPostWithComments(comments: [rootComment, childComment, grandchildComment])
            mockPostUseCase.mockPost = post

            await sut.loadComments()

            // When
            let revealed = sut.revealComment(withId: 3)

            // Then
            #expect(revealed)
            let loadedRoot = sut.comments.first(where: { $0.id == 1 })!
            let loadedChild = sut.comments.first(where: { $0.id == 2 })!
            let loadedGrandchild = sut.comments.first(where: { $0.id == 3 })!

            #expect(loadedRoot.visibility == .visible)
            #expect(loadedChild.visibility == .visible)
            #expect(loadedGrandchild.visibility == .visible)
            #expect(sut.visibleComments.contains(where: { $0.id == 3 }))
        }
    }

    // MARK: - Helper Methods

    private func createTestComments() -> [Domain.Comment] {
        [
            createTestComment(id: 1, level: 0),
            createTestComment(id: 2, level: 1),
            createTestComment(id: 3, level: 1),
            createTestComment(id: 4, level: 2),
            createTestComment(id: 5, level: 0),
        ]
    }

    private func createTestComment(id: Int, level: Int = 0, upvoted: Bool = false) -> Domain.Comment {
        Domain.Comment(
            id: id,
            age: "1 hour ago",
            text: "Test comment \(id)",
            by: "user\(id)",
            level: level,
            upvoted: upvoted,
            visibility: Domain.CommentVisibilityType.visible,
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
    var postQueue: [Post] = []

    func getPost(id: Int) async throws -> Post {
        getPostCallCount += 1
        if shouldDelay {
            try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        }
        if shouldThrowError {
            throw MockError.testError
        }
        if !postQueue.isEmpty {
            return postQueue.removeFirst()
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
            upvoted: false,
        )
    }

    func getPosts(type _: PostType, page _: Int, nextId _: Int?) async throws -> [Post] {
        []
    }
}

final class MockCommentUseCase: CommentUseCase, @unchecked Sendable {
    func getComments(for _: Post) async throws -> [Domain.Comment] {
        []
    }
}

final class MockVoteUseCase: VoteUseCase, @unchecked Sendable {
    var upvotePostCalled = false
    var upvoteCommentCalled = false
    var shouldThrowError = false

    func upvote(post _: Post) async throws {
        upvotePostCalled = true
        if shouldThrowError {
            throw MockError.testError
        }
    }

    func upvote(comment _: Domain.Comment, for _: Post) async throws {
        upvoteCommentCalled = true
        if shouldThrowError {
            throw MockError.testError
        }
    }
}

final class StubSettingsUseCase: SettingsUseCase, @unchecked Sendable {
    var safariReaderMode: Bool = false
    var openInDefaultBrowser: Bool = false
    private var storedShowThumbnails: Bool
    var textSize: TextSize = .medium

    init(showThumbnails: Bool) {
        storedShowThumbnails = showThumbnails
    }

    var showThumbnails: Bool {
        get { storedShowThumbnails }
        set {
            storedShowThumbnails = newValue
            NotificationCenter.default.post(name: UserDefaults.didChangeNotification, object: nil)
        }
    }

    func clearCache() {}

    func cacheUsageBytes() async -> Int64 { 0 }
}

enum MockError: Error {
    case testError
}

// Helper function to create test comment outside of struct
private func createTestComment(id: Int, level: Int = 0, upvoted: Bool = false) -> Domain.Comment {
    Domain.Comment(
        id: id,
        age: "1 hour ago",
        text: "Test comment \(id)",
        by: "user\(id)",
        level: level,
        upvoted: upvoted,
        visibility: .visible,
    )
}
