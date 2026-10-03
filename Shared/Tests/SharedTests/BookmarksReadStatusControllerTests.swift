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

@Suite("BookmarksController", .serialized)
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


    @Test("Toggle adds/removes from cache and posts change notification")
    func toggleUpdatesCacheAndNotifies() async {
        let useCase = StubBookmarksUseCase(ids: [])
        let controller = BookmarksController(bookmarksUseCase: useCase)

        let received = MainActorBookmarkNotificationRecorder()
        let observer = NotificationCenter.default.addObserver(
            forName: .bookmarksDidChange, object: nil, queue: .main
        ) { note in
            let postID = note.userInfo?["postId"] as? Int
            let isBookmarked = note.userInfo?["isBookmarked"] as? Bool
            MainActor.assumeIsolated { received.record(postID: postID, isBookmarked: isBookmarked) }
        }
        defer { NotificationCenter.default.removeObserver(observer) }

        let didBookmark = await controller.toggle(post: makePost(id: 7))
        #expect(didBookmark)
        #expect(controller.isBookmarked(7))
        #expect(received.postID == 7)
        #expect(received.isBookmarked == true)

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

    @Test("A stale bookmarked-posts fetch preserves unaffected posts after a concurrent removal")
    func staleBookmarkedPostsReconcilesConcurrentRemoval() async {
        let useCase = GatedBookmarkedPostsUseCase(ids: [1, 2])
        let controller = BookmarksController(bookmarksUseCase: useCase)

        let postsTask = Task { await controller.bookmarkedPosts() }
        await useCase.waitUntilPostsFetchStarted()

        let didRemove = await controller.toggle(post: makePost(id: 1))
        #expect(!didRemove)

        await useCase.releasePostsFetch()
        let posts = await postsTask.value

        #expect(posts.map(\.id) == [2])
        #expect(!controller.isBookmarked(1))
        #expect(controller.isBookmarked(2))
    }

    @Test("A stale bookmarked-posts fetch includes a concurrent addition")
    func staleBookmarkedPostsReconcilesConcurrentAddition() async {
        let useCase = GatedBookmarkedPostsUseCase(ids: [1, 2])
        let controller = BookmarksController(bookmarksUseCase: useCase)

        let postsTask = Task { await controller.bookmarkedPosts() }
        await useCase.waitUntilPostsFetchStarted()

        let didAdd = await controller.toggle(post: makePost(id: 3))
        #expect(didAdd)

        await useCase.releasePostsFetch()
        let posts = await postsTask.value

        #expect(Set(posts.map(\.id)) == [1, 2, 3])
        #expect(posts.allSatisfy { $0.isBookmarked })
    }

    @Test("A bookmarked-posts fetch waits for an active mutation before applying its snapshot")
    func bookmarkedPostsWaitsForActiveMutation() async {
        let useCase = GatedBookmarkedPostsUseCase(ids: [1, 2])
        let controller = BookmarksController(bookmarksUseCase: useCase)
        await useCase.enableToggleGating()

        let postsTask = Task { await controller.bookmarkedPosts() }
        await useCase.waitUntilPostsFetchStarted()
        let toggleTask = Task { await controller.toggle(post: makePost(id: 1)) }
        await useCase.waitUntilToggleStarted()

        await useCase.releasePostsFetch()
        await useCase.releaseToggle(returning: false)
        let didRemove = await toggleTask.value
        let posts = await postsTask.value

        #expect(!didRemove)
        #expect(posts.map(\.id) == [2])
    }

    @Test("A failed concurrent bookmark mutation does not discard a fetched snapshot")
    func staleBookmarkedPostsReconcilesFailedMutation() async {
        let useCase = GatedBookmarkedPostsUseCase(ids: [1], shouldThrowOnToggle: true)
        let controller = BookmarksController(bookmarksUseCase: useCase)

        let postsTask = Task { await controller.bookmarkedPosts() }
        await useCase.waitUntilPostsFetchStarted()

        let result = await controller.toggle(post: makePost(id: 1))
        #expect(!result)

        await useCase.releasePostsFetch()
        let posts = await postsTask.value

        #expect(posts.map(\.id) == [1])
        #expect(controller.isBookmarked(1))
    }

    @Test("A refresh started during a failed toggle cannot overwrite cached fallback state")
    func failedToggleInvalidatesOverlappingRefresh() async {
        let useCase = ToggleAndRefreshGate(ids: [1])
        let controller = BookmarksController(bookmarksUseCase: useCase)
        _ = await controller.refreshBookmarks()
        await useCase.enableRefreshGating()

        let toggleTask = Task { await controller.toggle(post: makePost(id: 1)) }
        await useCase.waitUntilToggleStarted()

        let refreshTask = Task { await controller.refreshBookmarks() }
        await useCase.waitUntilRefreshStarted()

        await useCase.releaseToggleFailure()
        let toggleResult = await toggleTask.value
        #expect(toggleResult)

        await useCase.releaseRefresh(with: [])
        _ = await refreshTask.value
        #expect(controller.isBookmarked(1))
    }

    @Test("A stale bookmark refresh cannot overwrite a newer toggle")
    func staleRefreshCannotOverwriteToggle() async {
        let useCase = GatedBookmarksUseCase(ids: [])
        let controller = BookmarksController(bookmarksUseCase: useCase)

        let refreshTask = Task { await controller.refreshBookmarks() }
        await useCase.waitUntilRefreshStarted()

        let didBookmark = await controller.toggle(post: makePost(id: 7))
        #expect(didBookmark)
        #expect(controller.isBookmarked(7))

        await useCase.releaseRefresh()
        let staleResult = await refreshTask.value

        #expect(staleResult == [7])
        #expect(controller.isBookmarked(7))
    }

    @Test("External bookmark changes refresh cache and notify only when state changes")
    func externalBookmarkChangesRefreshAndNotify() async {
        let useCase = MutableBookmarksUseCase(ids: [1])
        let notificationCenter = NotificationCenter()
        let controller = BookmarksController(bookmarksUseCase: useCase, notificationCenter: notificationCenter)
        _ = await controller.refreshBookmarks()

        let notifications = MainActorNotificationRecorder()
        let observer = notificationCenter.addObserver(
            forName: .bookmarksDidChange,
            object: nil,
            queue: .main
        ) { _ in MainActor.assumeIsolated { notifications.record() } }
        defer { notificationCenter.removeObserver(observer) }

        await useCase.setIDs([1, 2])
        notificationCenter.post(
            name: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: NSUbiquitousKeyValueStore.default
        )
        await useCase.waitUntilReadCount(2)
        await notifications.waitForCount(1)
        let changedReadCount = await useCase.currentReadCount()
        #expect(changedReadCount == 2)
        guard changedReadCount == 2 else { return }
        #expect(notifications.count == 1)

        #expect(controller.isBookmarked(2))

        notificationCenter.post(
            name: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: NSUbiquitousKeyValueStore.default
        )
        await useCase.waitUntilReadCount(3)
        let unchangedReadCount = await useCase.currentReadCount()
        #expect(unchangedReadCount == 3)
        guard unchangedReadCount == 3 else { return }
        #expect(notifications.count == 1)
    }

    @Test("Overlapping external bookmark notifications emit one generic change")
    func overlappingExternalBookmarkNotificationsAreDeduplicated() async {
        let useCase = SequencedBookmarksUseCase(ids: [1])
        let notificationCenter = NotificationCenter()
        let controller = BookmarksController(bookmarksUseCase: useCase, notificationCenter: notificationCenter)
        _ = await controller.refreshBookmarks()
        await useCase.enableGating()

        let recorder = MainActorNotificationRecorder()
        let observer = notificationCenter.addObserver(
            forName: .bookmarksDidChange,
            object: nil,
            queue: .main
        ) { _ in MainActor.assumeIsolated { recorder.record() } }
        defer { notificationCenter.removeObserver(observer) }

        await useCase.setIDs([1, 2])
        postExternalChange(on: notificationCenter)
        await useCase.waitUntilReadCount(2)
        postExternalChange(on: notificationCenter)

        await useCase.releaseNext()
        await useCase.waitUntilReadCount(3)
        await useCase.releaseNext()
        await recorder.waitForCount(1)

        #expect(recorder.count == 1)
        #expect(controller.isBookmarked(2))
    }

    @Test("An external bookmark refresh invalidated by a local toggle retries current state")
    func invalidatedExternalBookmarkRefreshRetries() async {
        let useCase = SequencedBookmarksUseCase(ids: [1])
        let notificationCenter = NotificationCenter()
        let controller = BookmarksController(bookmarksUseCase: useCase, notificationCenter: notificationCenter)
        _ = await controller.refreshBookmarks()
        await useCase.enableGating()

        let recorder = MainActorNotificationRecorder()
        let observer = notificationCenter.addObserver(
            forName: .bookmarksDidChange,
            object: nil,
            queue: .main
        ) { note in
            let isGeneric = note.userInfo == nil
            MainActor.assumeIsolated { recorder.record(isGeneric: isGeneric) }
        }
        defer { notificationCenter.removeObserver(observer) }

        await useCase.setIDs([1, 2])
        postExternalChange(on: notificationCenter)
        await useCase.waitUntilReadCount(2)

        let didAdd = await controller.toggle(post: makePost(id: 3))
        #expect(didAdd)
        await useCase.releaseNext()
        await useCase.waitUntilReadCount(3)
        await useCase.releaseNext()
        await recorder.waitForCount(1)

        #expect(controller.isBookmarked(2))
        #expect(controller.isBookmarked(3))
        #expect(recorder.count == 1)
    }
}

@Suite("ReadStatusController", .serialized)
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


    @Test("markRead inserts into cache and posts change notification")
    func markReadUpdatesCacheAndNotifies() async {
        let useCase = StubReadStatusUseCase(ids: [])
        let controller = ReadStatusController(readStatusUseCase: useCase)

        let received = MainActorReadStatusNotificationRecorder()
        let observer = NotificationCenter.default.addObserver(
            forName: .readStatusDidChange, object: nil, queue: .main
        ) { note in
            let postID = note.userInfo?["postId"] as? Int
            MainActor.assumeIsolated { received.record(postID: postID) }
        }
        defer { NotificationCenter.default.removeObserver(observer) }

        await controller.markRead(postID: 33)
        #expect(controller.isRead(33))
        #expect(received.postID == 33)
        #expect(useCase.markedIDs == [33], "Underlying use case should persist the read id")
    }

    @Test("A stale read-status refresh cannot overwrite a newer mark")
    func staleRefreshCannotOverwriteMark() async {
        let useCase = GatedReadStatusUseCase(ids: [])
        let controller = ReadStatusController(readStatusUseCase: useCase)

        let refreshTask = Task { await controller.refreshReadStatus() }
        await useCase.waitUntilRefreshStarted()

        await controller.markRead(postID: 33)
        #expect(controller.isRead(33))

        await useCase.releaseRefresh()
        let staleResult = await refreshTask.value

        #expect(staleResult == [33])
        #expect(controller.isRead(33))
    }

    @Test("Overlapping external read-status notifications emit one generic change")
    func overlappingExternalReadStatusNotificationsAreDeduplicated() async {
        let useCase = SequencedReadStatusUseCase(ids: [1])
        let notificationCenter = NotificationCenter()
        let controller = ReadStatusController(readStatusUseCase: useCase, notificationCenter: notificationCenter)
        _ = await controller.refreshReadStatus()
        await useCase.enableGating()

        let recorder = MainActorNotificationRecorder()
        let observer = notificationCenter.addObserver(
            forName: .readStatusDidChange,
            object: nil,
            queue: .main
        ) { _ in MainActor.assumeIsolated { recorder.record() } }
        defer { notificationCenter.removeObserver(observer) }

        await useCase.setIDs([1, 2])
        postExternalChange(on: notificationCenter)
        await useCase.waitUntilReadCount(2)
        postExternalChange(on: notificationCenter)

        await useCase.releaseNext()
        await useCase.waitUntilReadCount(3)
        await useCase.releaseNext()
        await recorder.waitForCount(1)

        #expect(recorder.count == 1)
        #expect(controller.isRead(2))
    }

    @Test("An external read-status refresh invalidated by a local mark retries current state")
    func invalidatedExternalReadStatusRefreshRetries() async {
        let useCase = SequencedReadStatusUseCase(ids: [1])
        let notificationCenter = NotificationCenter()
        let controller = ReadStatusController(readStatusUseCase: useCase, notificationCenter: notificationCenter)
        _ = await controller.refreshReadStatus()
        await useCase.enableGating()

        let recorder = MainActorNotificationRecorder()
        let observer = notificationCenter.addObserver(
            forName: .readStatusDidChange,
            object: nil,
            queue: .main
        ) { note in
            let isGeneric = note.userInfo == nil
            MainActor.assumeIsolated { recorder.record(isGeneric: isGeneric) }
        }
        defer { notificationCenter.removeObserver(observer) }

        await useCase.setIDs([1, 2])
        postExternalChange(on: notificationCenter)
        await useCase.waitUntilReadCount(2)

        await controller.markRead(postID: 3)
        await useCase.releaseNext()
        await useCase.waitUntilReadCount(3)
        await useCase.releaseNext()
        await recorder.waitForCount(1)

        #expect(controller.isRead(2))
        #expect(controller.isRead(3))
        #expect(recorder.count == 1)
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

private actor GatedBookmarksUseCase: BookmarksUseCase {
    private var ids: Set<Int>
    private var refreshStarted = false
    private var hasGatedRefresh = false
    private var refreshStartWaiter: CheckedContinuation<Void, Never>?
    private var pendingRefresh: (snapshot: Set<Int>, continuation: CheckedContinuation<Set<Int>, Never>)?

    init(ids: Set<Int>) {
        self.ids = ids
    }

    func bookmarkedIDs() async -> Set<Int> {
        refreshStarted = true
        refreshStartWaiter?.resume()
        refreshStartWaiter = nil
        guard !hasGatedRefresh else { return ids }
        hasGatedRefresh = true
        let snapshot = ids
        return await withCheckedContinuation { continuation in
            pendingRefresh = (snapshot, continuation)
        }
    }

    func bookmarkedPosts() async -> [Post] {
        ids.map { makePost(id: $0) }
    }

    func toggleBookmark(post: Post) async throws -> Bool {
        if ids.contains(post.id) {
            ids.remove(post.id)
            return false
        }
        ids.insert(post.id)
        return true
    }

    func waitUntilRefreshStarted() async {
        if refreshStarted { return }
        await withCheckedContinuation { continuation in
            refreshStartWaiter = continuation
        }
    }

    func releaseRefresh() {
        let continuation = pendingRefresh?.continuation
        let snapshot = pendingRefresh?.snapshot ?? []
        pendingRefresh = nil
        continuation?.resume(returning: snapshot)
    }
}

private actor MutableBookmarksUseCase: BookmarksUseCase {
    private var ids: Set<Int>
    private var readCount = 0
    private var readWaiters: [(target: Int, continuation: CheckedContinuation<Void, Never>)] = []

    init(ids: Set<Int>) {
        self.ids = ids
    }

    func bookmarkedIDs() async -> Set<Int> {
        readCount += 1
        let waiters = readWaiters.filter { readCount >= $0.target }
        readWaiters.removeAll { readCount >= $0.target }
        waiters.forEach { $0.continuation.resume() }
        return ids
    }

    func bookmarkedPosts() async -> [Post] {
        ids.map { makePost(id: $0) }
    }

    func toggleBookmark(post: Post) async throws -> Bool {
        if ids.contains(post.id) {
            ids.remove(post.id)
            return false
        }
        ids.insert(post.id)
        return true
    }

    func setIDs(_ ids: Set<Int>) {
        self.ids = ids
    }

    func currentReadCount() -> Int { readCount }

    func waitUntilReadCount(_ target: Int) async {
        if readCount >= target { return }
        await withCheckedContinuation { continuation in
            readWaiters.append((target, continuation))
        }
    }
}

private actor GatedReadStatusUseCase: ReadStatusUseCase {
    private var ids: Set<Int>
    private var refreshStarted = false
    private var hasGatedRefresh = false
    private var refreshStartWaiter: CheckedContinuation<Void, Never>?
    private var pendingRefresh: (snapshot: Set<Int>, continuation: CheckedContinuation<Set<Int>, Never>)?

    init(ids: Set<Int>) {
        self.ids = ids
    }

    func readPostIDs() async -> Set<Int> {
        refreshStarted = true
        refreshStartWaiter?.resume()
        refreshStartWaiter = nil
        guard !hasGatedRefresh else { return ids }
        hasGatedRefresh = true
        let snapshot = ids
        return await withCheckedContinuation { continuation in
            pendingRefresh = (snapshot, continuation)
        }
    }

    func markPostRead(id: Int) async {
        ids.insert(id)
    }

    func waitUntilRefreshStarted() async {
        if refreshStarted { return }
        await withCheckedContinuation { continuation in
            refreshStartWaiter = continuation
        }
    }

    func releaseRefresh() {
        let continuation = pendingRefresh?.continuation
        let snapshot = pendingRefresh?.snapshot ?? []
        pendingRefresh = nil
        continuation?.resume(returning: snapshot)
    }
}

@MainActor
private final class MainActorNotificationRecorder {
    private(set) var count = 0
    private var waiters: [(target: Int, continuation: CheckedContinuation<Void, Never>)] = []

    func record() {
        record(isGeneric: true)
    }

    func record(isGeneric: Bool = true) {
        guard isGeneric else { return }
        count += 1
        let ready = waiters.filter { count >= $0.target }
        waiters.removeAll { count >= $0.target }
        ready.forEach { $0.continuation.resume() }
    }

    func waitForCount(_ target: Int) async {
        if count >= target { return }
        await withCheckedContinuation { continuation in
            waiters.append((target, continuation))
        }
    }
}

@MainActor
private final class MainActorBookmarkNotificationRecorder {
    private(set) var postID: Int?
    private(set) var isBookmarked: Bool?

    func record(postID: Int?, isBookmarked: Bool?) {
        self.postID = postID
        self.isBookmarked = isBookmarked
    }
}

@MainActor
private final class MainActorReadStatusNotificationRecorder {
    private(set) var postID: Int?

    func record(postID: Int?) {
        self.postID = postID
    }
}

private func postExternalChange(on notificationCenter: NotificationCenter) {
    notificationCenter.post(
        name: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
        object: NSUbiquitousKeyValueStore.default
    )
}

extension BookmarksControllerTests {
    @Test("A suspended external read does not retain the bookmark controller")
    func externalReadDoesNotRetainController() async {
        let useCase = SequencedBookmarksUseCase(ids: [1])
        let center = NotificationCenter()
        var controller: BookmarksController? = BookmarksController(bookmarksUseCase: useCase, notificationCenter: center)
        _ = await controller?.refreshBookmarks()
        await useCase.enableGating()
        postExternalChange(on: center)
        await useCase.waitUntilReadCount(2)
        weak var releasedController = controller
        controller = nil
        #expect(releasedController == nil)
        await useCase.releaseNext()
    }
}

extension ReadStatusControllerTests {
    @Test("A suspended external read does not retain the read-status controller")
    func externalReadDoesNotRetainController() async {
        let useCase = SequencedReadStatusUseCase(ids: [1])
        let center = NotificationCenter()
        var controller: ReadStatusController? = ReadStatusController(readStatusUseCase: useCase, notificationCenter: center)
        _ = await controller?.refreshReadStatus()
        await useCase.enableGating()
        postExternalChange(on: center)
        await useCase.waitUntilReadCount(2)
        weak var releasedController = controller
        controller = nil
        #expect(releasedController == nil)
        await useCase.releaseNext()
    }
}

private actor GatedBookmarkedPostsUseCase: BookmarksUseCase {
    private var ids: Set<Int>
    private let shouldThrowOnToggle: Bool
    private var shouldGateToggle = false
    private var postsFetchStarted = false
    private var toggleStarted = false
    private var postsFetchWaiter: CheckedContinuation<Void, Never>?
    private var toggleWaiter: CheckedContinuation<Void, Never>?
    private var pendingPosts: (snapshot: [Post], continuation: CheckedContinuation<[Post], Never>)?
    private var toggleContinuation: CheckedContinuation<Bool, Never>?

    init(ids: Set<Int>, shouldThrowOnToggle: Bool = false) {
        self.ids = ids
        self.shouldThrowOnToggle = shouldThrowOnToggle
    }

    func bookmarkedIDs() async -> Set<Int> {
        ids
    }

    func bookmarkedPosts() async -> [Post] {
        postsFetchStarted = true
        postsFetchWaiter?.resume()
        postsFetchWaiter = nil
        let snapshot = ids.sorted().map(makePost)
        return await withCheckedContinuation { continuation in
            pendingPosts = (snapshot, continuation)
        }
    }

    func toggleBookmark(post: Post) async throws -> Bool {
        if shouldThrowOnToggle { throw StubError.failure }
        if shouldGateToggle {
            toggleStarted = true
            toggleWaiter?.resume()
            toggleWaiter = nil
            let result = await withCheckedContinuation { continuation in
                toggleContinuation = continuation
            }
            if result { ids.insert(post.id) } else { ids.remove(post.id) }
            return result
        }
        if ids.contains(post.id) {
            ids.remove(post.id)
            return false
        }
        ids.insert(post.id)
        return true
    }

    func waitUntilPostsFetchStarted() async {
        if postsFetchStarted { return }
        await withCheckedContinuation { continuation in
            postsFetchWaiter = continuation
        }
    }

    func enableToggleGating() {
        shouldGateToggle = true
    }

    func waitUntilToggleStarted() async {
        if toggleStarted { return }
        await withCheckedContinuation { continuation in
            toggleWaiter = continuation
        }
    }

    func releaseToggle(returning result: Bool) {
        toggleContinuation?.resume(returning: result)
        toggleContinuation = nil
    }

    func releasePostsFetch() {
        let pending = pendingPosts
        pendingPosts = nil
        pending?.continuation.resume(returning: pending?.snapshot ?? [])
    }
}

private actor ToggleAndRefreshGate: BookmarksUseCase {
    private var ids: Set<Int>
    private var shouldGateRefresh = false
    private var toggleStarted = false
    private var refreshStarted = false
    private var toggleWaiter: CheckedContinuation<Void, Never>?
    private var refreshWaiter: CheckedContinuation<Void, Never>?
    private var toggleContinuation: CheckedContinuation<Bool, Never>?
    private var refreshContinuation: CheckedContinuation<Set<Int>, Never>?

    init(ids: Set<Int>) {
        self.ids = ids
    }

    func bookmarkedIDs() async -> Set<Int> {
        guard shouldGateRefresh else { return ids }
        refreshStarted = true
        refreshWaiter?.resume()
        refreshWaiter = nil
        return await withCheckedContinuation { continuation in
            refreshContinuation = continuation
        }
    }

    func bookmarkedPosts() async -> [Post] {
        ids.sorted().map(makePost)
    }

    func toggleBookmark(post _: Post) async throws -> Bool {
        toggleStarted = true
        toggleWaiter?.resume()
        toggleWaiter = nil
        let succeeded = await withCheckedContinuation { continuation in
            toggleContinuation = continuation
        }
        if succeeded { return true }
        throw StubError.failure
    }

    func waitUntilToggleStarted() async {
        if toggleStarted { return }
        await withCheckedContinuation { continuation in
            toggleWaiter = continuation
        }
    }

    func enableRefreshGating() {
        shouldGateRefresh = true
    }

    func waitUntilRefreshStarted() async {
        if refreshStarted { return }
        await withCheckedContinuation { continuation in
            refreshWaiter = continuation
        }
    }

    func releaseToggleFailure() {
        toggleContinuation?.resume(returning: false)
        toggleContinuation = nil
    }

    func releaseRefresh(with ids: Set<Int>) {
        refreshContinuation?.resume(returning: ids)
        refreshContinuation = nil
    }
}

private actor SequencedBookmarksUseCase: BookmarksUseCase {
    private var ids: Set<Int>
    private var gated = false
    private var readCount = 0
    private var readWaiters: [(target: Int, continuation: CheckedContinuation<Void, Never>)] = []
    private var pending: [(snapshot: Set<Int>, continuation: CheckedContinuation<Set<Int>, Never>)] = []

    init(ids: Set<Int>) {
        self.ids = ids
    }

    func bookmarkedIDs() async -> Set<Int> {
        readCount += 1
        let waiters = readWaiters.filter { readCount >= $0.target }
        readWaiters.removeAll { readCount >= $0.target }
        waiters.forEach { $0.continuation.resume() }
        guard gated else { return ids }
        let snapshot = ids
        return await withCheckedContinuation { continuation in
            pending.append((snapshot, continuation))
        }
    }

    func bookmarkedPosts() async -> [Post] {
        ids.sorted().map(makePost)
    }

    func toggleBookmark(post: Post) async throws -> Bool {
        if ids.contains(post.id) {
            ids.remove(post.id)
            return false
        }
        ids.insert(post.id)
        return true
    }

    func enableGating() {
        gated = true
    }

    func setIDs(_ ids: Set<Int>) {
        self.ids = ids
    }

    func waitUntilReadCount(_ target: Int) async {
        if readCount >= target { return }
        await withCheckedContinuation { continuation in
            readWaiters.append((target, continuation))
        }
    }

    func releaseNext() {
        guard !pending.isEmpty else { return }
        let next = pending.removeFirst()
        next.continuation.resume(returning: next.snapshot)
    }
}

private actor SequencedReadStatusUseCase: ReadStatusUseCase {
    private var ids: Set<Int>
    private var gated = false
    private var readCount = 0
    private var readWaiters: [(target: Int, continuation: CheckedContinuation<Void, Never>)] = []
    private var pending: [(snapshot: Set<Int>, continuation: CheckedContinuation<Set<Int>, Never>)] = []

    init(ids: Set<Int>) {
        self.ids = ids
    }

    func readPostIDs() async -> Set<Int> {
        readCount += 1
        let waiters = readWaiters.filter { readCount >= $0.target }
        readWaiters.removeAll { readCount >= $0.target }
        waiters.forEach { $0.continuation.resume() }
        guard gated else { return ids }
        let snapshot = ids
        return await withCheckedContinuation { continuation in
            pending.append((snapshot, continuation))
        }
    }

    func markPostRead(id: Int) async {
        ids.insert(id)
    }

    func enableGating() {
        gated = true
    }

    func setIDs(_ ids: Set<Int>) {
        self.ids = ids
    }

    func waitUntilReadCount(_ target: Int) async {
        if readCount >= target { return }
        await withCheckedContinuation { continuation in
            readWaiters.append((target, continuation))
        }
    }

    func releaseNext() {
        guard !pending.isEmpty else { return }
        let next = pending.removeFirst()
        next.continuation.resume(returning: next.snapshot)
    }
}
