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
        // Vote links are intentionally not persisted (their `auth` token is a credential
        // and expires), so they should round-trip as nil.
        #expect(post.voteLinks == nil)

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

    @Test("Bookmarks never persist vote-auth credentials")
    mutating func bookmarksDoNotPersistVoteAuth() async throws {
        let store = MockUbiquitousKeyValueStore()
        let repository = BookmarksRepository(store: store, now: { Date(timeIntervalSince1970: 5678) })

        // A post whose vote URLs carry a per-session `auth` credential.
        let postWithAuth = Post(
            id: 100,
            url: URL(string: "https://example.com/100")!,
            title: "Secret Vote Post",
            age: "1 hour ago",
            commentsCount: 0,
            by: "tester",
            score: 1,
            postType: .news,
            upvoted: false,
            voteLinks: VoteLinks(
                upvote: URL(string: "https://news.ycombinator.com/vote?id=100&how=up&auth=SECRET_TOKEN&goto=news"),
                unvote: URL(string: "https://news.ycombinator.com/vote?id=100&how=un&auth=SECRET_TOKEN&goto=news")
            )
        )

        _ = try await repository.toggleBookmark(post: postWithAuth)

        // The persisted payload must not contain the auth credential.
        let storedData = try #require(store.data(forKey: "Bookmarks.posts"))
        let storedJSON = try #require(String(data: storedData, encoding: .utf8))
        #expect(!storedJSON.contains("auth"), "Persisted bookmark must not contain vote-auth tokens")
        #expect(!storedJSON.contains("SECRET_TOKEN"), "Persisted bookmark must not contain the auth secret")
        #expect(!storedJSON.contains("voteLinks"), "Persisted bookmark must not store vote links")

        // And the reloaded post exposes no vote links.
        let reloaded = await repository.bookmarkedPosts()
        #expect(reloaded.first?.voteLinks == nil)
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
