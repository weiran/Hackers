//
//  ReadStatusController.swift
//  Shared
//
//  Centralises post read state so feed views share synced state.
//

import Domain
import Foundation

public final class ReadStatusController: @unchecked Sendable {
    private let readStatusUseCase: any ReadStatusUseCase
    private var cachedIDs: Set<Int> = []
    private var externalChangesObserver: NSObjectProtocol?

    public init(readStatusUseCase: any ReadStatusUseCase = DependencyContainer.shared.getReadStatusUseCase()) {
        self.readStatusUseCase = readStatusUseCase
        externalChangesObserver = NotificationCenter.default.addObserver(
            forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: NSUbiquitousKeyValueStore.default,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                _ = await self.refreshReadStatus()
                NotificationCenter.default.post(name: .readStatusDidChange, object: nil)
            }
        }
    }

    deinit {
        if let externalChangesObserver {
            NotificationCenter.default.removeObserver(externalChangesObserver)
        }
    }

    @MainActor
    @discardableResult
    public func refreshReadStatus() async -> Set<Int> {
        let ids = await readStatusUseCase.readPostIDs()
        cachedIDs = ids
        return ids
    }

    @MainActor
    public func annotatedPosts(from posts: [Post]) -> [Post] {
        posts.map { post in
            var mutablePost = post
            mutablePost.isRead = cachedIDs.contains(post.id)
            return mutablePost
        }
    }

    @MainActor
    public func isRead(_ postID: Int) -> Bool {
        cachedIDs.contains(postID)
    }

    @MainActor
    public func markRead(postID: Int) async {
        cachedIDs.insert(postID)
        await readStatusUseCase.markPostRead(id: postID)
        NotificationCenter.default.post(
            name: .readStatusDidChange,
            object: nil,
            userInfo: ["postId": postID, "isRead": true]
        )
    }
}
