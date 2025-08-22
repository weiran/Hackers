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
        // Given
        sut.isLoading = true
        mockPostUseCase.getPostCallCount = 0
        
        // When
        await sut.loadComments()
        
        // Then
        #expect(mockPostUseCase.getPostCallCount == 0)
    }
    
    // MARK: - Voting Tests
    
    @Test("Upvoting post updates state correctly", arguments: [
        (initial: false, upvote: true, expectedUpvoted: true, expectedScoreDelta: 1),
        (initial: true, upvote: false, expectedUpvoted: false, expectedScoreDelta: -1)
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
        if upvote {
            #expect(mockVoteUseCase.upvotePostCalled)
        } else {
            #expect(mockVoteUseCase.unvotePostCalled)
        }
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
    
    @Test("Voting on comment updates state", arguments: [false, true])
    @MainActor
    func voteOnComment(initialUpvoted: Bool) async throws {
        // Given
        let comment = createTestComment(id: 1, upvoted: initialUpvoted)
        let expectedUpvoted = !initialUpvoted
        
        // When
        try await sut.voteOnComment(comment, upvote: expectedUpvoted)
        
        // Then
        #expect(comment.upvoted == expectedUpvoted)
        if expectedUpvoted {
            #expect(mockVoteUseCase.upvoteCommentCalled)
        } else {
            #expect(mockVoteUseCase.unvoteCommentCalled)
        }
    }
    
    // MARK: - Comment Visibility Tests
    
    @Suite("Comment Visibility")
    struct CommentVisibilityTests {
        let sut: CommentsViewModel
        
        init() {
            self.sut = CommentsViewModel(
                post: Post(
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
        
        @Test("Toggle comment from visible to compact hides children")
        @MainActor
        func toggleVisibleToCompact() {
            // Given
            let parentComment = createTestComment(id: 1, level: 0)
            let childComment = createTestComment(id: 2, level: 1)
            sut.comments = [parentComment, childComment]
            // Set initial visibility
            parentComment.visibility = Domain.CommentVisibilityType.visible
            childComment.visibility = Domain.CommentVisibilityType.visible
            sut.visibleComments = sut.comments
            
            #expect(parentComment.visibility == Domain.CommentVisibilityType.visible)
            #expect(childComment.visibility == Domain.CommentVisibilityType.visible)
            
            // When
            sut.toggleCommentVisibility(parentComment)
            
            // Then
            #expect(parentComment.visibility == Domain.CommentVisibilityType.compact)
            #expect(childComment.visibility == Domain.CommentVisibilityType.hidden)
            #expect(sut.visibleComments.count == 1)
        }
        
        @Test("Toggle comment from compact to visible shows children")
        @MainActor
        func toggleCompactToVisible() {
            // Given
            let parentComment = createTestComment(id: 1, level: 0)
            parentComment.visibility = Domain.CommentVisibilityType.compact
            let childComment = createTestComment(id: 2, level: 1)
            childComment.visibility = Domain.CommentVisibilityType.hidden
            sut.comments = [parentComment, childComment]
            sut.visibleComments = sut.comments
            
            // When
            sut.toggleCommentVisibility(parentComment)
            
            // Then
            #expect(parentComment.visibility == Domain.CommentVisibilityType.visible)
            #expect(childComment.visibility == Domain.CommentVisibilityType.visible)
            #expect(sut.visibleComments.count == 2)
        }
        
        @Test("Hide comment branch collapses entire tree")
        @MainActor
        func hideCommentBranch() {
            // Given
            let rootComment = createTestComment(id: 1, level: 0)
            let childComment1 = createTestComment(id: 2, level: 1)
            let childComment2 = createTestComment(id: 3, level: 2)
            sut.comments = [rootComment, childComment1, childComment2]
            sut.visibleComments = sut.comments
            
            // When
            sut.hideCommentBranch(childComment2)
            
            // Then
            #expect(rootComment.visibility == Domain.CommentVisibilityType.compact)
            #expect(childComment1.visibility == Domain.CommentVisibilityType.hidden)
            #expect(childComment2.visibility == Domain.CommentVisibilityType.hidden)
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
        post.comments = comments
        return post
    }
}

// MARK: - Mock Classes

final class MockPostUseCase: PostUseCase, @unchecked Sendable {
    var mockPost: Post?
    var shouldThrowError = false
    var getPostCallCount = 0
    
    func getPost(id: Int) async throws -> Post {
        getPostCallCount += 1
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
    var unvotePostCalled = false
    var upvoteCommentCalled = false
    var unvoteCommentCalled = false
    var shouldThrowError = false
    
    func upvote(post: Post) async throws {
        upvotePostCalled = true
        if shouldThrowError {
            throw MockError.testError
        }
    }
    
    func unvote(post: Post) async throws {
        unvotePostCalled = true
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
    
    func unvote(comment: Domain.Comment, for post: Post) async throws {
        unvoteCommentCalled = true
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