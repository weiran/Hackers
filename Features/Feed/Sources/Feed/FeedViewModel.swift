//
//  FeedViewModel.swift
//  Feed
//
//  Copyright © 2025 Weiran Zhang. All rights reserved.
//

import Foundation
import Domain
import Shared
import SwiftUI

@Observable
public final class FeedViewModel: @unchecked Sendable {
    public var isLoadingMore = false
    public var postType: Domain.PostType = .news

    private var postIds: Set<Int> = Set()
    private var pageIndex = 1
    private var lastPostId = 0
    private var isFetching = false

    private let postUseCase: any PostUseCase
    private let voteUseCase: any VoteUseCase
    private let feedLoader: LoadingStateManager<[Domain.Post]>

    public var posts: [Domain.Post] { feedLoader.data }
    public var isLoading: Bool { feedLoader.isLoading }
    public var error: Error? { feedLoader.error }

    public init(
        postUseCase: any PostUseCase = DependencyContainer.shared.getPostUseCase(),
        voteUseCase: any VoteUseCase = DependencyContainer.shared.getVoteUseCase()
    ) {
        self.postUseCase = postUseCase
        self.voteUseCase = voteUseCase
        self.feedLoader = LoadingStateManager(initialData: [])

        // Set up the loading function after initialization
        feedLoader.setLoadFunction(
            shouldSkipLoad: { !$0.isEmpty },
            loadData: { [weak self] in
                try await self?.fetchFeed() ?? []
            }
        )
    }

    @MainActor
    public func loadFeed() async {
        await feedLoader.loadIfNeeded()
    }

    @MainActor
    public func loadNextPage() async {
        guard !isLoadingMore && !isLoading && !posts.isEmpty else { return }

        isLoadingMore = true

        if postType == .newest || postType == .jobs {
            lastPostId = posts.last?.id ?? lastPostId
        } else {
            pageIndex += 1
        }

        do {
            let fetchedPosts = try await postUseCase.getPosts(
                type: postType,
                page: pageIndex,
                nextId: lastPostId > 0 ? lastPostId : nil
            )

            let newPosts = fetchedPosts.filter { !self.postIds.contains($0.id) }
            let newPostIds = newPosts.map { $0.id }

            // Update the LoadingStateManager's data with appended posts
            feedLoader.data.append(contentsOf: newPosts)
            self.postIds.formUnion(newPostIds)

            isLoadingMore = false
        } catch {
            // Can't set error directly anymore, could log or handle differently
            isLoadingMore = false
        }
    }

    @MainActor
    public func vote(on post: Domain.Post, upvote: Bool) async throws {
        if upvote {
            try await voteUseCase.upvote(post: post)
        } else {
            try await voteUseCase.unvote(post: post)
        }
    }

    @MainActor
    public func refreshFeed() async {
        reset()
        await feedLoader.refresh()
    }

    private func fetchFeed() async throws -> [Domain.Post] {
        do {
            let fetchedPosts = try await postUseCase.getPosts(
                type: postType,
                page: pageIndex,
                nextId: lastPostId > 0 ? lastPostId : nil
            )

            return await MainActor.run {
                let newPosts = fetchedPosts.filter { !self.postIds.contains($0.id) }
                let newPostIds = newPosts.map { $0.id }
                self.postIds.formUnion(newPostIds)
                return newPosts
            }
        } catch {
            throw error
        }
    }

    @MainActor
    public func changePostType(_ newType: Domain.PostType) async {
        guard postType != newType else { return }

        postType = newType
        await refreshFeed()
    }

    @MainActor
    private func reset() {
        postIds = Set()
        pageIndex = 1
        lastPostId = 0
        isFetching = false
        feedLoader.reset()
    }

    // MARK: - Post Updates

    @MainActor
    public func replacePost(_ updatedPost: Domain.Post) {
        if let index = feedLoader.data.firstIndex(where: { $0.id == updatedPost.id }) {
            feedLoader.data[index] = updatedPost
        }
    }
}
