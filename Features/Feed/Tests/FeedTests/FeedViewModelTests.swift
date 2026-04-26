//
//  FeedViewModelTests.swift
//  FeedTests
//
//  Copyright © 2025 Weiran Zhang. All rights reserved.
//

import Domain
import Foundation
@testable import Feed
import Shared
import Testing

@Suite("FeedViewModel")
struct FeedViewModelTests {
    @MainActor
    @Test("Loading feed populates posts and clears loading state")
    func loadFeedSuccess() async {
        let postUseCase = StubPostUseCase()
        let voteUseCase = StubVoteUseCase()
        postUseCase.enqueue(.success([SampleData.post(id: 1)]))
        let bookmarksUseCase = StubBookmarksUseCase()
        let bookmarksController = BookmarksController(bookmarksUseCase: bookmarksUseCase)
        let searchUseCase = StubSearchUseCase()

        let viewModel = FeedViewModel(
            postUseCase: postUseCase,
            voteUseCase: voteUseCase,
            bookmarksController: bookmarksController,
            searchUseCase: searchUseCase
        )
        await viewModel.loadFeed()

        #expect(viewModel.posts.count == 1)
        #expect(viewModel.posts.first?.id == 1)
        #expect(viewModel.isLoading == false)
        #expect(viewModel.error == nil)
    }

    @MainActor
    @Test("Load failure surfaces error state and stops spinner")
    func loadFeedFailure() async {
        let postUseCase = StubPostUseCase()
        postUseCase.enqueue(.failure(StubError.network))
        let bookmarksController = BookmarksController(bookmarksUseCase: StubBookmarksUseCase())
        let searchUseCase = StubSearchUseCase()
        let viewModel = FeedViewModel(
            postUseCase: postUseCase,
            voteUseCase: StubVoteUseCase(),
            bookmarksController: bookmarksController,
            searchUseCase: searchUseCase
        )

        await viewModel.loadFeed()

        #expect(viewModel.posts.isEmpty)
        #expect(viewModel.error is StubError)
        #expect(viewModel.isLoading == false)
    }

    @MainActor
    @Test("Next page appends unique posts without duplicates")
    func loadNextPageAppendsUniquePosts() async {
        let postUseCase = StubPostUseCase()
        postUseCase.enqueue(.success([SampleData.post(id: 1), SampleData.post(id: 2)]))
        postUseCase.enqueue(.success([SampleData.post(id: 2), SampleData.post(id: 3)]))
        let bookmarksController = BookmarksController(bookmarksUseCase: StubBookmarksUseCase())
        let searchUseCase = StubSearchUseCase()

        let viewModel = FeedViewModel(
            postUseCase: postUseCase,
            voteUseCase: StubVoteUseCase(),
            bookmarksController: bookmarksController,
            searchUseCase: searchUseCase
        )
        await viewModel.loadFeed()
        await viewModel.loadNextPage()

        let ids = viewModel.posts.map(\.id)
        #expect(ids == [1, 2, 3])
        #expect(viewModel.isLoadingMore == false)
    }

    @MainActor
    @Test("Changing post type refreshes feed and resets pagination")
    func changePostTypeRefreshesFeed() async {
        let postUseCase = StubPostUseCase()
        postUseCase.enqueue(.success([SampleData.post(id: 1)]))
        postUseCase.enqueue(.success([SampleData.post(id: 42, type: .ask)]))
        let bookmarksController = BookmarksController(bookmarksUseCase: StubBookmarksUseCase())

        let viewModel = FeedViewModel(
            postUseCase: postUseCase,
            voteUseCase: StubVoteUseCase(),
            bookmarksController: bookmarksController
        )
        await viewModel.loadFeed()
        await viewModel.changePostType(.ask)

        #expect(viewModel.postType == .ask)
        #expect(viewModel.posts.first?.id == 42)
        #expect(postUseCase.requestedTypes == [.news, .ask])
    }

    @MainActor
    @Test("Voting delegates to use case and propagates errors")
    func voteDelegatesToUseCase() async throws {
        let post = SampleData.post(id: 7)
        let postUseCase = StubPostUseCase()
        postUseCase.enqueue(.success([post]))
        let voteUseCase = StubVoteUseCase()
        let bookmarksController = BookmarksController(bookmarksUseCase: StubBookmarksUseCase())
        let viewModel = FeedViewModel(
            postUseCase: postUseCase,
            voteUseCase: voteUseCase,
            bookmarksController: bookmarksController
        )
        await viewModel.loadFeed()

        try await viewModel.vote(on: post, upvote: true)
        #expect(voteUseCase.upvotePostCallCount == 1)

        voteUseCase.shouldThrow = true
        await #expect(throws: StubError.self) {
            try await viewModel.vote(on: post, upvote: true)
        }
        #expect(voteUseCase.upvotePostCallCount == 2)
    }

    @MainActor
    @Test("Show thumbnails follows settings changes via notifications")
    func showThumbnailsSyncsWithSettings() async throws {
        let postUseCase = StubPostUseCase()
        let voteUseCase = StubVoteUseCase()
        let settingsUseCase = StubSettingsUseCase(showThumbnails: true)
        let bookmarksController = BookmarksController(bookmarksUseCase: StubBookmarksUseCase())

        let viewModel = FeedViewModel(
            postUseCase: postUseCase,
            voteUseCase: voteUseCase,
            settingsUseCase: settingsUseCase,
            bookmarksController: bookmarksController
        )

        #expect(viewModel.showThumbnails == true)

        settingsUseCase.showThumbnails = false
        try await Task.sleep(for: .milliseconds(10))

        #expect(viewModel.showThumbnails == false)
    }

    @MainActor
    @Test("Initializes with stored feed category when remember setting enabled")
    func initializesWithStoredFeedCategory() async {
        let postUseCase = StubPostUseCase()
        let voteUseCase = StubVoteUseCase()
        let settingsUseCase = StubSettingsUseCase(
            showThumbnails: true,
            rememberFeedCategory: true,
            lastFeedCategory: .ask
        )
        let bookmarksController = BookmarksController(bookmarksUseCase: StubBookmarksUseCase())
        let searchUseCase = StubSearchUseCase()

        let viewModel = FeedViewModel(
            postUseCase: postUseCase,
            voteUseCase: voteUseCase,
            settingsUseCase: settingsUseCase,
            bookmarksController: bookmarksController,
            searchUseCase: searchUseCase
        )

        #expect(viewModel.postType == .ask)
    }

    @MainActor
    @Test("Changing post type persists when remember setting enabled")
    func changePostTypePersistsWhenRememberEnabled() async {
        let postUseCase = StubPostUseCase()
        let voteUseCase = StubVoteUseCase()
        let settingsUseCase = StubSettingsUseCase(
            showThumbnails: true,
            rememberFeedCategory: true,
            lastFeedCategory: .news
        )
        let bookmarksController = BookmarksController(bookmarksUseCase: StubBookmarksUseCase())
        let searchUseCase = StubSearchUseCase()

        let viewModel = FeedViewModel(
            postUseCase: postUseCase,
            voteUseCase: voteUseCase,
            settingsUseCase: settingsUseCase,
            bookmarksController: bookmarksController,
            searchUseCase: searchUseCase
        )

        await viewModel.changePostType(.jobs)
        #expect(settingsUseCase.lastFeedCategory == .jobs)
    }

    @MainActor
    @Test("Bookmarks post type loads stored posts")
    func bookmarksCategoryLoadsStoredPosts() async {
        let postUseCase = StubPostUseCase()
        let voteUseCase = StubVoteUseCase()
        var bookmarkedPost = SampleData.post(id: 99)
        bookmarkedPost.isBookmarked = true
        let bookmarksUseCase = StubBookmarksUseCase(posts: [bookmarkedPost])
        let bookmarksController = BookmarksController(bookmarksUseCase: bookmarksUseCase)
        let searchUseCase = StubSearchUseCase()

        let viewModel = FeedViewModel(
            postUseCase: postUseCase,
            voteUseCase: voteUseCase,
            bookmarksController: bookmarksController,
            searchUseCase: searchUseCase
        )

        await viewModel.changePostType(.bookmarks)

        #expect(viewModel.postType == .bookmarks)
        #expect(viewModel.posts.count == 1)
        #expect(viewModel.posts.first?.id == 99)
        #expect(viewModel.posts.first?.isBookmarked == true)
    }

    @MainActor
    @Test("Toggling bookmark updates post state")
    func togglingBookmarkUpdatesPostState() async {
        let postUseCase = StubPostUseCase()
        postUseCase.enqueue(.success([SampleData.post(id: 5)]))
        let bookmarksUseCase = StubBookmarksUseCase()
        let bookmarksController = BookmarksController(bookmarksUseCase: bookmarksUseCase)
        let searchUseCase = StubSearchUseCase()

        let viewModel = FeedViewModel(
            postUseCase: postUseCase,
            voteUseCase: StubVoteUseCase(),
            bookmarksController: bookmarksController,
            searchUseCase: searchUseCase
        )

        await viewModel.loadFeed()
        #expect(viewModel.posts.first?.isBookmarked == false)

        let didBookmark = await viewModel.toggleBookmark(for: viewModel.posts[0])
        #expect(didBookmark == true)
        #expect(viewModel.posts.first?.isBookmarked == true)

        let didRemove = await viewModel.toggleBookmark(for: viewModel.posts[0])
        #expect(didRemove == false)
        #expect(viewModel.posts.first?.isBookmarked == false)
    }

    @MainActor
    @Test("Bookmark notifications propagate to feed")
    func bookmarkNotificationsPropagateToFeed() async throws {
        let postUseCase = StubPostUseCase()
        postUseCase.enqueue(.success([SampleData.post(id: 12)]))
        let bookmarksUseCase = StubBookmarksUseCase()
        let bookmarksController = BookmarksController(bookmarksUseCase: bookmarksUseCase)
        let searchUseCase = StubSearchUseCase()

        let viewModel = FeedViewModel(
            postUseCase: postUseCase,
            voteUseCase: StubVoteUseCase(),
            bookmarksController: bookmarksController,
            searchUseCase: searchUseCase
        )

        await viewModel.loadFeed()
        #expect(viewModel.posts.first?.isBookmarked == false)

        _ = await bookmarksController.toggle(post: viewModel.posts[0])
        try await Task.sleep(for: .milliseconds(20))

        #expect(viewModel.posts.first?.isBookmarked == true)
    }

    @MainActor
    @Test("Search query updates results")
    func searchQueryUpdatesResults() async throws {
        let postUseCase = StubPostUseCase()
        postUseCase.enqueue(.success([SampleData.post(id: 1)]))
        let bookmarksController = BookmarksController(bookmarksUseCase: StubBookmarksUseCase())
        let searchUseCase = StubSearchUseCase()
        searchUseCase.nextResults = [SampleData.post(id: 42)]

        let viewModel = FeedViewModel(
            postUseCase: postUseCase,
            voteUseCase: StubVoteUseCase(),
            bookmarksController: bookmarksController,
            searchUseCase: searchUseCase
        )

        await viewModel.loadFeed()
        viewModel.updateSearchQuery("swift")
        let searchCompleted = await waitForSearchCompletion(of: viewModel)
        #expect(searchCompleted)

        #expect(searchUseCase.receivedQueries.contains("swift"))
        #expect(viewModel.searchResults.first?.id == 42)
        #expect(viewModel.hasActiveSearch)
        #expect(viewModel.isSearchInProgress == false)
    }
}

@MainActor
private func waitForSearchCompletion(of viewModel: FeedViewModel, timeout: TimeInterval = 1, pollInterval: TimeInterval = 0.01) async -> Bool {
    let deadline = Date().addingTimeInterval(timeout)
    while viewModel.isSearchInProgress && Date() < deadline {
        let nanos = UInt64(pollInterval * 1_000_000_000)
        try? await Task.sleep(for: .nanoseconds(nanos))
    }
    return viewModel.isSearchInProgress == false
}

// MARK: - Test Doubles

private enum StubError: Error {
    case network
}

private final class StubPostUseCase: PostUseCase, @unchecked Sendable {
    private var responses: [Result<[Post], Error>] = []
    private(set) var requestedTypes: [PostType] = []

    func enqueue(_ result: Result<[Post], Error>) {
        responses.append(result)
    }

    func getPosts(type: PostType, page _: Int, nextId _: Int?) async throws -> [Post] {
        requestedTypes.append(type)
        guard !responses.isEmpty else { return [] }
        let result = responses.removeFirst()
        switch result {
        case let .success(posts):
            return posts
        case let .failure(error):
            throw error
        }
    }

    func getPost(id _: Int) async throws -> Post {
        throw StubError.network
    }
}

private final class StubVoteUseCase: VoteUseCase, @unchecked Sendable {
    var upvotePostCallCount = 0
    var shouldThrow = false

    func upvote(post _: Post) async throws {
        upvotePostCallCount += 1
        if shouldThrow { throw StubError.network }
    }

    func upvote(comment _: Domain.Comment, for _: Post) async throws {
        if shouldThrow { throw StubError.network }
    }

    func unvote(post _: Post) async throws {
        if shouldThrow { throw StubError.network }
    }

    func unvote(comment _: Domain.Comment, for _: Post) async throws {
        if shouldThrow { throw StubError.network }
    }
}

private final class StubBookmarksUseCase: BookmarksUseCase, @unchecked Sendable {
    private var posts: [Post]

    init(posts: [Post] = []) {
        self.posts = posts.map { post in
            var mutablePost = post
            mutablePost.isBookmarked = true
            return mutablePost
        }
    }

    func bookmarkedIDs() async -> Set<Int> {
        Set(posts.map(\.id))
    }

    func bookmarkedPosts() async -> [Post] {
        posts
    }

    @discardableResult
    func toggleBookmark(post: Post) async throws -> Bool {
        if let index = posts.firstIndex(where: { $0.id == post.id }) {
            posts.remove(at: index)
            return false
        } else {
            var mutablePost = post
            mutablePost.isBookmarked = true
            posts.insert(mutablePost, at: 0)
            return true
        }
    }
}

private final class StubSearchUseCase: SearchUseCase, @unchecked Sendable {
    var nextResults: [Post] = []
    var receivedQueries: [String] = []
    var shouldThrow = false

    func searchPosts(query: String) async throws -> [Post] {
        receivedQueries.append(query)
        if shouldThrow { throw StubError.network }
        return nextResults
    }
}

private final class StubSettingsUseCase: SettingsUseCase, @unchecked Sendable {
    var safariReaderMode: Bool = false
    var linkBrowserMode: LinkBrowserMode = .inAppBrowser
    private var storedShowThumbnails: Bool
    private var storedRememberFeedCategory: Bool
    private var storedLastFeedCategory: PostType?
    var textSize: TextSize = .medium
    var compactFeedDesign: Bool = false

    init(
        showThumbnails: Bool,
        rememberFeedCategory: Bool = false,
        lastFeedCategory: PostType? = nil
    ) {
        storedShowThumbnails = showThumbnails
        storedRememberFeedCategory = rememberFeedCategory
        storedLastFeedCategory = lastFeedCategory
    }

    var showThumbnails: Bool {
        get { storedShowThumbnails }
        set {
            storedShowThumbnails = newValue
            NotificationCenter.default.post(name: UserDefaults.didChangeNotification, object: nil)
        }
    }

    var rememberFeedCategory: Bool {
        get { storedRememberFeedCategory }
        set {
            storedRememberFeedCategory = newValue
            if !newValue {
                storedLastFeedCategory = nil
            }
            NotificationCenter.default.post(name: UserDefaults.didChangeNotification, object: nil)
        }
    }

    var lastFeedCategory: PostType? {
        get { storedLastFeedCategory }
        set {
            storedLastFeedCategory = newValue
            NotificationCenter.default.post(name: UserDefaults.didChangeNotification, object: nil)
        }
    }

    func clearCache() {}

    func cacheUsageBytes() async -> Int64 { 0 }
}

private enum SampleData {
    static func post(id: Int, type: PostType = .news) -> Post {
        Post(
            id: id,
            url: URL(string: "https://example.com/\(id)")!,
            title: "Post \(id)",
            age: "1 hour ago",
            commentsCount: 10,
            by: "user\(id)",
            score: 100,
            postType: type,
            upvoted: false
        )
    }
}
