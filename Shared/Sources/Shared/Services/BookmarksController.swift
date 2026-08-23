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
    private let bookmarksUseCase: any BookmarksUseCase
    private var cachedIDs: Set<Int> = []

    public init(bookmarksUseCase: any BookmarksUseCase = DependencyContainer.shared.getBookmarksUseCase()) {
        self.bookmarksUseCase = bookmarksUseCase
    }

    @discardableResult
    public func refreshBookmarks() async -> Set<Int> {
        let ids = await bookmarksUseCase.bookmarkedIDs()
        cachedIDs = ids
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
        let posts = await bookmarksUseCase.bookmarkedPosts()
        cachedIDs = Set(posts.map(\.id))
        return posts.map { post in
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
        do {
            let newState = try await bookmarksUseCase.toggleBookmark(post: post)
            if newState {
                cachedIDs.insert(post.id)
            } else {
                cachedIDs.remove(post.id)
            }
            NotificationCenter.default.post(
                name: .bookmarksDidChange,
                object: nil,
                userInfo: ["postId": post.id, "isBookmarked": newState]
            )
            return newState
        } catch {
            return cachedIDs.contains(post.id)
        }
    }
}
