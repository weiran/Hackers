//
//  VotingViewModelTests.swift
//  SharedTests
//
//  Copyright © 2025 Weiran Zhang. All rights reserved.
//

import Domain
import Foundation
@testable import Shared
import Testing

@Suite("VotingViewModel Tests")
struct VotingViewModelTests {
    let mockVotingStateProvider = MockVotingStateProvider()
    let mockCommentVotingStateProvider = MockCommentVotingStateProvider()

    @MainActor
    var votingViewModel: VotingViewModel {
        VotingViewModel(
            votingStateProvider: mockVotingStateProvider,
            commentVotingStateProvider: mockCommentVotingStateProvider,
            authenticationUseCase: MockAuthenticationUseCase(),
        )
    }

    // MARK: - Mock Services

    final class MockVotingStateProvider: VotingStateProvider, @unchecked Sendable {
        var upvoteCalled = false
        var errorToThrow: Error?
        var unvoteErrorToThrow: Error?

        func votingState(for item: any Votable) -> VotingState {
            VotingState(
                isUpvoted: item.upvoted,
                score: (item as? any ScoredVotable)?.score,
                canVote: item.voteLinks?.upvote != nil,
            )
        }

        func upvote(item _: any Votable) async throws {
            upvoteCalled = true
            if let errorToThrow { throw errorToThrow }
        }

        func unvote(item _: any Votable) async throws {
            if let unvoteErrorToThrow { throw unvoteErrorToThrow }
        }
    }

    final class MockCommentVotingStateProvider: CommentVotingStateProvider, @unchecked Sendable {
        var upvoteCommentCalled = false
        var shouldThrow = false
        var unvoteErrorToThrow: Error?

        func upvoteComment(_: Domain.Comment, for _: Post) async throws {
            upvoteCommentCalled = true
            if shouldThrow {
                throw HackersKitError.requestFailure
            }
        }

        func unvoteComment(_: Domain.Comment, for _: Post) async throws {
            if let unvoteErrorToThrow { throw unvoteErrorToThrow }
        }
    }

    final class BlockingCommentVotingStateProvider: CommentVotingStateProvider, @unchecked Sendable {
        private let lock = NSLock()
        private var continuations: [Int: CheckedContinuation<Void, Never>] = [:]
        private var startedItemIDs: Set<Int> = []
        private var startWaiters: [Int: [CheckedContinuation<Void, Never>]] = [:]

        func upvoteComment(_ comment: Domain.Comment, for _: Post) async throws {
            await withCheckedContinuation { continuation in
                let waiters = lock.withLock {
                    continuations[comment.id] = continuation
                    startedItemIDs.insert(comment.id)
                    return startWaiters.removeValue(forKey: comment.id) ?? []
                }
                waiters.forEach { $0.resume() }
            }
        }

        func unvoteComment(_: Domain.Comment, for _: Post) async throws {}

        func waitUntilStarted(itemID: Int) async {
            if lock.withLock({ startedItemIDs.contains(itemID) }) {
                return
            }

            await withCheckedContinuation { continuation in
                let alreadyStarted = lock.withLock {
                    if startedItemIDs.contains(itemID) {
                        return true
                    }
                    startWaiters[itemID, default: []].append(continuation)
                    return false
                }
                if alreadyStarted {
                    continuation.resume()
                }
            }
        }

        func finish(itemID: Int) {
            let continuation = lock.withLock { continuations.removeValue(forKey: itemID) }
            continuation?.resume()
        }
    }

    final class MockAuthenticationUseCase: AuthenticationUseCase, @unchecked Sendable {
        var logoutCalled = false
        func authenticate(username _: String, password _: String) async throws {}
        func logout() async throws { logoutCalled = true }
        func isAuthenticated() async -> Bool { false }
        func getCurrentUser() async -> User? { nil }
    }

    final class MockNavigationStore: NavigationStoreProtocol {
        init() {}

        var selectedPost: Post?
        var selectedPostId: Int?
        var showingLogin: Bool = false
        var showingSettings: Bool = false
        var showLoginCalled = false

        func showPost(_ post: Post) {
            selectedPost = post
            selectedPostId = post.id
        }

        func showPostLink(_ post: Post, presentation _: PostLinkPresentation) {
            selectedPost = post
            selectedPostId = post.id
        }

        func showPost(withId id: Int) {
            selectedPostId = id
            selectedPost = nil
        }

        func showLogin() { showingLogin = true; showLoginCalled = true }
        func showSettings() { showingSettings = true }
        func selectPostType(_: PostType) {}
        @MainActor
        func openURLInPrimaryContext(_: URL, pushOntoDetailStack _: Bool) -> Bool { false }
    }

    // MARK: - Unauthenticated flow

    @Test("Unauthenticated upvote triggers logout and login prompt")
    @MainActor
    func unauthenticatedUpvoteFlow() async throws {
        // Given
        let mockAuth = MockAuthenticationUseCase()
        let nav = MockNavigationStore()
        let viewModel = VotingViewModel(
            votingStateProvider: mockVotingStateProvider,
            commentVotingStateProvider: mockCommentVotingStateProvider,
            authenticationUseCase: mockAuth,
        )
        viewModel.navigationStore = nav

        mockVotingStateProvider.errorToThrow = HackersKitError.unauthenticated

        var post = Post(
            id: 1,
            url: URL(string: "https://example.com")!,
            title: "Post",
            age: "1h",
            commentsCount: 0,
            by: "user",
            score: 10,
            postType: .news,
            upvoted: false,
            voteLinks: VoteLinks(upvote: URL(string: "/vote?up"), unvote: nil)
        )

        // When
        await viewModel.upvote(post: &post)

        // Then
        #expect(mockVotingStateProvider.upvoteCalled, "Upvote should be attempted")
        #expect(mockAuth.logoutCalled, "Logout should be called on unauthenticated error")
        #expect(nav.showLoginCalled, "Navigation should prompt login")
        #expect(viewModel.lastError == nil, "Unauthenticated errors should prompt login instead of showing an alert")
        #expect(post.upvoted == false && post.score == 10, "Optimistic state should be reverted")
    }

    @Test("Post upvote synthesizes unvote URL when missing")
    @MainActor
    func postUpvoteSynthesizesUnvoteURL() async throws {
        mockVotingStateProvider.upvoteCalled = false

        var post = Post(
            id: 42,
            url: URL(string: "https://example.com")!,
            title: "Synth Test",
            age: "1h",
            commentsCount: 2,
            by: "tester",
            score: 5,
            postType: .news,
            upvoted: false,
            voteLinks: VoteLinks(
                upvote: URL(string: "https://news.ycombinator.com/vote?id=42&how=up&auth=abc123&goto=news")!,
                unvote: nil
            )
        )

        await votingViewModel.upvote(post: &post)

        #expect(mockVotingStateProvider.upvoteCalled, "Upvote should be attempted")

        guard let unvoteURL = post.voteLinks?.unvote else {
            Issue.record("Expected synthesized unvote URL")
            return
        }

        let absolute = unvoteURL.absoluteString
        #expect(absolute.contains("how=un"), "Unvote URL should set how=un")
        #expect(absolute.contains("auth=abc123"), "Unvote URL should preserve auth token")
        #expect(absolute.contains("goto=news"), "Unvote URL should preserve goto parameter")
    }

    // MARK: - Unvote Rejection Tests

    @Test("Successful post unvote clears unvote link")
    @MainActor
    func successfulPostUnvoteClearsUnvoteLink() async throws {
        var post = makeTestPost(upvoted: true)

        await votingViewModel.unvote(post: &post)

        #expect(post.upvoted == false, "Optimistic unvote should stand on success")
        #expect(post.score == 9, "Score should decrement on successful unvote")
        #expect(post.voteLinks?.unvote == nil, "Unvote link should be cleared after unvoting")
        #expect(votingViewModel.lastError == nil)
    }

    @Test("Failed post unvote restores upvoted state, score, and vote links")
    @MainActor
    func failedPostUnvoteRestoresState() async throws {
        mockVotingStateProvider.unvoteErrorToThrow = HackersKitError.requestFailure
        let viewModel = votingViewModel
        var post = makeTestPost(upvoted: true)

        await viewModel.unvote(post: &post)

        #expect(post.upvoted == true, "Vote must remain shown when HN doesn't process the unvote")
        #expect(post.score == 10, "Score must be restored when HN doesn't process the unvote")
        #expect(post.voteLinks?.unvote != nil, "Vote links must be restored so unvote can be retried")
        #expect(viewModel.lastError != nil, "Generic failure should surface an error")
    }

    @Test("Rejected post unvote stays upvoted and stops offering unvote")
    @MainActor
    func rejectedPostUnvoteDropsUnvoteLink() async throws {
        mockVotingStateProvider.unvoteErrorToThrow = HackersKitError.voteRejected
        let viewModel = votingViewModel
        var post = makeTestPost(upvoted: true)

        await viewModel.unvote(post: &post)

        #expect(post.upvoted == true, "HN kept the vote, so the UI must stay upvoted")
        #expect(post.score == 10, "Score must be restored when HN refuses the unvote")
        #expect(post.voteLinks?.upvote != nil)
        #expect(
            post.voteLinks?.unvote == nil,
            "Stale unvote affordance should be dropped once HN refuses it"
        )
        #expect(
            viewModel.lastError == nil,
            "A refused unvote should revert silently, without an alert"
        )
    }

    @Test("Rejected comment unvote stays upvoted and stops offering unvote")
    @MainActor
    func rejectedCommentUnvoteDropsUnvoteLink() async throws {
        mockCommentVotingStateProvider.unvoteErrorToThrow = HackersKitError.voteRejected
        let viewModel = votingViewModel
        let post = makeTestPost(upvoted: true)
        let comment = makeComment(id: 7)
            .with(upvoted: true)
            .with(
                voteLinks: VoteLinks(
                    upvote: URL(string: "/vote?id=7&how=up")!,
                    unvote: URL(string: "/vote?id=7&how=un&goto=item%3Fid%3D1")!
                )
            )
        var applied = comment

        await viewModel.unvote(comment: comment, in: post) { applied = $0 }

        #expect(applied.upvoted == true, "HN kept the vote, so the UI must stay upvoted")
        #expect(applied.voteLinks?.unvote == nil, "Stale unvote affordance should be dropped")
        #expect(applied.voteLinks?.upvote != nil)
        #expect(
            viewModel.lastError == nil,
            "A refused unvote should revert silently, without an alert"
        )
    }

    private func makeTestPost(upvoted: Bool) -> Post {
        Post(
            id: 1,
            url: URL(string: "https://example.com")!,
            title: "Post",
            age: "1h",
            commentsCount: 0,
            by: "user",
            score: 10,
            postType: .news,
            upvoted: upvoted,
            voteLinks: VoteLinks(
                upvote: URL(string: "/vote?id=1&how=up"),
                unvote: URL(string: "/vote?id=1&how=un&goto=news")
            )
        )
    }

    // MARK: - Comment Voting Tests

    @Test("Comment loading state is scoped per item")
    @MainActor
    func commentLoadingStateIsScopedPerItem() async throws {
        let provider = BlockingCommentVotingStateProvider()
        let viewModel = VotingViewModel(
            votingStateProvider: mockVotingStateProvider,
            commentVotingStateProvider: provider,
            authenticationUseCase: MockAuthenticationUseCase()
        )
        let firstComment = makeComment(id: 101)
        let secondComment = makeComment(id: 102)
        let post = Post(
            id: 200,
            url: URL(string: "https://example.com")!,
            title: "Test Post",
            age: "1h",
            commentsCount: 2,
            by: "author",
            score: 10,
            postType: .news,
            upvoted: false
        )

        let firstTask = Task { await viewModel.upvote(comment: firstComment, in: post) { _ in } }
        await waitUntilStarted(itemID: firstComment.id, provider: provider)

        #expect(viewModel.votingState(for: firstComment).isVoting)
        #expect(!viewModel.votingState(for: secondComment).isVoting)

        let secondTask = Task { await viewModel.upvote(comment: secondComment, in: post) { _ in } }
        await waitUntilStarted(itemID: secondComment.id, provider: provider)

        provider.finish(itemID: firstComment.id)
        await firstTask.value
        #expect(!viewModel.votingState(for: firstComment).isVoting)
        #expect(viewModel.votingState(for: secondComment).isVoting)
        #expect(viewModel.isVoting)

        provider.finish(itemID: secondComment.id)
        await secondTask.value
        #expect(!viewModel.isVoting)
    }

    @Test("Comment voting with MainActor")
    @MainActor
    func commentVotingWithMainActor() async throws {
        // Given
        let voteLinks = VoteLinks(upvote: URL(string: "/vote?up")!, unvote: nil)
        let comment = Domain.Comment(
            id: 123,
            age: "1h",
            text: "Test comment",
            by: "user",
            level: 0,
            upvoted: false,
            voteLinks: voteLinks,
        )

        let post = Post(
            id: 456,
            url: URL(string: "https://example.com")!,
            title: "Test Post",
            age: "2h",
            commentsCount: 1,
            by: "author",
            score: 10,
            postType: .news,
            upvoted: false,
        )

        // When - upvote comment (capture the applied optimistic state)
        var appliedComment: Domain.Comment?
        await votingViewModel.upvote(comment: comment, in: post) { appliedComment = $0 }

        // Then
        #expect(mockCommentVotingStateProvider.upvoteCommentCalled, "Upvote should be called")
        #expect(appliedComment?.upvoted == true, "Comment should be marked as upvoted after upvote")
    }

    private func makeComment(id: Int) -> Domain.Comment {
        Domain.Comment(
            id: id,
            age: "1h",
            text: "Test comment",
            by: "user",
            level: 0,
            upvoted: false,
            voteLinks: VoteLinks(upvote: URL(string: "/vote?up")!, unvote: nil)
        )
    }

    private func waitUntilStarted(
        itemID: Int,
        provider: BlockingCommentVotingStateProvider
    ) async {
        await provider.waitUntilStarted(itemID: itemID)
    }

    @Test("Comment upvote synthesizes unvote URL when missing")
    @MainActor
    func commentUpvoteSynthesizesUnvoteURL() async throws {
        mockCommentVotingStateProvider.shouldThrow = false
        mockCommentVotingStateProvider.upvoteCommentCalled = false

        let voteLinks = VoteLinks(
            upvote: URL(string: "vote?id=123&how=up&auth=xyz&goto=item%3Fid%3D456")!,
            unvote: nil
        )
        let comment = Domain.Comment(
            id: 123,
            age: "1h",
            text: "Test comment",
            by: "user",
            level: 0,
            upvoted: false,
            voteLinks: voteLinks
        )

        let post = Post(
            id: 456,
            url: URL(string: "https://example.com")!,
            title: "Test Post",
            age: "2h",
            commentsCount: 1,
            by: "author",
            score: 10,
            postType: .news,
            upvoted: false
        )

        var appliedComment: Domain.Comment?
        await votingViewModel.upvote(comment: comment, in: post) { appliedComment = $0 }

        #expect(mockCommentVotingStateProvider.upvoteCommentCalled, "Upvote should be attempted")
        guard let commentUnvote = appliedComment?.voteLinks?.unvote else {
            Issue.record("Expected synthesized unvote URL for comment")
            return
        }
        let absolute = commentUnvote.absoluteString
        #expect(absolute.contains("how=un"), "Unvote URL should use how=un")
        #expect(absolute.contains("auth=xyz"), "Auth token should be preserved")
    }

    @Test("Comment voting error handling")
    @MainActor
    func commentVotingErrorHandling() async throws {
        // Given
        let voteLinks = VoteLinks(upvote: URL(string: "/vote?up")!, unvote: nil)
        let comment = Domain.Comment(
            id: 123,
            age: "1h",
            text: "Test comment",
            by: "user",
            level: 0,
            upvoted: false,
            voteLinks: voteLinks,
        )

        let post = Post(
            id: 456,
            url: URL(string: "https://example.com")!,
            title: "Test Post",
            age: "2h",
            commentsCount: 1,
            by: "author",
            score: 10,
            postType: .news,
            upvoted: false,
        )

        mockCommentVotingStateProvider.shouldThrow = true
        let viewModel = votingViewModel

        // When - capture the last applied state (optimistic then revert)
        var appliedComment: Domain.Comment?
        await viewModel.upvote(comment: comment, in: post) { appliedComment = $0 }

        // Then - Should revert the optimistic update
        #expect(mockCommentVotingStateProvider.upvoteCommentCalled, "Upvote should be called")
        #expect(appliedComment?.upvoted == false, "Comment should be reverted to original state after error")
        #expect(viewModel.lastError != nil, "Error should be set")
    }
}

@Suite("NavigationStoreProtocol Default Behavior")
struct NavigationStoreProtocolDefaultsTests {
    final class RecordingNavigationStore: NavigationStoreProtocol, @unchecked Sendable {
        var selectedPost: Post?
        var selectedPostId: Int?
        var showingLogin: Bool = false
        var showingSettings: Bool = false

        var recordedURL: URL?
        var recordedPushFlag: Bool?
        var stubbedResult: Bool = false

        func showPost(_ post: Post) {
            selectedPost = post
            selectedPostId = post.id
        }

        func showPostLink(_ post: Post, presentation _: PostLinkPresentation) {
            selectedPost = post
            selectedPostId = post.id
        }

        func showPost(withId id: Int) {
            selectedPostId = id
            selectedPost = nil
        }

        func showLogin() { showingLogin = true }
        func showSettings() { showingSettings = true }
        func selectPostType(_: PostType) {}

        @MainActor
        func openURLInPrimaryContext(_ url: URL, pushOntoDetailStack: Bool) -> Bool {
            recordedURL = url
            recordedPushFlag = pushOntoDetailStack
            return stubbedResult
        }
    }

    @Test("Default openURLInPrimaryContext uses push flag")
    @MainActor
    func defaultConvenienceUsesPushFlag() {
        let store = RecordingNavigationStore()
        store.stubbedResult = true
        let targetURL = URL(string: "https://example.com/web")!

        let result = store.openURLInPrimaryContext(targetURL)

        #expect(result == true)
        #expect(store.recordedURL == targetURL)
        #expect(store.recordedPushFlag == true)
    }
}
