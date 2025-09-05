//
//  UseCaseTests.swift
//  DomainTests
//
//  Copyright © 2025 Weiran Zhang. All rights reserved.
//

// swiftlint:disable force_cast

import Testing
import Foundation
@testable import Domain

@Suite("Domain Use Cases Tests")
struct UseCaseTests {

    // MARK: - Mock Implementations for Testing

    @MainActor
    final class MockPostUseCase: PostUseCase {
        var getPostsCallCount = 0
        var getPostCallCount = 0
        var stubPosts: [Post] = []
        var stubPost: Post?

        func getPosts(type: PostType, page: Int, nextId: Int?) async throws -> [Post] {
            getPostsCallCount += 1
            return stubPosts
        }

        func getPost(id: Int) async throws -> Post {
            getPostCallCount += 1
            guard let post = stubPost else {
                throw HackersKitError.requestFailure
            }
            return post
        }
    }

    @MainActor
    final class MockVoteUseCase: VoteUseCase {
        var upvotePostCallCount = 0
        var unvotePostCallCount = 0
        var upvoteCommentCallCount = 0
        var unvoteCommentCallCount = 0

        func upvote(post: Post) async throws {
            upvotePostCallCount += 1
        }

        func unvote(post: Post) async throws {
            unvotePostCallCount += 1
        }

        func upvote(comment: Comment, for post: Post) async throws {
            upvoteCommentCallCount += 1
        }

        func unvote(comment: Comment, for post: Post) async throws {
            unvoteCommentCallCount += 1
        }
    }

    @MainActor
    final class MockCommentUseCase: CommentUseCase {
        var getCommentsCallCount = 0
        var stubComments: [Comment] = []

        func getComments(for post: Post) async throws -> [Comment] {
            getCommentsCallCount += 1
            return stubComments
        }
    }

    final class MockSettingsUseCase: SettingsUseCase, @unchecked Sendable {
        private var _safariReaderMode = false
        private var _showThumbnails = true
        private var _swipeActions = true
        private var _showComments = true
        private var _openInDefaultBrowser = false

        var safariReaderMode: Bool {
            get { _safariReaderMode }
            set { _safariReaderMode = newValue }
        }

        var showThumbnails: Bool {
            get { _showThumbnails }
            set { _showThumbnails = newValue }
        }

        var swipeActions: Bool {
            get { _swipeActions }
            set { _swipeActions = newValue }
        }

        var showComments: Bool {
            get { _showComments }
            set { _showComments = newValue }
        }

        var openInDefaultBrowser: Bool {
            get { _openInDefaultBrowser }
            set { _openInDefaultBrowser = newValue }
        }
    }

    // MARK: - PostUseCase Tests

    @MainActor
    @Test("PostUseCase getPosts functionality")
    func postUseCaseGetPosts() async throws {
        let mockUseCase = MockPostUseCase()
        let testPost = Self.createTestPost()
        mockUseCase.stubPosts = [testPost]

        let posts = try await mockUseCase.getPosts(type: .news, page: 1, nextId: nil)

        #expect(mockUseCase.getPostsCallCount == 1)
        #expect(posts.count == 1)
        #expect(posts.first?.id == testPost.id)
    }

    @MainActor
    @Test("PostUseCase getPost functionality")
    func postUseCaseGetPost() async throws {
        let mockUseCase = MockPostUseCase()
        let testPost = Self.createTestPost()
        mockUseCase.stubPost = testPost

        let post = try await mockUseCase.getPost(id: 123)

        #expect(mockUseCase.getPostCallCount == 1)
        #expect(post.id == testPost.id)
    }

    @MainActor
    @Test("PostUseCase getPost error handling")
    func postUseCaseGetPostError() async {
        let mockUseCase = MockPostUseCase()
        mockUseCase.stubPost = nil

        do {
            _ = try await mockUseCase.getPost(id: 123)
            Issue.record("Expected error to be thrown")
        } catch {
            #expect(error is HackersKitError)
        }
    }

    // MARK: - VoteUseCase Tests

    @MainActor
    @Test("VoteUseCase upvote post functionality")
    func voteUseCaseUpvotePost() async throws {
        let mockUseCase = MockVoteUseCase()
        let testPost = Self.createTestPost()

        try await mockUseCase.upvote(post: testPost)

        #expect(mockUseCase.upvotePostCallCount == 1)
    }

    @MainActor
    @Test("VoteUseCase unvote post functionality")
    func voteUseCaseUnvotePost() async throws {
        let mockUseCase = MockVoteUseCase()
        let testPost = Self.createTestPost()

        try await mockUseCase.unvote(post: testPost)

        #expect(mockUseCase.unvotePostCallCount == 1)
    }

    @MainActor
    @Test("VoteUseCase upvote comment functionality")
    func voteUseCaseUpvoteComment() async throws {
        let mockUseCase = MockVoteUseCase()
        let testPost = Self.createTestPost()
        let testComment = Self.createTestComment()

        try await mockUseCase.upvote(comment: testComment, for: testPost)

        #expect(mockUseCase.upvoteCommentCallCount == 1)
    }

    @MainActor
    @Test("VoteUseCase unvote comment functionality")
    func voteUseCaseUnvoteComment() async throws {
        let mockUseCase = MockVoteUseCase()
        let testPost = Self.createTestPost()
        let testComment = Self.createTestComment()

        try await mockUseCase.unvote(comment: testComment, for: testPost)

        #expect(mockUseCase.unvoteCommentCallCount == 1)
    }

    // MARK: - CommentUseCase Tests

    @MainActor
    @Test("CommentUseCase getComments functionality")
    func commentUseCaseGetComments() async throws {
        let mockUseCase = MockCommentUseCase()
        let testPost = Self.createTestPost()
        let testComment = Self.createTestComment()
        mockUseCase.stubComments = [testComment]

        let comments = try await mockUseCase.getComments(for: testPost)

        #expect(mockUseCase.getCommentsCallCount == 1)
        #expect(comments.count == 1)
        #expect(comments.first?.id == testComment.id)
    }

    // MARK: - SettingsUseCase Tests

    @Test("SettingsUseCase getters and setters")
    func settingsUseCaseGettersAndSetters() {
        let mockUseCase = MockSettingsUseCase()

        // Test initial values
        #expect(mockUseCase.safariReaderMode == false)
        #expect(mockUseCase.showThumbnails == true)
        #expect(mockUseCase.swipeActions == true)
        #expect(mockUseCase.showComments == true)
        #expect(mockUseCase.openInDefaultBrowser == false)

        // Test setters
        mockUseCase.safariReaderMode = true
        mockUseCase.showThumbnails = false
        mockUseCase.swipeActions = false
        mockUseCase.showComments = false
        mockUseCase.openInDefaultBrowser = true

        // Verify changes
        #expect(mockUseCase.safariReaderMode == true)
        #expect(mockUseCase.showThumbnails == false)
        #expect(mockUseCase.swipeActions == false)
        #expect(mockUseCase.showComments == false)
        #expect(mockUseCase.openInDefaultBrowser == true)
    }

    // MARK: - Helper Methods

    private static func createTestPost() -> Post {
        return Post(
            id: 123,
            url: URL(string: "https://example.com/post")!,
            title: "Test Post",
            age: "2 hours ago",
            commentsCount: 5,
            by: "testuser",
            score: 10,
            postType: .news,
            upvoted: false
        )
    }

    private static func createTestComment() -> Comment {
        return Comment(
            id: 456,
            age: "1 hour ago",
            text: "Test comment",
            by: "commenter",
            level: 0,
            upvoted: false
        )
    }
}
