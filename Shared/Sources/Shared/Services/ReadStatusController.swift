//
//  ReadStatusController.swift
//  Shared
//
//  Centralises post read state so feed views share synced state.
//

import Domain
import Foundation

@MainActor
public final class ReadStatusController {
    private let readStatusUseCase: any ReadStatusUseCase
    private let notificationCenter: NotificationCenter
    private var cachedIDs: Set<Int> = []
    private var mutationGeneration = 0
    private var activeMutationCount = 0
    private var externalChangesObserver: NSObjectProtocol?
    private var externalRefreshTask: Task<Void, Never>?
    private var externalRefreshPending = false

    public init(
        readStatusUseCase: any ReadStatusUseCase = DependencyContainer.shared.getReadStatusUseCase(),
        notificationCenter: NotificationCenter = .default
    ) {
        self.readStatusUseCase = readStatusUseCase
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
    public func refreshReadStatus() async -> Set<Int> {
        let generation = mutationGeneration
        let ids = await readStatusUseCase.readPostIDs()
        guard generation == mutationGeneration, activeMutationCount == 0 else { return cachedIDs }
        cachedIDs = ids
        return ids
    }

    public func annotatedPosts(from posts: [Post]) -> [Post] {
        posts.map { post in
            var mutablePost = post
            mutablePost.isRead = cachedIDs.contains(post.id)
            return mutablePost
        }
    }

    public func isRead(_ postID: Int) -> Bool {
        cachedIDs.contains(postID)
    }

    public func markRead(postID: Int) async {
        mutationGeneration += 1
        activeMutationCount += 1
        cachedIDs.insert(postID)
        await readStatusUseCase.markPostRead(id: postID)
        activeMutationCount -= 1
        mutationGeneration += 1
        if activeMutationCount == 0 {
            if externalRefreshPending { scheduleExternalRefresh() }
        }
        notificationCenter.post(
            name: .readStatusDidChange,
            object: nil,
            userInfo: ["postId": postID, "isRead": true]
        )
    }

    private func scheduleExternalRefresh() {
        externalRefreshPending = true
        guard externalRefreshTask == nil, activeMutationCount == 0 else { return }
        externalRefreshPending = false
        let generation = mutationGeneration
        let useCase = readStatusUseCase
        externalRefreshTask = Task { @MainActor [weak self, useCase] in
            let ids = await useCase.readPostIDs()
            guard !Task.isCancelled else { return }
            self?.completeExternalRefresh(ids: ids, generation: generation)
        }
    }

    private func completeExternalRefresh(ids: Set<Int>, generation: Int) {
        externalRefreshTask = nil
        if generation != mutationGeneration || activeMutationCount > 0 {
            externalRefreshPending = true
        } else {
            if ids != cachedIDs {
                cachedIDs = ids
                notificationCenter.post(name: .readStatusDidChange, object: nil)
            }
        }
        if externalRefreshPending { scheduleExternalRefresh() }
    }
}
