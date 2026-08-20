//
//  CommentsViewModelTests.swift
//  CommentsTests
//
//  Copyright © 2025 Weiran Zhang. All rights reserved.
//

@testable import Comments
import Domain
import Foundation
import Shared
import Testing

@Suite("CommentsViewModel Tests")
struct CommentsViewModelTests {
    let mockPostUseCase: MockPostUseCase
    let mockCommentUseCase: MockCommentUseCase
    let mockVoteUseCase: MockVoteUseCase
    let mockBookmarksUseCase: MockBookmarksUseCase
    let bookmarksController: BookmarksController
    let testPost: Post
    let sut: CommentsViewModel

    @MainActor
    init() {
        mockPostUseCase = MockPostUseCase()
        mockCommentUseCase = MockCommentUseCase()
        mockVoteUseCase = MockVoteUseCase()
        mockBookmarksUseCase = MockBookmarksUseCase()
        bookmarksController = BookmarksController(bookmarksUseCase: mockBookmarksUseCase)

        testPost = Post(
            id: 1,
            url: URL(string: "https://example.com")!,
            title: "Test Post",
            age: "1 hour ago",
            commentsCount: 5,
            by: "testuser",
            score: 100,
            postType: .news,
            upvoted: false,
        )

        sut = CommentsViewModel(
            post: testPost,
            postUseCase: mockPostUseCase,
            commentUseCase: mockCommentUseCase,
            voteUseCase: mockVoteUseCase,
            settingsUseCase: StubSettingsUseCase(showThumbnails: true),
            bookmarksController: bookmarksController
        )
    }

    @Test("Initializes in loading state when post is absent")
    @MainActor
    func initializesWithoutPost() {
        // When
        let viewModel = CommentsViewModel(
            postID: 42,
            initialPost: nil,
            postUseCase: mockPostUseCase,
            commentUseCase: mockCommentUseCase,
            voteUseCase: mockVoteUseCase,
            settingsUseCase: StubSettingsUseCase(showThumbnails: true),
            bookmarksController: bookmarksController
        )

        // Then
        #expect(viewModel.post == nil)
        #expect(viewModel.isPostLoading)
        #expect(viewModel.comments.isEmpty)
    }

    // MARK: - Loading Comments Tests

    @Test("Loading comments successfully populates comments and visible comments")
    @MainActor
    func loadCommentsSuccess() async {
        // Given
        let expectedComments = createTestComments()
        let postWithComments = createPostWithComments(comments: expectedComments)
        mockPostUseCase.mockPost = postWithComments

        // When
        await sut.loadComments()

        // Then
        #expect(sut.comments.count == expectedComments.count)
        #expect(sut.visibleComments.count == expectedComments.count)
        #expect(!sut.isLoading)
        #expect(!sut.isPostLoading)
        #expect(sut.error == nil)
    }

    @Test("Loading comments calls onCommentsLoaded callback")
    @MainActor
    func loadCommentsCallsCallback() async {
        // Given
        let expectedComments = createTestComments()
        let postWithComments = createPostWithComments(comments: expectedComments)
        mockPostUseCase.mockPost = postWithComments

        var callbackCalled = false
        var receivedComments: [Domain.Comment] = []
        sut.onCommentsLoaded = { (comments: [Domain.Comment]) in
            callbackCalled = true
            receivedComments = comments
        }

        // When
        await sut.loadComments()

        // Then
        #expect(callbackCalled)
        #expect(receivedComments.count == expectedComments.count)
    }

    @Test("Loading comments handles failure gracefully")
    @MainActor
    func loadCommentsFailure() async {
        // Given
        mockPostUseCase.shouldThrowError = true

        // When
        await sut.loadComments()

        // Then
        #expect(sut.comments.isEmpty)
        #expect(sut.visibleComments.isEmpty)
        #expect(!sut.isLoading)
        #expect(!sut.isPostLoading)
        #expect(sut.error != nil)
    }

    @Test("Loading comments does not proceed when already loading")
    @MainActor
    func loadCommentsSkipsWhenAlreadyLoading() async {
        // Given - Create a slow-loading scenario
        mockPostUseCase.shouldDelay = true
        mockPostUseCase.getPostCallCount = 0

        // Start first load (but don't await it)
        let firstLoadTask = Task {
            await sut.loadComments()
        }

        // Wait until the first load has definitely entered the loading state.
        for _ in 0..<100 where !sut.isLoading {
            try? await Task.sleep(for: .milliseconds(1))
        }
        #expect(sut.isLoading)

        // When - Try to load again while first load is in progress
        await sut.loadComments()

        // Wait for first load to complete
        await firstLoadTask.value

        // Then - Should only have called getPost once
        #expect(mockPostUseCase.getPostCallCount == 1)
        mockPostUseCase.shouldDelay = false
    }

    @Test("Refreshing comments replaces data and clears loading flag")
    @MainActor
    func refreshCommentsUpdatesThread() async {
        let firstComment = createTestComment(id: 11, level: 0)
        let secondComment = createTestComment(id: 22, level: 0)
        mockPostUseCase.postQueue = [
            createPostWithComments(comments: [firstComment]),
            createPostWithComments(comments: [secondComment])
        ]

        let viewModel = CommentsViewModel(
            postID: testPost.id,
            initialPost: nil,
            postUseCase: mockPostUseCase,
            commentUseCase: mockCommentUseCase,
            voteUseCase: mockVoteUseCase,
            settingsUseCase: StubSettingsUseCase(showThumbnails: true),
            bookmarksController: BookmarksController(bookmarksUseCase: MockBookmarksUseCase())
        )

        await viewModel.loadComments()
        #expect(viewModel.comments.first?.id == 11)

        await viewModel.refreshComments()

        #expect(viewModel.comments.first?.id == 22)
        #expect(viewModel.isPostLoading == false)
        #expect(viewModel.error == nil)
    }

    @Test("Show thumbnails responds to settings notifications")
    @MainActor
    func showThumbnailsSyncsWithSettings() async throws {
        let settingsUseCase = StubSettingsUseCase(showThumbnails: false)
        let viewModel = CommentsViewModel(
            post: testPost,
            postUseCase: mockPostUseCase,
            commentUseCase: mockCommentUseCase,
            voteUseCase: mockVoteUseCase,
            settingsUseCase: settingsUseCase,
            bookmarksController: BookmarksController(bookmarksUseCase: mockBookmarksUseCase)
        )

        #expect(viewModel.showThumbnails == false)

        settingsUseCase.showThumbnails = true
        try await Task.sleep(for: .milliseconds(10))

        #expect(viewModel.showThumbnails == true)
    }

    @Test("Swipe collapse threads responds to settings notifications")
    @MainActor
    func swipeCollapseThreadsSyncsWithSettings() async throws {
        let settingsUseCase = StubSettingsUseCase(showThumbnails: true)
        let viewModel = CommentsViewModel(
            post: testPost,
            postUseCase: mockPostUseCase,
            commentUseCase: mockCommentUseCase,
            voteUseCase: mockVoteUseCase,
            settingsUseCase: settingsUseCase,
            bookmarksController: BookmarksController(bookmarksUseCase: mockBookmarksUseCase)
        )

        #expect(viewModel.swipeCollapseThreads == true)

        settingsUseCase.swipeCollapseThreads = false
        try await Task.sleep(for: .milliseconds(10))

        #expect(viewModel.swipeCollapseThreads == false)
    }

    @Test("Next comment button visibility responds to settings notifications")
    @MainActor
    func showNextCommentButtonSyncsWithSettings() async throws {
        let settingsUseCase = StubSettingsUseCase(showThumbnails: true)
        let viewModel = CommentsViewModel(
            post: testPost,
            postUseCase: mockPostUseCase,
            commentUseCase: mockCommentUseCase,
            voteUseCase: mockVoteUseCase,
            settingsUseCase: settingsUseCase,
            bookmarksController: BookmarksController(bookmarksUseCase: mockBookmarksUseCase)
        )

        #expect(viewModel.showNextCommentButton == true)

        settingsUseCase.showNextCommentButton = false
        try await Task.sleep(for: .milliseconds(10))

        #expect(viewModel.showNextCommentButton == false)
    }

    @Test("Bookmark notifications update local post state")
    @MainActor
    func bookmarkNotificationsUpdatePostState() async {
        var unbookmarkedPost = testPost
        unbookmarkedPost.isBookmarked = false
        let viewModel = CommentsViewModel(
            post: unbookmarkedPost,
            postUseCase: mockPostUseCase,
            commentUseCase: mockCommentUseCase,
            voteUseCase: mockVoteUseCase,
            settingsUseCase: StubSettingsUseCase(showThumbnails: true),
            bookmarksController: bookmarksController
        )

        #expect(viewModel.post?.isBookmarked == false)

        NotificationCenter.default.post(
            name: .bookmarksDidChange,
            object: nil,
            userInfo: ["postId": unbookmarkedPost.id, "isBookmarked": true]
        )
        await Task.yield()
        #expect(viewModel.post?.isBookmarked == true)

        NotificationCenter.default.post(
            name: .bookmarksDidChange,
            object: nil,
            userInfo: ["postId": unbookmarkedPost.id + 1, "isBookmarked": false]
        )
        await Task.yield()
        #expect(viewModel.post?.isBookmarked == true)

        NotificationCenter.default.post(
            name: .bookmarksDidChange,
            object: nil,
            userInfo: ["postId": unbookmarkedPost.id, "isBookmarked": false]
        )
        await Task.yield()
        #expect(viewModel.post?.isBookmarked == false)
    }

    // MARK: - Voting Tests

    @Test("Upvoting post updates state correctly", arguments: [
        (initial: false, upvote: true, expectedUpvoted: true, expectedScoreDelta: 1)
    ])
    @MainActor
    func voteOnPost(initial: Bool, upvote: Bool, expectedUpvoted: Bool, expectedScoreDelta: Int) async throws {
        // Given
        guard var post = sut.post else {
            #expect(false, "Expected post to be available during voteOnPost test")
            return
        }
        post.upvoted = initial
        let initialScore = post.score
        sut.post = post

        // When
        try await sut.voteOnPost(upvote: upvote)

        // Then
        #expect(sut.post?.upvoted == expectedUpvoted)
        #expect(sut.post?.score == initialScore + expectedScoreDelta)
        #expect(mockVoteUseCase.upvotePostCalled)
    }

    @Test("Failed vote on post reverts changes")
    @MainActor
    func voteOnPostFailureRevertsChanges() async {
        // Given
        mockVoteUseCase.shouldThrowError = true
        guard let initialPost = sut.post else {
            #expect(false, "Expected post to be available during voteOnPostFailureRevertsChanges test")
            return
        }
        let initialUpvoted = initialPost.upvoted
        let initialScore = initialPost.score

        // When & Then
        await #expect(throws: MockError.self) {
            try await sut.voteOnPost(upvote: true)
        }

        #expect(sut.post?.upvoted == initialUpvoted)
        #expect(sut.post?.score == initialScore)
    }

    @Test("replace(comment:) drives a visible re-render on a content-only change")
    @MainActor
    func replaceCommentBumpsVisibleRevision() async {
        // A vote changes a comment's `upvoted` without changing which comments are visible.
        // The visible-projection signature only tracks collapse state, so replace() must
        // force visibleComments to be reassigned and visibleRevision bumped, or the row
        // won't re-render.
        let comment = createTestComment(id: 1, upvoted: false)
        mockPostUseCase.mockPost = createPostWithComments(comments: [comment])
        await sut.loadComments()

        let revisionBefore = sut.visibleRevision
        let visibleUpvotedBefore = sut.visibleComments.first(where: { $0.id == 1 })?.upvoted

        sut.replace(comment: comment.with(upvoted: true))

        #expect(sut.visibleRevision > revisionBefore, "A content change must bump visibleRevision")
        #expect(visibleUpvotedBefore == false)
        let visibleUpvotedAfter = sut.visibleComments.first(where: { $0.id == 1 })?.upvoted
        #expect(visibleUpvotedAfter == true, "visibleComments must reflect the updated comment")
    }

    @Test("Upvoting a comment through VotingViewModel persists the upvoted state after voting completes")
    @MainActor
    func commentUpvoteThroughVotingViewModelSucceeds() async {
        // Mirrors CommentsContentView.upvoteComment: vote the loaded comment through
        // VotingViewModel, writing each state change back via replace(comment:).
        let comment = createTestComment(id: 1, upvoted: false)
        mockPostUseCase.mockPost = createPostWithComments(comments: [comment])
        await sut.loadComments()

        let provider = StubCommentVotingStateProvider()
        let votingViewModel = VotingViewModel(
            votingStateProvider: StubVotingStateProvider(),
            commentVotingStateProvider: provider,
            authenticationUseCase: StubAuthenticationUseCase()
        )
        let post = sut.post ?? testPost

        let tappedComment = sut.comment(withID: 1)
        #expect(tappedComment != nil, "The loaded comment must be resolvable by id")

        await votingViewModel.upvote(comment: tappedComment!, in: post) { updated in
            sut.replace(comment: updated)
        }

        #expect(provider.upvoteCalls == [1], "The vote request should run for the tapped comment")
        #expect(
            sut.visibleComments.first(where: { $0.id == 1 })?.upvoted == true,
            "After a successful vote the visible projection must show the upvoted state"
        )
        #expect(sut.comment(withID: 1)?.upvoted == true)
    }

    @Test("A failed comment vote reverts the optimistic upvoted state")
    @MainActor
    func commentUpvoteThroughVotingViewModelRevertsOnError() async {
        let comment = createTestComment(id: 1, upvoted: false)
        mockPostUseCase.mockPost = createPostWithComments(comments: [comment])
        await sut.loadComments()

        let provider = StubCommentVotingStateProvider()
        provider.errorToThrow = MockError.testError
        let votingViewModel = VotingViewModel(
            votingStateProvider: StubVotingStateProvider(),
            commentVotingStateProvider: provider,
            authenticationUseCase: StubAuthenticationUseCase()
        )
        let post = sut.post ?? testPost

        await votingViewModel.upvote(comment: sut.comment(withID: 1)!, in: post) { updated in
            sut.replace(comment: updated)
        }

        #expect(
            sut.visibleComments.first(where: { $0.id == 1 })?.upvoted == false,
            "A failed vote must leave the visible projection un-upvoted"
        )
    }

    // MARK: - Comment Visibility Tests

    @Suite("Comment Visibility")
    @MainActor
    struct CommentVisibilityTests {
        let mockPostUseCase: MockPostUseCase
        let mockCommentUseCase: MockCommentUseCase
        let mockVoteUseCase: MockVoteUseCase
        let mockBookmarksUseCase: MockBookmarksUseCase
        let testPost: Post
        let sut: CommentsViewModel

        init() {
            mockPostUseCase = MockPostUseCase()
            mockCommentUseCase = MockCommentUseCase()
            mockVoteUseCase = MockVoteUseCase()
            mockBookmarksUseCase = MockBookmarksUseCase()

            testPost = Post(
                id: 1,
                url: URL(string: "https://example.com")!,
                title: "Test",
                age: "1h",
                commentsCount: 0,
                by: "user",
                score: 0,
                postType: .news,
                upvoted: false,
            )

            sut = CommentsViewModel(
                post: testPost,
                postUseCase: mockPostUseCase,
                commentUseCase: mockCommentUseCase,
                voteUseCase: mockVoteUseCase,
                settingsUseCase: StubSettingsUseCase(showThumbnails: true),
                bookmarksController: BookmarksController(bookmarksUseCase: mockBookmarksUseCase)
            )
        }

        private func createTestComment(id: Int, level: Int = 0) -> Domain.Comment {
            Domain.Comment(
                id: id,
                age: "1 hour ago",
                text: "Test comment \(id)",
                by: "user\(id)",
                level: level,
                upvoted: false,
                visibility: Domain.CommentVisibilityType.visible,
            )
        }

        private func createPostWithComments(comments: [Domain.Comment]) -> Post {
            var post = testPost
            post.comments = comments.isEmpty ? nil : comments
            return post
        }

        @Test("Toggle comment from visible to compact hides children")
        @MainActor
        func toggleVisibleToCompact() async {
            // Given - Set up mock to return comments
            let parentComment = createTestComment(id: 1, level: 0)
            let childComment = createTestComment(id: 2, level: 1)
            let testPostWithComments = createPostWithComments(comments: [parentComment, childComment])
            mockPostUseCase.mockPost = testPostWithComments

            // Load comments
            await sut.loadComments()

            // Verify initial state
            #expect(sut.comments.count == 2)
            let loadedParent = sut.comments.first(where: { $0.id == 1 })!
            let loadedChild = sut.comments.first(where: { $0.id == 2 })!

            #expect(loadedParent.visibility == Domain.CommentVisibilityType.visible)
            #expect(loadedChild.visibility == Domain.CommentVisibilityType.visible)

            // When
            sut.toggleCommentVisibility(loadedParent)

            // Then - re-fetch owned copies since Comment is now a value type
            let toggledParent = sut.comments.first(where: { $0.id == 1 })!
            #expect(toggledParent.visibility == Domain.CommentVisibilityType.compact)
            #expect(loadedChild.visibility == Domain.CommentVisibilityType.visible)
            #expect(sut.isCommentCollapsed(withID: loadedParent.id))
            #expect(!sut.isCommentCollapsed(withID: loadedChild.id))
            #expect(sut.visibleComments.count == 1)
        }

        @Test("Toggle comment from compact to visible shows children")
        @MainActor
        func toggleCompactToVisible() async {
            // Given - Set up mock with comments in compact state
            let parentComment = createTestComment(id: 1, level: 0)
                .withVisibility(Domain.CommentVisibilityType.compact)
            let childComment = createTestComment(id: 2, level: 1)
                .withVisibility(Domain.CommentVisibilityType.hidden)

            let testPostWithComments = createPostWithComments(comments: [parentComment, childComment])
            mockPostUseCase.mockPost = testPostWithComments

            // Load comments
            await sut.loadComments()

            // Verify initial state
            let loadedParent = sut.comments.first(where: { $0.id == 1 })!
            let loadedChild = sut.comments.first(where: { $0.id == 2 })!

            // When
            sut.toggleCommentVisibility(loadedParent)

            // Then - re-fetch owned copy since Comment is now a value type
            let toggledParent = sut.comments.first(where: { $0.id == 1 })!
            #expect(toggledParent.visibility == Domain.CommentVisibilityType.visible)
            #expect(loadedChild.visibility == Domain.CommentVisibilityType.visible)
            #expect(!sut.isCommentCollapsed(withID: loadedParent.id))
            #expect(sut.visibleComments.count == 2)
        }

        @Test("Flagged placeholder starts collapsed and reveals its replies")
        @MainActor
        func flaggedPlaceholderStartsCollapsed() async {
            let flaggedComment = Domain.Comment(
                id: 1,
                age: "1 hour ago",
                text: "[flagged]",
                by: "flagged-user",
                isFlagged: true,
                level: 1,
                upvoted: false,
                visibility: .compact,
            )
            let reply = createTestComment(id: 2, level: 2)
            mockPostUseCase.mockPost = createPostWithComments(comments: [flaggedComment, reply])

            await sut.loadComments()

            #expect(sut.visibleComments.map(\.id) == [flaggedComment.id])
            #expect(sut.isCommentCollapsed(withID: flaggedComment.id))

            sut.toggleCommentVisibility(flaggedComment)

            #expect(sut.visibleComments.map(\.id) == [flaggedComment.id, reply.id])
        }

        @Test("Toggle uses indexed subtree bounds without hiding following siblings")
        @MainActor
        func toggleUsesIndexedSubtreeBounds() async {
            let parentComment = createTestComment(id: 1, level: 0)
            let childComment = createTestComment(id: 2, level: 1)
            let grandchildComment = createTestComment(id: 3, level: 2)
            let siblingComment = createTestComment(id: 4, level: 0)

            mockPostUseCase.mockPost = createPostWithComments(
                comments: [parentComment, childComment, grandchildComment, siblingComment]
            )

            await sut.loadComments()

            let loadedParent = sut.comments.first(where: { $0.id == 1 })!
            let loadedSibling = sut.comments.first(where: { $0.id == 4 })!

            sut.toggleCommentVisibility(loadedParent)

            // Re-fetch owned copy since Comment is now a value type.
            let toggledParent = sut.comments.first(where: { $0.id == 1 })!
            #expect(toggledParent.visibility == .compact)
            #expect(loadedSibling.visibility == .visible)
            #expect(!sut.isCommentCollapsed(withID: loadedSibling.id))
            #expect(sut.visibleComments.map(\.id) == [1, 4])
        }

        @Test("Toggle by ID resolves current loaded comment")
        @MainActor
        func toggleByIDResolvesCurrentComment() async {
            let parentComment = createTestComment(id: 1, level: 0)
            let childComment = createTestComment(id: 2, level: 1)
            mockPostUseCase.mockPost = createPostWithComments(comments: [parentComment, childComment])

            await sut.loadComments()

            let staleParent = createTestComment(id: 1, level: 0)

            sut.toggleCommentVisibility(staleParent)

            // Re-fetch owned copy since Comment is now a value type.
            let toggledParent = sut.comments.first(where: { $0.id == 1 })!
            #expect(toggledParent.visibility == .compact)
            #expect(staleParent.visibility == .visible)
            #expect(sut.isCommentCollapsed(withID: toggledParent.id))
            #expect(sut.visibleComments.map(\.id) == [1])

            let reverted = sut.toggleCommentVisibility(withID: 1)

            #expect(reverted?.id == toggledParent.id)
            let expandedParent = sut.comments.first(where: { $0.id == 1 })!
            #expect(expandedParent.visibility == .visible)
            #expect(!sut.isCommentCollapsed(withID: expandedParent.id))
            #expect(sut.visibleComments.map(\.id) == [1, 2])
            #expect(sut.toggleCommentVisibility(withID: 999) == nil)
        }

        @Test("Visible revision advances only when visible signature changes")
        @MainActor
        func visibleRevisionTracksSignatureChanges() async {
            let parentComment = createTestComment(id: 1, level: 0)
            let childComment = createTestComment(id: 2, level: 1)
            mockPostUseCase.mockPost = createPostWithComments(comments: [parentComment, childComment])

            await sut.loadComments()

            let loadedParent = sut.comments.first(where: { $0.id == 1 })!
            let revisionAfterLoad = sut.visibleRevision

            sut.toggleCommentVisibility(loadedParent)
            let revisionAfterToggle = sut.visibleRevision

            let missingReveal = sut.revealComment(withId: 999)

            #expect(revisionAfterToggle == revisionAfterLoad + 1)
            #expect(!missingReveal)
            #expect(sut.visibleRevision == revisionAfterToggle)
        }

        @Test("Hide comment branch collapses entire tree")
        @MainActor
        func hideCommentBranch() async {
            // Given - Set up mock with comment hierarchy
            let rootComment = createTestComment(id: 1, level: 0)
            let childComment1 = createTestComment(id: 2, level: 1)
            let childComment2 = createTestComment(id: 3, level: 2)

            let testPostWithComments = createPostWithComments(comments: [rootComment, childComment1, childComment2])
            mockPostUseCase.mockPost = testPostWithComments

            // Load comments
            await sut.loadComments()

            // Verify initial state
            #expect(sut.comments.count == 3)
            let loadedChild2 = sut.comments.first(where: { $0.id == 3 })!

            // When
            let collapsedRoot = sut.hideCommentBranch(loadedChild2)

            // Then
            let loadedRoot = sut.comments.first(where: { $0.id == 1 })!
            let loadedChild1 = sut.comments.first(where: { $0.id == 2 })!

            #expect(collapsedRoot?.id == loadedRoot.id)
            #expect(loadedRoot.visibility == Domain.CommentVisibilityType.compact)
            #expect(loadedChild1.visibility == Domain.CommentVisibilityType.visible)
            #expect(loadedChild2.visibility == Domain.CommentVisibilityType.visible)
            #expect(sut.isCommentCollapsed(withID: loadedRoot.id))
            #expect(sut.visibleComments.count == 1)
        }

        @Test("Reveal comment shows hidden ancestors")
        @MainActor
        func revealCommentUnhidesAncestors() async {
            // Given - Comment chain with collapsed ancestors
            let rootComment = createTestComment(id: 1, level: 0)
                .withVisibility(.compact)
            let childComment = createTestComment(id: 2, level: 1)
                .withVisibility(.hidden)
            let grandchildComment = createTestComment(id: 3, level: 2)
                .withVisibility(.hidden)

            let post = createPostWithComments(comments: [rootComment, childComment, grandchildComment])
            mockPostUseCase.mockPost = post

            await sut.loadComments()

            // When
            let revealed = sut.revealComment(withId: 3)

            // Then
            #expect(revealed)
            let loadedRoot = sut.comments.first(where: { $0.id == 1 })!
            let loadedChild = sut.comments.first(where: { $0.id == 2 })!
            let loadedGrandchild = sut.comments.first(where: { $0.id == 3 })!

            #expect(loadedRoot.visibility == .visible)
            #expect(loadedChild.visibility == .visible)
            #expect(loadedGrandchild.visibility == .visible)
            #expect(!sut.isCommentCollapsed(withID: loadedRoot.id))
            #expect(sut.visibleComments.contains(where: { $0.id == 3 }))
        }

        @Test("Nested collapsed child stays collapsed after parent collapse and expand")
        @MainActor
        func nestedCollapsedChildPersistsThroughParentToggle() async {
            let rootComment = createTestComment(id: 1, level: 0)
            let childComment = createTestComment(id: 2, level: 1)
            let grandchildComment = createTestComment(id: 3, level: 2)

            mockPostUseCase.mockPost = createPostWithComments(comments: [rootComment, childComment, grandchildComment])

            await sut.loadComments()

            let loadedRoot = sut.comments.first(where: { $0.id == 1 })!
            let loadedChild = sut.comments.first(where: { $0.id == 2 })!

            sut.toggleCommentVisibility(loadedChild)
            #expect(sut.visibleComments.map(\.id) == [1, 2])

            sut.toggleCommentVisibility(loadedRoot)
            #expect(sut.visibleComments.map(\.id) == [1])

            sut.toggleCommentVisibility(loadedRoot)
            #expect(sut.visibleComments.map(\.id) == [1, 2])
            #expect(sut.isCommentCollapsed(withID: 2))
        }

        @Test("Next visible comment advances through visible projection")
        @MainActor
        func nextVisibleCommentID() async {
            let firstRoot = createTestComment(id: 1, level: 0)
            let child = createTestComment(id: 2, level: 1)
            let secondRoot = createTestComment(id: 3, level: 0)
            mockPostUseCase.mockPost = createPostWithComments(comments: [firstRoot, child, secondRoot])

            await sut.loadComments()

            #expect(sut.nextVisibleCommentID(after: nil) == 1)
            #expect(sut.nextVisibleCommentID(after: 1) == 2)
            #expect(sut.nextVisibleCommentID(after: 2) == 3)
            #expect(sut.nextVisibleCommentID(after: 3) == nil)
        }

        @Test("Next visible thread skips descendants")
        @MainActor
        func nextVisibleThreadID() async {
            let firstRoot = createTestComment(id: 1, level: 0)
            let child = createTestComment(id: 2, level: 1)
            let secondRoot = createTestComment(id: 3, level: 0)
            mockPostUseCase.mockPost = createPostWithComments(comments: [firstRoot, child, secondRoot])

            await sut.loadComments()

            #expect(sut.nextVisibleThreadID(after: nil) == 1)
            #expect(sut.nextVisibleThreadID(after: 1) == 3)
            #expect(sut.nextVisibleThreadID(after: 2) == 3)
            #expect(sut.nextVisibleThreadID(after: 3) == nil)
        }

        @Test("Root separator follows visible adjacency")
        @MainActor
        func rootSeparatorFollowsVisibleAdjacency() async {
            let firstRoot = createTestComment(id: 1, level: 0)
            let child = createTestComment(id: 2, level: 1)
            let secondRoot = createTestComment(id: 3, level: 0)
            mockPostUseCase.mockPost = createPostWithComments(comments: [firstRoot, child, secondRoot])

            await sut.loadComments()

            #expect(!sut.showsRootSeparator(afterCommentID: 1))
            #expect(sut.showsRootSeparator(afterCommentID: 2))
            #expect(!sut.showsRootSeparator(afterCommentID: 3))
            #expect(!sut.showsRootSeparator(afterCommentID: 999))

            sut.toggleCommentVisibility(withID: 1)

            #expect(sut.visibleComments.map(\.id) == [1, 3])
            #expect(sut.showsRootSeparator(afterCommentID: 1))
            #expect(!sut.showsRootSeparator(afterCommentID: 3))
        }
    }

    // MARK: - Helper Methods

    private func createTestComments() -> [Domain.Comment] {
        [
            createTestComment(id: 1, level: 0),
            createTestComment(id: 2, level: 1),
            createTestComment(id: 3, level: 1),
            createTestComment(id: 4, level: 2),
            createTestComment(id: 5, level: 0),
        ]
    }

    private func createTestComment(id: Int, level: Int = 0, upvoted: Bool = false) -> Domain.Comment {
        Domain.Comment(
            id: id,
            age: "1 hour ago",
            text: "Test comment \(id)",
            by: "user\(id)",
            level: level,
            upvoted: upvoted,
            visibility: Domain.CommentVisibilityType.visible,
        )
    }

    private func createPostWithComments(comments: [Domain.Comment]) -> Post {
        var post = testPost
        post.comments = comments.isEmpty ? nil : comments
        return post
    }
}

// MARK: - Mock Classes

final class MockPostUseCase: PostUseCase, @unchecked Sendable {
    var mockPost: Post?
    var shouldThrowError = false
    var shouldDelay = false
    var getPostCallCount = 0
    var postQueue: [Post] = []

    func getPost(id: Int) async throws -> Post {
        getPostCallCount += 1
        if shouldDelay {
            try await Task.sleep(for: .milliseconds(100))
        }
        if shouldThrowError {
            throw MockError.testError
        }
        if !postQueue.isEmpty {
            return postQueue.removeFirst()
        }
        return mockPost ?? Post(
            id: id,
            url: URL(string: "https://example.com")!,
            title: "Mock Post",
            age: "1 hour ago",
            commentsCount: 0,
            by: "mockuser",
            score: 0,
            postType: .news,
            upvoted: false,
        )
    }

    func getPosts(type _: PostType, page _: Int, nextId _: Int?) async throws -> [Post] {
        []
    }
}

final class MockCommentUseCase: CommentUseCase, @unchecked Sendable {
    func getComments(for _: Post) async throws -> [Domain.Comment] {
        []
    }
}

final class MockBookmarksUseCase: BookmarksUseCase, @unchecked Sendable {
    var posts: [Post] = []
    var toggleCalls: [Int] = []
    var shouldThrow = false

    func bookmarkedIDs() async -> Set<Int> {
        Set(posts.map(\.id))
    }

    func bookmarkedPosts() async -> [Post] {
        posts
    }

    @discardableResult
    func toggleBookmark(post: Post) async throws -> Bool {
        toggleCalls.append(post.id)
        if shouldThrow {
            throw MockError.testError
        }
        if let index = posts.firstIndex(where: { $0.id == post.id }) {
            posts.remove(at: index)
            return false
        } else {
            var mutablePost = post
            mutablePost.isBookmarked = true
            posts.append(mutablePost)
            return true
        }
    }
}

final class MockVoteUseCase: VoteUseCase, @unchecked Sendable {
    var upvotePostCalled = false
    var upvoteCommentCalled = false
    var shouldThrowError = false

    func upvote(post _: Post) async throws {
        upvotePostCalled = true
        if shouldThrowError {
            throw MockError.testError
        }
    }

    func upvote(comment _: Domain.Comment, for _: Post) async throws {
        upvoteCommentCalled = true
        if shouldThrowError {
            throw MockError.testError
        }
    }

    func unvote(post _: Post) async throws {
        if shouldThrowError {
            throw MockError.testError
        }
    }

    func unvote(comment _: Domain.Comment, for _: Post) async throws {
        if shouldThrowError {
            throw MockError.testError
        }
    }
}

final class StubSettingsUseCase: SettingsUseCase, @unchecked Sendable {
    var safariReaderMode: Bool = false
    var linkBrowserMode: LinkBrowserMode = .inAppBrowser
    private var storedShowThumbnails: Bool
    private var storedRememberFeedCategory: Bool = false
    private var storedLastFeedCategory: PostType?
    var textSize: TextSize = .medium
    var compactFeedDesign: Bool = false
    var dimReadPosts: Bool = true
    private var storedSwipeCollapseThreads: Bool = true
    private var storedShowNextCommentButton: Bool = true

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

    var swipeCollapseThreads: Bool {
        get { storedSwipeCollapseThreads }
        set {
            storedSwipeCollapseThreads = newValue
            NotificationCenter.default.post(name: UserDefaults.didChangeNotification, object: nil)
        }
    }

    var showNextCommentButton: Bool {
        get { storedShowNextCommentButton }
        set {
            storedShowNextCommentButton = newValue
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

    func clearCache() async {}

    func cacheUsageBytes() async -> Int64 { 0 }
}

final class StubAuthenticationUseCase: AuthenticationUseCase, @unchecked Sendable {
    func authenticate(username _: String, password _: String) async throws {}
    func logout() async throws {}
    func isAuthenticated() async -> Bool { false }
    func getCurrentUser() async -> User? { nil }
}

final class StubVotingStateProvider: VotingStateProvider, @unchecked Sendable {
    func votingState(for item: any Votable) -> VotingState {
        VotingState(
            isUpvoted: item.upvoted,
            score: (item as? any ScoredVotable)?.score,
            canVote: item.voteLinks?.upvote != nil,
            canUnvote: item.voteLinks?.unvote != nil
        )
    }

    func upvote(item _: any Votable) async throws {}
    func unvote(item _: any Votable) async throws {}
}

final class StubCommentVotingStateProvider: CommentVotingStateProvider, @unchecked Sendable {
    var upvoteCalls: [Int] = []
    var errorToThrow: Error?

    func upvoteComment(_ comment: Domain.Comment, for _: Post) async throws {
        upvoteCalls.append(comment.id)
        if let errorToThrow {
            throw errorToThrow
        }
    }

    func unvoteComment(_ comment: Domain.Comment, for _: Post) async throws {}
}

enum MockError: Error {
    case testError
}

// Helper function to create test comment outside of struct
private func createTestComment(id: Int, level: Int = 0, upvoted: Bool = false) -> Domain.Comment {
    Domain.Comment(
        id: id,
        age: "1 hour ago",
        text: "Test comment \(id)",
        by: "user\(id)",
        level: level,
        upvoted: upvoted,
        visibility: .visible,
    )
}
