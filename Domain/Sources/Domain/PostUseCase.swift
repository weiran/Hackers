//
//  PostUseCase.swift
//  Domain
//
//  Copyright © 2025 Weiran Zhang. All rights reserved.
//

import Foundation

public protocol PostUseCase: Sendable {
    func getPosts(type: PostType, page: Int, nextId: Int?) async throws -> [Post]
    func getPost(id: Int) async throws -> Post
}

public protocol BookmarksUseCase: Sendable {
    func bookmarkedIDs() async -> Set<Int>
    func bookmarkedPosts() async -> [Post]
    @discardableResult
    func toggleBookmark(post: Post) async throws -> Bool
}
