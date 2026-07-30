//
//  BookmarksRepository.swift
//  Data
//
//  Provides an iCloud-synchronised implementation of the bookmarks use case.
//

import Domain
import Foundation

public protocol UbiquitousKeyValueStoreProtocol: AnyObject, Sendable {
    func data(forKey defaultName: String) -> Data?
    func set(_ value: Any?, forKey defaultName: String)
    func synchronize() -> Bool
}

extension NSUbiquitousKeyValueStore: UbiquitousKeyValueStoreProtocol {}

public final class BookmarksRepository: BookmarksUseCase, @unchecked Sendable {
    private enum Constants {
        static let bookmarksKey = "Bookmarks.posts"
    }

    private let store: UbiquitousKeyValueStoreProtocol
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private let now: () -> Date

    public init(
        store: UbiquitousKeyValueStoreProtocol = NSUbiquitousKeyValueStore.default,
        now: @escaping () -> Date = Date.init
    ) {
        self.store = store
        self.now = now

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        self.encoder = encoder

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder
    }

    public func bookmarkedIDs() async -> Set<Int> {
        let entries = loadEntries()
        return Set(entries.map(\.id))
    }

    public func bookmarkedPosts() async -> [Post] {
        loadEntries().map { $0.makePost() }
    }

    @discardableResult
    public func toggleBookmark(post: Post) async throws -> Bool {
        var entries = loadEntries()

        if let index = entries.firstIndex(where: { $0.id == post.id }) {
            entries.remove(at: index)
            try persist(entries)
            return false
        } else {
            let entry = BookmarkEntry(post: post, bookmarkedAt: now())
            entries.append(entry)
            entries.sort { $0.bookmarkedAt > $1.bookmarkedAt }
            try persist(entries)
            return true
        }
    }
}

private extension BookmarksRepository {
    func loadEntries() -> [BookmarkEntry] {
        _ = store.synchronize()
        guard let data = store.data(forKey: Constants.bookmarksKey) else {
            return []
        }

        guard let entries = try? decoder.decode([BookmarkEntry].self, from: data) else {
            return []
        }

        return entries.sorted { $0.bookmarkedAt > $1.bookmarkedAt }
    }

    func persist(_ entries: [BookmarkEntry]) throws {
        let data = try encoder.encode(entries)
        store.set(data, forKey: Constants.bookmarksKey)
        _ = store.synchronize()
    }
}

private struct BookmarkEntry: Codable, Sendable {
    let id: Int
    let url: URL
    let title: String
    let age: String
    let commentsCount: Int
    let by: String
    let score: Int
    let postTypeRawValue: String
    let upvoted: Bool
    let text: String?
    let bookmarkedAt: Date

    init(post: Post, bookmarkedAt: Date) {
        id = post.id
        url = post.url
        title = post.title
        age = post.age
        commentsCount = post.commentsCount
        by = post.by
        score = post.score
        postTypeRawValue = post.postType.rawValue
        upvoted = post.upvoted
        // Deliberately do not persist voteLinks: their `auth` query parameter is a
        // per-session credential, and storing it would leak it to iCloud. They also
        // expire, so voting on a bookmark re-resolves fresh links when the post is
        // loaded from the Hacker News feed. (Old entries that still carry a voteLinks
        // key in iCloud decode fine — Codable ignores unknown keys.)
        text = post.text
        self.bookmarkedAt = bookmarkedAt
    }

    func makePost() -> Post {
        let postType = PostType(rawValue: postTypeRawValue) ?? .news
        return Post(
            id: id,
            url: url,
            title: title,
            age: age,
            commentsCount: commentsCount,
            by: by,
            score: score,
            postType: postType,
            upvoted: upvoted,
            isBookmarked: true,
            voteLinks: nil,
            text: text
        )
    }
}
