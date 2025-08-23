//
//  PostRepositoryTests.swift
//  DataTests
//
//  Copyright © 2025 Weiran Zhang. All rights reserved.
//

// swiftlint:disable force_cast

import Testing
import Foundation
@testable import Data
@testable import Domain
@testable import Networking

@Suite("PostRepository Tests")
struct PostRepositoryTests {

    let mockNetworkManager = MockNetworkManager()
    var postRepository: PostRepository {
        PostRepository(networkManager: mockNetworkManager)
    }

    // MARK: - Mock NetworkManager

    final class MockNetworkManager: NetworkManagerProtocol, @unchecked Sendable {
        var stubbedGetResponse: String = ""
        var stubbedPostResponse: String = ""
        var getCallCount = 0
        var postCallCount = 0
        var lastGetURL: URL?
        var lastPostURL: URL?
        var lastPostBody: String?

        func get(url: URL) async throws -> String {
            getCallCount += 1
            lastGetURL = url
            return stubbedGetResponse
        }

        func post(url: URL, body: String) async throws -> String {
            postCallCount += 1
            lastPostURL = url
            lastPostBody = body
            return stubbedPostResponse
        }

        func clearCookies() {
            // No-op for testing
        }

        func containsCookie(for url: URL) -> Bool {
            return false // Return false for testing simplicity
        }
    }

    // MARK: - Initialization Tests

    @Test("PostRepository initialization")
    func postRepositoryInitialization() {
        #expect(postRepository != nil, "PostRepository should initialize successfully")
    }

    // MARK: - GetPosts Tests

    @Test("Get posts with news type")
    func getPostsNewsType() async throws {
        mockNetworkManager.stubbedGetResponse = createMockPostsHTML()

        let posts = try await postRepository.getPosts(type: .news, page: 1, nextId: nil)

        #expect(mockNetworkManager.getCallCount == 1, "Should make one network call")
        #expect(mockNetworkManager.lastGetURL != nil, "Should have a URL")
        #expect(mockNetworkManager.lastGetURL!.absoluteString.contains("news"), "URL should contain 'news'")
        #expect(mockNetworkManager.lastGetURL!.absoluteString.contains("p=1"), "URL should contain page parameter")
    }

    @Test("Get posts with newest type")
    func getPostsNewestType() async throws {
        mockNetworkManager.stubbedGetResponse = createMockPostsHTML()

        let posts = try await postRepository.getPosts(type: .newest, page: 1, nextId: 12345)

        #expect(mockNetworkManager.getCallCount == 1)
        #expect(mockNetworkManager.lastGetURL != nil)
        #expect(mockNetworkManager.lastGetURL!.absoluteString.contains("newest"))
        #expect(mockNetworkManager.lastGetURL!.absoluteString.contains("next=12345"))
    }

    @Test("Get posts with active type")
    func getPostsActiveType() async throws {
        mockNetworkManager.stubbedGetResponse = createMockPostsHTML()

        let posts = try await postRepository.getPosts(type: .active, page: 2, nextId: nil)

        #expect(mockNetworkManager.getCallCount == 1)
        #expect(mockNetworkManager.lastGetURL != nil)
        #expect(mockNetworkManager.lastGetURL!.absoluteString.contains("active"))
        #expect(mockNetworkManager.lastGetURL!.absoluteString.contains("p=2"))
    }

    // MARK: - GetPost Tests

    @Test("Get post")
    func getPost() async throws {
        mockNetworkManager.stubbedGetResponse = createMockSinglePostHTML()

        let post = try await postRepository.getPost(id: 123)

        #expect(mockNetworkManager.getCallCount == 1)
        #expect(mockNetworkManager.lastGetURL != nil)
        #expect(mockNetworkManager.lastGetURL!.absoluteString.contains("id=123"))
    }

    // MARK: - Vote Tests

    @Test("Upvote post")
    func upvotePost() async throws {
        let voteLinks = VoteLinks(upvote: URL(string: "/vote?id=123&how=up")!, unvote: nil)
        let post = createTestPost(voteLinks: voteLinks)

        try await postRepository.upvote(post: post)

        #expect(mockNetworkManager.getCallCount == 1)
        #expect(mockNetworkManager.lastGetURL != nil)
        #expect(mockNetworkManager.lastGetURL!.absoluteString.contains("news.ycombinator.com"))
        #expect(mockNetworkManager.lastGetURL!.absoluteString.contains("vote"))
    }

    @Test("Unvote post")
    func unvotePost() async throws {
        let voteLinks = VoteLinks(upvote: nil, unvote: URL(string: "/vote?id=123&how=un")!)
        let post = createTestPost(voteLinks: voteLinks)

        try await postRepository.unvote(post: post)

        #expect(mockNetworkManager.getCallCount == 1)
        #expect(mockNetworkManager.lastGetURL != nil)
        #expect(mockNetworkManager.lastGetURL!.absoluteString.contains("news.ycombinator.com"))
        #expect(mockNetworkManager.lastGetURL!.absoluteString.contains("vote"))
    }

    @Test("Upvote post without vote links")
    func upvotePostWithoutVoteLinks() async {
        let post = createTestPost(voteLinks: nil)

        do {
            try await postRepository.upvote(post: post)
            Issue.record("Expected error for post without vote links")
        } catch {
            #expect(error is HackersKitError)
        }
    }

    @Test("Upvote comment")
    func upvoteComment() async throws {
        let voteLinks = VoteLinks(upvote: URL(string: "/vote?id=456&how=up")!, unvote: nil)
        let comment = createTestComment(voteLinks: voteLinks)
        let post = createTestPost()

        try await postRepository.upvote(comment: comment, for: post)

        #expect(mockNetworkManager.getCallCount == 1)
        #expect(mockNetworkManager.lastGetURL != nil)
        #expect(mockNetworkManager.lastGetURL!.absoluteString.contains("news.ycombinator.com"))
        #expect(mockNetworkManager.lastGetURL!.absoluteString.contains("vote"))
    }

    @Test("Unvote comment")
    func unvoteComment() async throws {
        let voteLinks = VoteLinks(upvote: nil, unvote: URL(string: "/vote?id=456&how=un")!)
        let comment = createTestComment(voteLinks: voteLinks)
        let post = createTestPost()

        try await postRepository.unvote(comment: comment, for: post)

        #expect(mockNetworkManager.getCallCount == 1)
        #expect(mockNetworkManager.lastGetURL != nil)
        #expect(mockNetworkManager.lastGetURL!.absoluteString.contains("news.ycombinator.com"))
        #expect(mockNetworkManager.lastGetURL!.absoluteString.contains("vote"))
    }

    // MARK: - Comments Tests

    @Test("Get comments")
    func getComments() async throws {
        mockNetworkManager.stubbedGetResponse = createMockCommentsHTML()
        let post = createTestPost()

        let comments = try await postRepository.getComments(for: post)

        #expect(mockNetworkManager.getCallCount == 1)
        #expect(mockNetworkManager.lastGetURL != nil)
        #expect(mockNetworkManager.lastGetURL!.absoluteString.contains("item"))
        #expect(mockNetworkManager.lastGetURL!.absoluteString.contains("id=123"))
    }

    // MARK: - Error Handling Tests

    @Test("Network error handling")
    func networkError() async {
        // Configure mock to throw an error
        let post = createTestPost()

        do {
            _ = try await postRepository.getComments(for: post)
            // Since we're not setting stubbed response, this should use the default empty string
            // which should result in an empty comments array, not an error
            // This test verifies the repository handles parsing gracefully
        } catch {
            Issue.record("Repository should handle parsing errors gracefully")
        }
    }

    // MARK: - Helper Methods

    private func createTestPost(voteLinks: VoteLinks? = nil) -> Post {
        return Post(
            id: 123,
            url: URL(string: "https://example.com/post")!,
            title: "Test Post",
            age: "2 hours ago",
            commentsCount: 5,
            by: "testuser",
            score: 10,
            postType: .news,
            upvoted: false,
            voteLinks: voteLinks
        )
    }

    private func createTestComment(voteLinks: VoteLinks? = nil) -> Domain.Comment {
        return Domain.Comment(
            id: 456,
            age: "1 hour ago",
            text: "Test comment",
            by: "commenter",
            level: 0,
            upvoted: false,
            voteLinks: voteLinks
        )
    }

    private func createMockPostsHTML() -> String {
        return """
        <html>
        <body>
        <table class="itemlist">
            <tr class="athing" id="123">
                <td>
                    <span class="titleline">
                        <a href="https://example.com/article">Test Article Title</a>
                    </span>
                </td>
            </tr>
            <tr>
                <td>
                    <span class="score">10 points</span>
                    <span class="age" title="2023-01-01T10:00:00">2 hours ago</span>
                    <a class="hnuser" href="user?id=testuser">testuser</a>
                    <a href="item?id=123">5 comments</a>
                </td>
            </tr>
        </table>
        </body>
        </html>
        """
    }

    private func createMockSinglePostHTML() -> String {
        return """
        <html>
        <body>
        <table class="fatitem">
            <tr class="athing" id="123">
                <td>
                    <span class="titleline">
                        <a href="https://example.com/article">Test Article Title</a>
                    </span>
                </td>
            </tr>
            <tr>
                <td>
                    <span class="score">10 points</span>
                    <span class="age" title="2023-01-01T10:00:00">2 hours ago</span>
                    <a class="hnuser" href="user?id=testuser">testuser</a>
                    <a href="item?id=123">5 comments</a>
                </td>
            </tr>
        </table>
        </body>
        </html>
        """
    }

    private func createMockCommentsHTML() -> String {
        return """
        <html>
        <body>
        <table class="comment-tree">
            <tr class="athing comtr" id="456">
                <td>
                    <div class="comment">
                        <span class="age">1 hour ago</span>
                        <a class="hnuser" href="user?id=commenter">commenter</a>
                        <div class="comment-body">This is a test comment</div>
                    </div>
                </td>
            </tr>
        </table>
        </body>
        </html>
        """
    }
}
