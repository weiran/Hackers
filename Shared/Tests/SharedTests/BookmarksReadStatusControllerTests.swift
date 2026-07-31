//
//  BookmarksReadStatusControllerTests.swift
//  SharedTests
//
//  Focused coverage for BookmarksController and ReadStatusController, which previously
//  had only incidental coverage through the feed/comments view-model tests.
//

@testable import Shared
import Domain
import Foundation
import Testing

@Suite("BookmarksController")
@MainActor
struct BookmarksControllerTests {
    @Test("Refresh caches bookmark IDs and annotates posts")
    func refreshCachesAndAnnotates() async {
        let useCase = StubBookmarksUseCase(ids: [1, 2])
        let controller = BookmarksController(bookmarksUseCase: useCase)

        let ids = await controller.refreshBookmarks()
        #expect(ids == [1, 2])

        let posts = [makePost(id: 1), makePost(id: 3)]
        let annotated = controller.annotatedPosts(from: posts)
        #expect(annotated[0].isBookmarked)
        #expect(!annotated[1].isBookmarked)
    }

    @Test("isBookmarked reflects the cached set")
    func isBookmarkedReflectsCache() async {
        let controller = BookmarksController(bookmarksUseCase: StubBookmarksUseCase(ids: [42]))
        _ = await controller.refreshBookmarks()
        #expect(controller.isBookmarked(42))
        #expect(!controller.isBookmarked(99))
    }

    @Test("Toggle adds/removes from cache and posts change notification")
    func toggleUpdatesCacheAndNotifies() async {
        let useCase = StubBookmarksUseCase(ids: [])
        let controller = BookmarksController(bookmarksUseCase: useCase)

        var received: (id: Int, bookmarked: Bool)?
        let observer = NotificationCenter.default.addObserver(
            forName: .bookmarksDidChange, object: nil, queue: .main
        ) { note in
            guard let id = note.userInfo?["postId"] as? Int,
                  let bookmarked = note.userInfo?["isBookmarked"] as? Bool else { return }
            received = (id, bookmarked)
        }
        defer { NotificationCenter.default.removeObserver(observer) }

        let didBookmark = await controller.toggle(post: makePost(id: 7))
        #expect(didBookmark)
        #expect(controller.isBookmarked(7))
        #expect(received?.id == 7)
        #expect(received?.bookmarked == true)

        let didRemove = await controller.toggle(post: makePost(id: 7))
        #expect(!didRemove)
        #expect(!controller.isBookmarked(7))
    }

    @Test("Toggle error falls back to existing cached state")
    func toggleErrorFallsBackToCache() async {
        let useCase = StubBookmarksUseCase(ids: [5], shouldThrowOnToggle: true)
        let controller = BookmarksController(bookmarksUseCase: useCase)
        _ = await controller.refreshBookmarks()

        // Already bookmarked; toggle throws, so the controller reports the cached state.
        let result = await controller.toggle(post: makePost(id: 5))
        #expect(result == true, "Should report cached bookmarked state when toggle throws")
        #expect(controller.isBookmarked(5))
    }

    @Test("bookmarkedPosts marks every returned post as bookmarked")
    func bookmarkedPostsAreAnnotated() async {
        let useCase = StubBookmarksUseCase(ids: [1, 2])
        let controller = BookmarksController(bookmarksUseCase: useCase)

        let posts = await controller.bookmarkedPosts()
        #expect(posts.count == 2)
        #expect(posts.map(\.isBookmarked) == [true, true])
    }
}

@Suite("ReadStatusController")
@MainActor
struct ReadStatusControllerTests {
    @Test("Refresh caches read IDs and annotates posts")
    func refreshCachesAndAnnotates() async {
        let useCase = StubReadStatusUseCase(ids: [10, 20])
        let controller = ReadStatusController(readStatusUseCase: useCase)

        let ids = await controller.refreshReadStatus()
        #expect(ids == [10, 20])

        let annotated = controller.annotatedPosts(from: [makePost(id: 10), makePost(id: 30)])
        #expect(annotated[0].isRead)
        #expect(!annotated[1].isRead)
    }

    @Test("isRead reflects the cached set")
    func isReadReflectsCache() async {
        let controller = ReadStatusController(readStatusUseCase: StubReadStatusUseCase(ids: [8]))
        _ = await controller.refreshReadStatus()
        #expect(controller.isRead(8))
        #expect(!controller.isRead(9))
    }

    @Test("markRead inserts into cache and posts change notification")
    func markReadUpdatesCacheAndNotifies() async {
        let useCase = StubReadStatusUseCase(ids: [])
        let controller = ReadStatusController(readStatusUseCase: useCase)

        var receivedID: Int?
        let observer = NotificationCenter.default.addObserver(
            forName: .readStatusDidChange, object: nil, queue: .main
        ) { note in
            receivedID = note.userInfo?["postId"] as? Int
        }
        defer { NotificationCenter.default.removeObserver(observer) }

        await controller.markRead(postID: 33)
        #expect(controller.isRead(33))
        #expect(receivedID == 33)
        #expect(useCase.markedIDs == [33], "Underlying use case should persist the read id")
    }
}

// MARK: - Helpers

private func makePost(id: Int) -> Post {
    Post(
        id: id,
        url: URL(string: "https://example.com/\(id)")!,
        title: "Post \(id)",
        age: "1h",
        commentsCount: 0,
        by: "user",
        score: 1,
        postType: .news,
        upvoted: false
    )
}

private final class StubBookmarksUseCase: BookmarksUseCase, @unchecked Sendable {
    private var ids: Set<Int>
    let shouldThrowOnToggle: Bool

    init(ids: Set<Int>, shouldThrowOnToggle: Bool = false) {
        self.ids = ids
        self.shouldThrowOnToggle = shouldThrowOnToggle
    }

    func bookmarkedIDs() async -> Set<Int> { ids }

    func bookmarkedPosts() async -> [Post] {
        ids.map { makePost(id: $0) }
    }

    @discardableResult
    func toggleBookmark(post: Post) async throws -> Bool {
        if shouldThrowOnToggle { throw StubError.failure }
        if ids.contains(post.id) {
            ids.remove(post.id)
            return false
        } else {
            ids.insert(post.id)
            return true
        }
    }
}

private final class StubReadStatusUseCase: ReadStatusUseCase, @unchecked Sendable {
    private var ids: Set<Int>
    private(set) var markedIDs: Set<Int> = []

    init(ids: Set<Int>) {
        self.ids = ids
    }

    func readPostIDs() async -> Set<Int> { ids }

    func markPostRead(id: Int) async {
        ids.insert(id)
        markedIDs.insert(id)
    }
}

private enum StubError: Error {
    case failure
}
