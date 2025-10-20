//
//  BookmarksRepositoryTests.swift
//  DataTests
//

@testable import Data
import Domain
import Foundation
import Testing

@Suite("BookmarksRepository")
struct BookmarksRepositoryTests {
    private let samplePost = Post(
        id: 42,
        url: URL(string: "https://example.com/42")!,
        title: "Example Post",
        age: "2 hours ago",
        commentsCount: 5,
        by: "tester",
        score: 100,
        postType: .news,
        upvoted: false,
        voteLinks: VoteLinks(
            upvote: URL(string: "https://news.ycombinator.com/upvote?id=42"),
            unvote: URL(string: "https://news.ycombinator.com/unvote?id=42")
        )
    )

    @Test("Toggle bookmark adds and removes posts")
    mutating func toggleBookmarkAddsAndRemoves() async throws {
        let store = MockUbiquitousKeyValueStore()
        let repository = BookmarksRepository(store: store, now: { Date(timeIntervalSince1970: 1234) })

        let didBookmark = try await repository.toggleBookmark(post: samplePost)
        #expect(didBookmark == true)

        var ids = await repository.bookmarkedIDs()
        #expect(ids == [samplePost.id])

        let didRemove = try await repository.toggleBookmark(post: samplePost)
        #expect(didRemove == false)

        ids = await repository.bookmarkedIDs()
        #expect(ids.isEmpty)
    }

    @Test("Bookmarked posts round-trip stored fields")
    mutating func bookmarkedPostsRoundTrip() async throws {
        let store = MockUbiquitousKeyValueStore()
        let repository = BookmarksRepository(store: store, now: { Date(timeIntervalSince1970: 5678) })

        _ = try await repository.toggleBookmark(post: samplePost)
        var bookmarkedPosts = await repository.bookmarkedPosts()
        #expect(bookmarkedPosts.count == 1)
        var post = bookmarkedPosts[0]
        #expect(post.isBookmarked == true)
        #expect(post.title == samplePost.title)
        #expect(post.voteLinks?.upvote == samplePost.voteLinks?.upvote)

        // Add another bookmark with older timestamp to ensure ordering by recency
        let olderPost = Post(
            id: 7,
            url: URL(string: "https://example.com/7")!,
            title: "Older Post",
            age: "3 hours ago",
            commentsCount: 2,
            by: "tester2",
            score: 50,
            postType: .ask,
            upvoted: false
        )

        let olderRepository = BookmarksRepository(store: store, now: { Date(timeIntervalSince1970: 1000) })
        _ = try await olderRepository.toggleBookmark(post: olderPost)

        bookmarkedPosts = await repository.bookmarkedPosts()
        #expect(bookmarkedPosts.count == 2)
        post = bookmarkedPosts.first!
        #expect(post.id == samplePost.id) // Most recent first
    }
}

private final class MockUbiquitousKeyValueStore: UbiquitousKeyValueStoreProtocol, @unchecked Sendable {
    private var storage: [String: Any] = [:]

    func data(forKey defaultName: String) -> Data? {
        storage[defaultName] as? Data
    }

    func set(_ value: Any?, forKey defaultName: String) {
        storage[defaultName] = value
    }

    func synchronize() -> Bool { true }
}
