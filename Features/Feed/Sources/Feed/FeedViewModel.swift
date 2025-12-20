//
//  FeedViewModel.swift
//  Feed
//
//  Copyright © 2025 Weiran Zhang. All rights reserved.
//

import Combine
import Domain
import Foundation
import Observation
import Shared
import SwiftUI

@MainActor
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
    private let bookmarksController: BookmarksController
    private let searchUseCase: any SearchUseCase
    private let feedLoader: LoadingStateManager<[Domain.Post]>
    private var settingsUseCase: any SettingsUseCase
    private var settingsCancellable: AnyCancellable?
    private var bookmarksObservation: AnyCancellable?
    private var searchTask: Task<Void, Never>?
    private var rememberFeedCategorySetting: Bool

    public var posts: [Domain.Post] { feedLoader.data }
    public var isLoading: Bool { feedLoader.isLoading }
    public var error: Error? { feedLoader.error }
    public var showThumbnails: Bool
    public var compactFeedDesign: Bool
    public var searchQuery: String = ""
    public var searchResults: [Domain.Post] = []
    public var isSearchInProgress = false
    public var searchError: Error?
    public var hasActiveSearch: Bool {
        !searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    public var displayedPosts: [Domain.Post] {
        hasActiveSearch ? searchResults : posts
    }

    @MainActor
    public init(
        postUseCase: any PostUseCase = DependencyContainer.shared.getPostUseCase(),
        voteUseCase: any VoteUseCase = DependencyContainer.shared.getVoteUseCase(),
        settingsUseCase: any SettingsUseCase = DependencyContainer.shared.getSettingsUseCase(),
        bookmarksController: BookmarksController? = nil,
        searchUseCase: any SearchUseCase = DependencyContainer.shared.getSearchUseCase()
    ) {
        self.postUseCase = postUseCase
        self.voteUseCase = voteUseCase
        self.settingsUseCase = settingsUseCase
        self.bookmarksController = bookmarksController ?? DependencyContainer.shared.makeBookmarksController()
        self.searchUseCase = searchUseCase
        showThumbnails = settingsUseCase.showThumbnails
        compactFeedDesign = settingsUseCase.compactFeedDesign
        let rememberSetting = settingsUseCase.rememberFeedCategory
        rememberFeedCategorySetting = rememberSetting
        if rememberSetting, let storedPostType = settingsUseCase.lastFeedCategory {
            postType = storedPostType
        }
        feedLoader = LoadingStateManager(initialData: [])

        // Set up the loading function after initialization
        feedLoader.setLoadFunction(
            shouldSkipLoad: { !$0.isEmpty },
            loadData: { [weak self] in
                try await self?.fetchFeed() ?? []
            },
        )

        settingsCancellable = NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self else { return }
                let currentValue = self.settingsUseCase.showThumbnails
                if self.showThumbnails != currentValue {
                    self.showThumbnails = currentValue
                }
                let compactValue = self.settingsUseCase.compactFeedDesign
                if self.compactFeedDesign != compactValue {
                    self.compactFeedDesign = compactValue
                }
                let rememberValue = self.settingsUseCase.rememberFeedCategory
                if self.rememberFeedCategorySetting != rememberValue {
                    self.rememberFeedCategorySetting = rememberValue
                    if rememberValue {
                        self.settingsUseCase.lastFeedCategory = self.postType
                    } else {
                        self.settingsUseCase.lastFeedCategory = nil
                    }
                }
            }

        bookmarksObservation = NotificationCenter.default.publisher(for: .bookmarksDidChange)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                guard
                    let postId = notification.userInfo?["postId"] as? Int,
                    let isBookmarked = notification.userInfo?["isBookmarked"] as? Bool
                else { return }
                Task { @MainActor [weak self] in
                    guard let self else { return }
                    await self.handleBookmarksUpdate(postId: postId, isBookmarked: isBookmarked)
                }
            }
    }

    @MainActor
    public func loadFeed() async {
        await feedLoader.loadIfNeeded()
    }

    @MainActor
    public func loadNextPage() async {
        guard !isLoadingMore && !isLoading && !posts.isEmpty else { return }
        guard postType != .bookmarks else { return }

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
                nextId: lastPostId > 0 ? lastPostId : nil,
            )

            await bookmarksController.refreshBookmarks()
            let annotatedPosts = bookmarksController.annotatedPosts(from: fetchedPosts)

            let newPosts = annotatedPosts.filter { !self.postIds.contains($0.id) }
            let newPostIds = newPosts.map(\.id)

            // Update the LoadingStateManager's data with appended posts
            feedLoader.data.append(contentsOf: newPosts)
            postIds.formUnion(newPostIds)

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
        }
        // Unvote removed; do nothing when upvote == false
    }

    @MainActor
    public func refreshFeed() async {
        reset()
        await feedLoader.refresh()
    }

    private func fetchFeed() async throws -> [Domain.Post] {
        if postType == .bookmarks {
            let storedPosts = await bookmarksController.bookmarkedPosts()
            return await MainActor.run {
                postIds = Set(storedPosts.map(\.id))
                return storedPosts
            }
        }

        await bookmarksController.refreshBookmarks()

        do {
            let fetchedPosts = try await postUseCase.getPosts(
                type: postType,
                page: pageIndex,
                nextId: lastPostId > 0 ? lastPostId : nil,
            )

            return await MainActor.run {
                // Filter duplicates by creating a new set from the fetched posts
                var seenIds = Set<Int>()
                let uniquePosts = fetchedPosts.filter { post in
                    if seenIds.contains(post.id) {
                        return false
                    } else {
                        seenIds.insert(post.id)
                        return true
                    }
                }

                let annotatedPosts = bookmarksController.annotatedPosts(from: uniquePosts)

                let newPostIds = annotatedPosts.map(\.id)
                self.postIds.formUnion(newPostIds)
                return annotatedPosts
            }
        } catch {
            throw error
        }
    }

    @MainActor
    public func changePostType(_ newType: Domain.PostType) async {
        guard postType != newType else { return }

        postType = newType
        persistLastFeedCategoryIfNeeded()
        reset(clearPosts: true)  // Clear posts immediately to prevent flash of old data
        await feedLoader.refresh()
    }

    @MainActor
    private func reset(clearPosts: Bool = false) {
        if clearPosts {
            feedLoader.data = []
        }
        postIds = Set()
        pageIndex = 1
        lastPostId = 0
        isFetching = false
        feedLoader.reset()
    }

    private func persistLastFeedCategoryIfNeeded() {
        guard rememberFeedCategorySetting else { return }
        settingsUseCase.lastFeedCategory = postType
    }

    // MARK: - Post Updates

    @MainActor
    public func replacePost(_ updatedPost: Domain.Post) {
        if let index = feedLoader.data.firstIndex(where: { $0.id == updatedPost.id }) {
            feedLoader.data[index] = updatedPost
        }
        if let searchIndex = searchResults.firstIndex(where: { $0.id == updatedPost.id }) {
            searchResults[searchIndex] = updatedPost
        }
    }

    @MainActor
    public func toggleBookmark(for post: Domain.Post) async -> Bool {
        let newState = await bookmarksController.toggle(post: post)
        await handleBookmarksUpdate(postId: post.id, isBookmarked: newState)
        return newState
    }

    @MainActor
    private func updateBookmarkState(for postId: Int, isBookmarked: Bool) {
        if let index = feedLoader.data.firstIndex(where: { $0.id == postId }) {
            feedLoader.data[index].isBookmarked = isBookmarked
        }
        if let index = searchResults.firstIndex(where: { $0.id == postId }) {
            searchResults[index].isBookmarked = isBookmarked
        }
    }

    @MainActor
    private func handleBookmarksUpdate(postId: Int, isBookmarked: Bool) async {
        updateBookmarkState(for: postId, isBookmarked: isBookmarked)

        if postType == .bookmarks {
            let posts = await bookmarksController.bookmarkedPosts()
            let updatedPostIds = Set(posts.map(\.id))
            withAnimation(.easeInOut) {
                postIds = updatedPostIds
                feedLoader.data = posts
            }
        }
    }

    @MainActor
    public func updateSearchQuery(_ query: String) {
        searchTask?.cancel()
        searchQuery = query
        searchError = nil

        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            isSearchInProgress = false
            searchResults = []
            return
        }

        isSearchInProgress = true
        let currentQuery = query
        searchTask = Task { [weak self] in
            guard let self else { return }
            do {
                let results = try await self.searchUseCase.searchPosts(query: currentQuery)
                if Task.isCancelled { return }
                await self.bookmarksController.refreshBookmarks()
                let annotated = await MainActor.run {
                    self.bookmarksController.annotatedPosts(from: results)
                }
                await MainActor.run {
                    self.searchResults = annotated
                    self.isSearchInProgress = false
                }
            } catch {
                if Task.isCancelled { return }
                await MainActor.run {
                    self.searchResults = []
                    self.isSearchInProgress = false
                    self.searchError = error
                }
            }
        }
    }
}
