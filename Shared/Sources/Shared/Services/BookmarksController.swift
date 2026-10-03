//
//  BookmarksController.swift
//  Shared
//
//  Centralises bookmark state management so Feed and Comments share logic.
//

import Domain
import Foundation

@MainActor
public final class BookmarksController {
    private struct MutationOutcome {
        let generation: Int
        let post: Post
        let isBookmarked: Bool
        let succeeded: Bool
        let hadCachedState: Bool
    }

    private let bookmarksUseCase: any BookmarksUseCase
    private let notificationCenter: NotificationCenter
    private var cachedIDs: Set<Int> = []
    private var hasCachedState = false
    private var mutationGeneration = 0
    private var activeMutationCount = 0
    private var mutationCompletionWaiters: [CheckedContinuation<Void, Never>] = []
    private var mutationOutcomes: [MutationOutcome] = []
    private var activeBookmarkedPosts: [Int: Int] = [:]
    private var externalChangesObserver: NSObjectProtocol?
    private var externalRefreshTask: Task<Void, Never>?
    private var externalRefreshPending = false

    public init(
        bookmarksUseCase: any BookmarksUseCase = DependencyContainer.shared.getBookmarksUseCase(),
        notificationCenter: NotificationCenter = .default
    ) {
        self.bookmarksUseCase = bookmarksUseCase
        self.notificationCenter = notificationCenter
        externalChangesObserver = notificationCenter.addObserver(
            forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: NSUbiquitousKeyValueStore.default,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            MainActor.assumeIsolated {
                self.scheduleExternalRefresh()
            }
        }
    }

    isolated deinit {
        externalRefreshTask?.cancel()
        if let externalChangesObserver {
            notificationCenter.removeObserver(externalChangesObserver)
        }
    }

    @discardableResult
    public func refreshBookmarks() async -> Set<Int> {
        let generation = mutationGeneration
        let ids = await bookmarksUseCase.bookmarkedIDs()
        guard generation == mutationGeneration, activeMutationCount == 0 else { return cachedIDs }
        cachedIDs = ids
        hasCachedState = true
        return ids
    }

    public func annotatedPosts(from posts: [Post]) -> [Post] {
        posts.map { post in
            var mutablePost = post
            mutablePost.isBookmarked = cachedIDs.contains(post.id)
            return mutablePost
        }
    }

    public func bookmarkedPosts() async -> [Post] {
        let generation = mutationGeneration
        activeBookmarkedPosts[generation, default: 0] += 1
        let posts = await bookmarksUseCase.bookmarkedPosts()
        await waitForActiveMutations()
        activeBookmarkedPosts[generation, default: 1] -= 1
        if activeBookmarkedPosts[generation] == 0 {
            activeBookmarkedPosts.removeValue(forKey: generation)
        }

        var reconciledPosts = posts
        let overlappingOutcomes = mutationOutcomes.filter { $0.generation > generation }
        for outcome in overlappingOutcomes {
            guard outcome.succeeded || outcome.hadCachedState else { continue }
            if outcome.isBookmarked {
                if !reconciledPosts.contains(where: { $0.id == outcome.post.id }) {
                    reconciledPosts.append(outcome.post)
                }
            } else {
                reconciledPosts.removeAll { $0.id == outcome.post.id }
            }
        }

        if activeMutationCount == 0 {
            cachedIDs = Set(reconciledPosts.map(\.id))
            hasCachedState = true
        }
        pruneMutationOutcomes()

        return reconciledPosts.map { post in
            var mutablePost = post
            mutablePost.isBookmarked = true
            return mutablePost
        }
    }

    public func isBookmarked(_ postID: Int) -> Bool {
        cachedIDs.contains(postID)
    }

    @discardableResult
    public func toggle(post: Post) async -> Bool {
        mutationGeneration += 1
        activeMutationCount += 1
        let hadCachedState = hasCachedState
        do {
            let newState = try await bookmarksUseCase.toggleBookmark(post: post)
            if newState {
                cachedIDs.insert(post.id)
            } else {
                cachedIDs.remove(post.id)
            }
            finishMutation(
                post: post,
                isBookmarked: newState,
                succeeded: true,
                hadCachedState: hadCachedState
            )
            notificationCenter.post(
                name: .bookmarksDidChange,
                object: nil,
                userInfo: ["postId": post.id, "isBookmarked": newState]
            )
            return newState
        } catch {
            let fallbackState = cachedIDs.contains(post.id)
            finishMutation(
                post: post,
                isBookmarked: fallbackState,
                succeeded: false,
                hadCachedState: hadCachedState
            )
            return fallbackState
        }
    }

    private func finishMutation(
        post: Post,
        isBookmarked: Bool,
        succeeded: Bool,
        hadCachedState: Bool
    ) {
        activeMutationCount -= 1
        mutationGeneration += 1
        mutationOutcomes.append(
            MutationOutcome(
                generation: mutationGeneration,
                post: post,
                isBookmarked: isBookmarked,
                succeeded: succeeded,
                hadCachedState: hadCachedState
            )
        )
        if activeMutationCount == 0 {
            let waiters = mutationCompletionWaiters
            mutationCompletionWaiters.removeAll(keepingCapacity: true)
            waiters.forEach { $0.resume() }
            if externalRefreshPending { scheduleExternalRefresh() }
        }
        pruneMutationOutcomes()
    }

    private func pruneMutationOutcomes() {
        if activeBookmarkedPosts.isEmpty {
            mutationOutcomes.removeAll(keepingCapacity: true)
            return
        }

        if let oldestGeneration = activeBookmarkedPosts.keys.min() {
            mutationOutcomes.removeAll { $0.generation <= oldestGeneration }
        }
    }

    private func waitForActiveMutations() async {
        while activeMutationCount > 0 {
            await withCheckedContinuation { continuation in
                mutationCompletionWaiters.append(continuation)
            }
        }
    }

    private func scheduleExternalRefresh() {
        externalRefreshPending = true
        guard externalRefreshTask == nil, activeMutationCount == 0 else { return }
        externalRefreshPending = false
        let generation = mutationGeneration
        let useCase = bookmarksUseCase
        externalRefreshTask = Task { @MainActor [weak self, useCase] in
            let ids = await useCase.bookmarkedIDs()
            guard !Task.isCancelled else { return }
            self?.completeExternalRefresh(ids: ids, generation: generation)
        }
    }

    private func completeExternalRefresh(ids: Set<Int>, generation: Int) {
        externalRefreshTask = nil
        if generation != mutationGeneration || activeMutationCount > 0 {
            externalRefreshPending = true
        } else {
            hasCachedState = true
            if ids != cachedIDs {
                cachedIDs = ids
                notificationCenter.post(name: .bookmarksDidChange, object: nil)
            }
        }
        if externalRefreshPending { scheduleExternalRefresh() }
    }
}
