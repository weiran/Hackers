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

public protocol ReadStatusUseCase: Sendable {
    func readPostIDs() async -> Set<Int>
    func markPostRead(id: Int) async
}

public protocol SearchUseCase: Sendable {
    func searchPosts(
        query: String,
        sort: SearchSort,
        dateRange: SearchDateRange,
        page: Int,
        hitsPerPage: Int
    ) async throws -> SearchResultsPage
}

public enum SearchSort: String, CaseIterable, Sendable {
    case popular
    case recent
}

public enum SearchDateRange: String, CaseIterable, Sendable {
    case allTime
    case last24Hours
    case pastWeek
    case pastMonth
    case pastYear
}

public struct SearchResultsPage: Sendable, Equatable {
    public let posts: [Post]
    public let page: Int
    public let totalPages: Int
    public let totalResults: Int
    public let hasMore: Bool

    public init(posts: [Post], page: Int, totalPages: Int, totalResults: Int, hasMore: Bool) {
        self.posts = posts
        self.page = page
        self.totalPages = totalPages
        self.totalResults = totalResults
        self.hasMore = hasMore
    }
}
