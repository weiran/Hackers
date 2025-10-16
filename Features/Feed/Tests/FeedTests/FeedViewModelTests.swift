//
//  FeedViewModelTests.swift
//  FeedTests
//
//  Copyright © 2025 Weiran Zhang. All rights reserved.
//

import Domain
import Foundation
@testable import Feed
import Testing

@Suite("FeedViewModel")
struct FeedViewModelTests {
    @MainActor
    @Test("Loading feed populates posts and clears loading state")
    func loadFeedSuccess() async {
        let postUseCase = StubPostUseCase()
        let voteUseCase = StubVoteUseCase()
        postUseCase.enqueue(.success([SampleData.post(id: 1)]))

        let viewModel = FeedViewModel(postUseCase: postUseCase, voteUseCase: voteUseCase)
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
        let viewModel = FeedViewModel(postUseCase: postUseCase, voteUseCase: StubVoteUseCase())

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

        let viewModel = FeedViewModel(postUseCase: postUseCase, voteUseCase: StubVoteUseCase())
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

        let viewModel = FeedViewModel(postUseCase: postUseCase, voteUseCase: StubVoteUseCase())
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
        let viewModel = FeedViewModel(postUseCase: postUseCase, voteUseCase: voteUseCase)
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

        let viewModel = FeedViewModel(
            postUseCase: postUseCase,
            voteUseCase: voteUseCase,
            settingsUseCase: settingsUseCase
        )

        #expect(viewModel.showThumbnails == true)

        settingsUseCase.showThumbnails = false
        try await Task.sleep(nanoseconds: 10_000_000)

        #expect(viewModel.showThumbnails == false)
    }
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
}

private final class StubSettingsUseCase: SettingsUseCase, @unchecked Sendable {
    var safariReaderMode: Bool = false
    var openInDefaultBrowser: Bool = false
    private var storedShowThumbnails: Bool
    var textSize: TextSize = .medium

    init(showThumbnails: Bool) {
        storedShowThumbnails = showThumbnails
    }

    var showThumbnails: Bool {
        get { storedShowThumbnails }
        set {
            storedShowThumbnails = newValue
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
