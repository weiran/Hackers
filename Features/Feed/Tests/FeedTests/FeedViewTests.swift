//
//  FeedViewTests.swift
//  FeedTests
//
//  Copyright © 2025 Weiran Zhang. All rights reserved.
//

@testable import Domain
@testable import Feed
@testable import Shared
import SwiftUI
import Testing

@Suite("FeedView Tests")
struct FeedViewTests {
    // Mock Navigation Store
    @MainActor
    final class MockNavigationStore: @MainActor NavigationStoreProtocol, @unchecked Sendable {
        var selectedPost: Post?
        var selectedPostId: Int?
        var showingLogin: Bool = false
        var showingSettings: Bool = false
        var showPostCalled = false
        var showLoginCalled = false
        var showSettingsCalled = false
        var selectedPostType: PostType?

        func showPost(_ post: Post) {
            showPostCalled = true
            selectedPostId = post.id
        }

        func showPostLink(_ post: Post) {
            selectedPostId = post.id
        }

        func showPost(withId id: Int) {
            selectedPostId = id
        }

        func showLogin() {
            showLoginCalled = true
        }

        func showSettings() {
            showSettingsCalled = true
        }

        func selectPostType(_ type: PostType) {
            selectedPostType = type
        }

        @MainActor
        func openURLInPrimaryContext(_: URL, pushOntoDetailStack _: Bool) -> Bool { false }
    }

    // Mock Use Cases
    final class MockPostUseCase: PostUseCase, @unchecked Sendable {
        private var _mockPosts: [Post] = []
        var mockPosts: [Post] {
            get { _mockPosts }
            set { _mockPosts = newValue }
        }

        var getPostsCalled = false
        var lastRequestedType: PostType?
        var lastRequestedPage: Int?

        func getPosts(type: PostType, page: Int, nextId _: Int?) async throws -> [Post] {
            getPostsCalled = true
            lastRequestedType = type
            lastRequestedPage = page
            return mockPosts
        }

        func getPost(id: Int) async throws -> Post {
            if let existing = mockPosts.first(where: { $0.id == id }) {
                return existing
            }
            return Post(
                id: id,
                url: URL(string: "https://example.com")!,
                title: "Test",
                age: "1h",
                commentsCount: 0,
                by: "test",
                score: 0,
                postType: .news,
                upvoted: false,
            )
        }
    }

    final class MockVoteUseCase: VoteUseCase, @unchecked Sendable {
        private var _upvoteCalled = false
        private var _shouldThrowError = false

        var upvoteCalled: Bool {
            get { _upvoteCalled }
            set { _upvoteCalled = newValue }
        }

        var shouldThrowError: Bool {
            get { _shouldThrowError }
            set { _shouldThrowError = newValue }
        }

        func upvote(post _: Post) async throws {
            if shouldThrowError {
                throw HackersKitError.unauthenticated
            }
            upvoteCalled = true
            // Mock implementation - in real app this would be handled by the repository
        }

        func upvote(comment _: Domain.Comment, for _: Post) async throws {
            // Not used in feed
        }

        func unvote(post _: Post) async throws {}

        func unvote(comment _: Domain.Comment, for _: Post) async throws {}
    }

    final class MockBookmarksUseCase: BookmarksUseCase, @unchecked Sendable {
        var storedPosts: [Post] = []
        var toggleCalls: [Int] = []

        func bookmarkedIDs() async -> Set<Int> {
            Set(storedPosts.map(\.id))
        }

        func bookmarkedPosts() async -> [Post] {
            storedPosts
        }

        @discardableResult
        func toggleBookmark(post: Post) async throws -> Bool {
            toggleCalls.append(post.id)
            if let index = storedPosts.firstIndex(where: { $0.id == post.id }) {
                storedPosts.remove(at: index)
                return false
            } else {
                var newPost = post
                newPost.isBookmarked = true
                storedPosts.append(newPost)
                return true
            }
        }
    }

    final class MockSearchUseCase: SearchUseCase, @unchecked Sendable {
        var lastQuery: String?
        var results: [Post] = []

        func searchPosts(query: String) async throws -> [Post] {
            lastQuery = query
            return results
        }
    }

    private func createMockPost(id: Int, upvoted: Bool = false) -> Post {
        Post(
            id: id,
            url: URL(string: "https://example.com/\(id)")!,
            title: "Test Post \(id)",
            age: "1 hour ago",
            commentsCount: 10,
            by: "testuser",
            score: 100,
            postType: .news,
            upvoted: upvoted,
        )
    }

    @Test("FeedViewModel loads posts successfully")
    @MainActor
    func loadPosts() async throws {
        // Arrange
        let mockPostUseCase = MockPostUseCase()
        let mockVoteUseCase = MockVoteUseCase()
        let mockBookmarksUseCase = MockBookmarksUseCase()
        let mockSearchUseCase = MockSearchUseCase()
        mockPostUseCase.mockPosts = [
            createMockPost(id: 1),
            createMockPost(id: 2),
            createMockPost(id: 3),
        ]
        let bookmarksController = BookmarksController(bookmarksUseCase: mockBookmarksUseCase)

        let viewModel = FeedViewModel(
            postUseCase: mockPostUseCase,
            voteUseCase: MockVoteUseCase(),
            bookmarksController: bookmarksController,
            searchUseCase: mockSearchUseCase
        )

        // Act
        await viewModel.loadFeed()

        // Assert
        #expect(viewModel.posts.count == 3)
        #expect(viewModel.posts[0].id == 1)
        #expect(viewModel.posts[1].id == 2)
        #expect(viewModel.posts[2].id == 3)
        #expect(mockPostUseCase.getPostsCalled == true)
        #expect(viewModel.isLoading == false)
    }

    @Test("FeedViewModel handles pagination")
    @MainActor
    func pagination() async throws {
        // Arrange
        let mockPostUseCase = MockPostUseCase()
        let mockVoteUseCase = MockVoteUseCase()
        let mockBookmarksUseCase = MockBookmarksUseCase()
        let mockSearchUseCase = MockSearchUseCase()
        mockPostUseCase.mockPosts = [
            createMockPost(id: 1),
            createMockPost(id: 2),
        ]
        let bookmarksController = BookmarksController(bookmarksUseCase: mockBookmarksUseCase)

        let viewModel = FeedViewModel(
            postUseCase: mockPostUseCase,
            voteUseCase: MockVoteUseCase(),
            bookmarksController: bookmarksController,
            searchUseCase: mockSearchUseCase
        )

        // Act - Load first page
        await viewModel.loadFeed()
        #expect(viewModel.posts.count == 2)

        // Update mock data for second page
        mockPostUseCase.mockPosts = [
            createMockPost(id: 3),
            createMockPost(id: 4),
        ]

        // Act - Load next page
        await viewModel.loadNextPage()

        // Assert
        #expect(viewModel.posts.count == 4)
        #expect(viewModel.posts[2].id == 3)
        #expect(viewModel.posts[3].id == 4)
        #expect(mockPostUseCase.lastRequestedPage == 2)
    }

    @Test("FeedViewModel handles voting")
    @MainActor
    func voting() async throws {
        // Arrange
        let mockPostUseCase = MockPostUseCase()
        let mockVoteUseCase = MockVoteUseCase()
        let mockBookmarksUseCase = MockBookmarksUseCase()
        let mockSearchUseCase = MockSearchUseCase()
        let post = createMockPost(id: 1, upvoted: false)
        mockPostUseCase.mockPosts = [post]
        let bookmarksController = BookmarksController(bookmarksUseCase: mockBookmarksUseCase)

        let viewModel = FeedViewModel(
            postUseCase: mockPostUseCase,
            voteUseCase: mockVoteUseCase,
            bookmarksController: bookmarksController,
            searchUseCase: mockSearchUseCase
        )

        await viewModel.loadFeed()

        // Act - Upvote
        try await viewModel.vote(on: viewModel.posts[0], upvote: true)

        // Assert
        #expect(mockVoteUseCase.upvoteCalled == true)
        // Unvote removed; no-op when upvote == false
    }

    @Test("FeedViewModel handles post type changes")
    @MainActor
    func postTypeChange() async throws {
        // Arrange
        let mockPostUseCase = MockPostUseCase()
        let mockVoteUseCase = MockVoteUseCase()
        let mockBookmarksUseCase = MockBookmarksUseCase()
        let mockSearchUseCase = MockSearchUseCase()
        mockPostUseCase.mockPosts = [createMockPost(id: 1)]
        let bookmarksController = BookmarksController(bookmarksUseCase: mockBookmarksUseCase)

        let viewModel = FeedViewModel(
            postUseCase: mockPostUseCase,
            voteUseCase: MockVoteUseCase(),
            bookmarksController: bookmarksController,
            searchUseCase: mockSearchUseCase
        )

        // Act
        await viewModel.changePostType(Domain.PostType.ask)

        // Assert
        #expect(viewModel.postType == Domain.PostType.ask)
        #expect(mockPostUseCase.lastRequestedType == Domain.PostType.ask)
        #expect(mockPostUseCase.getPostsCalled == true)
    }

    @Test("FeedViewModel filters duplicate posts")
    @MainActor
    func duplicateFiltering() async throws {
        // Arrange
        let mockPostUseCase = MockPostUseCase()
        let mockVoteUseCase = MockVoteUseCase()
        let mockBookmarksUseCase = MockBookmarksUseCase()
        let mockSearchUseCase = MockSearchUseCase()
        mockPostUseCase.mockPosts = [
            createMockPost(id: 1),
            createMockPost(id: 2),
            createMockPost(id: 1), // Duplicate
        ]
        let bookmarksController = BookmarksController(bookmarksUseCase: mockBookmarksUseCase)

        let viewModel = FeedViewModel(
            postUseCase: mockPostUseCase,
            voteUseCase: mockVoteUseCase,
            bookmarksController: bookmarksController,
            searchUseCase: mockSearchUseCase
        )

        // Act
        await viewModel.loadFeed()

        // Assert
        #expect(viewModel.posts.count == 2) // Should filter out duplicate
        #expect(Set(viewModel.posts.map(\.id)).count == 2)
    }
}
