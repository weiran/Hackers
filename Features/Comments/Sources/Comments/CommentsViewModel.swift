//
//  CommentsViewModel.swift
//  Comments
//
//  Copyright © 2025 Weiran Zhang. All rights reserved.
//

import Combine
import Domain
import Foundation
import Shared
import SwiftUI

@Observable
public final class CommentsViewModel: @unchecked Sendable {
    public let postID: Int
    public var post: Post? {
        didSet {
            onPostUpdated?(post)
        }
    }
    public var visibleComments: [Comment] = []
    public var showThumbnails: Bool

    // Callback for when comments are loaded (used for HTML parsing in the view layer)
    public var onCommentsLoaded: (([Comment]) -> Void)?
    // Callback for when post is updated
    public var onPostUpdated: ((Post?) -> Void)?

    private let postUseCase: any PostUseCase
    private let commentUseCase: any CommentUseCase
    private let voteUseCase: any VoteUseCase
    private let commentsLoader: LoadingStateManager<[Comment]>
    private let settingsUseCase: any SettingsUseCase
    private let bookmarksController: BookmarksController
    private var settingsCancellable: AnyCancellable?
    private var bookmarksObservation: AnyCancellable?

    public var comments: [Comment] { commentsLoader.data }
    public var isLoading: Bool { commentsLoader.isLoading }
    public var error: Error? { commentsLoader.error }
    public private(set) var isPostLoading: Bool

    @MainActor
    public init(
        postID: Int,
        initialPost: Post? = nil,
        postUseCase: any PostUseCase = DependencyContainer.shared.getPostUseCase(),
        commentUseCase: any CommentUseCase = DependencyContainer.shared.getCommentUseCase(),
        voteUseCase: any VoteUseCase = DependencyContainer.shared.getVoteUseCase(),
        settingsUseCase: any SettingsUseCase = DependencyContainer.shared.getSettingsUseCase(),
        bookmarksController: BookmarksController? = nil
    ) {
        self.postID = postID
        post = initialPost
        isPostLoading = initialPost == nil
        self.postUseCase = postUseCase
        self.commentUseCase = commentUseCase
        self.voteUseCase = voteUseCase
        self.settingsUseCase = settingsUseCase
        self.bookmarksController = bookmarksController ?? DependencyContainer.shared.makeBookmarksController()
        showThumbnails = settingsUseCase.showThumbnails

        let initialComments = initialPost?.comments ?? []
        commentsLoader = LoadingStateManager(initialData: initialComments)
        commentsLoader.setLoadFunction(
            shouldSkipLoad: { [weak self] comments in
                guard let self else { return false }
                return !comments.isEmpty && post != nil
            },
            loadData: { [weak self] in
                try await self?.fetchComments() ?? []
            }
        )

        updateVisibleComments()

        settingsCancellable = NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self else { return }
                let currentValue = settingsUseCase.showThumbnails
                if self.showThumbnails != currentValue {
                    self.showThumbnails = currentValue
                }
            }

        bookmarksObservation = NotificationCenter.default.publisher(for: .bookmarksDidChange)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                guard let self else { return }
                guard let postId = notification.userInfo?["postId"] as? Int,
                      postId == self.postID,
                      let isBookmarked = notification.userInfo?["isBookmarked"] as? Bool
                else { return }
                if var currentPost = self.post {
                    currentPost.isBookmarked = isBookmarked
                    self.post = currentPost
                }
            }
    }

    @MainActor
    public convenience init(
        post: Post,
        postUseCase: any PostUseCase = DependencyContainer.shared.getPostUseCase(),
        commentUseCase: any CommentUseCase = DependencyContainer.shared.getCommentUseCase(),
        voteUseCase: any VoteUseCase = DependencyContainer.shared.getVoteUseCase(),
        settingsUseCase: any SettingsUseCase = DependencyContainer.shared.getSettingsUseCase(),
        bookmarksController: BookmarksController? = nil
    ) {
        self.init(
            postID: post.id,
            initialPost: post,
            postUseCase: postUseCase,
            commentUseCase: commentUseCase,
            voteUseCase: voteUseCase,
            settingsUseCase: settingsUseCase,
            bookmarksController: bookmarksController
        )
    }

    @MainActor
    public func loadComments() async {
        if post == nil {
            isPostLoading = true
        }
        if let currentPost = post {
            await bookmarksController.refreshBookmarks()
            var updatedPost = currentPost
            updatedPost.isBookmarked = bookmarksController.isBookmarked(currentPost.id)
            post = updatedPost
        }
        await commentsLoader.loadIfNeeded()
        updateVisibleComments()
    }

    @MainActor
    public func refreshComments() async {
        if post == nil {
            isPostLoading = true
        }
        await bookmarksController.refreshBookmarks()
        await commentsLoader.refresh()
        updateVisibleComments()
    }

    private func fetchComments() async throws -> [Comment] {
        do {
            let postWithComments = try await postUseCase.getPost(id: postID)
            await bookmarksController.refreshBookmarks()
            let annotatedPost = await MainActor.run {
                bookmarksController.annotatedPosts(from: [postWithComments]).first ?? postWithComments
            }
            let loadedComments = annotatedPost.comments ?? []
            let commentCountExcludingStoryText = loadedComments.count(where: { $0.id >= 0 })

            await MainActor.run {
                self.post = annotatedPost
                self.post?.commentsCount = commentCountExcludingStoryText
                self.isPostLoading = false
                self.onCommentsLoaded?(loadedComments)
            }

            return loadedComments
        } catch {
            await MainActor.run {
                self.isPostLoading = false
            }
            throw error
        }
    }

    @MainActor
    public func voteOnPost(upvote: Bool) async throws {
        guard upvote else { return }
        guard var currentPost = post else { return }

        currentPost.upvoted = true
        currentPost.score += 1
        post = currentPost

        do {
            try await voteUseCase.upvote(post: currentPost)
        } catch {
            currentPost.upvoted = false
            currentPost.score -= 1
            post = currentPost
            throw error
        }
    }

    @MainActor
    public func toggleBookmark() async -> Bool {
        guard let currentPost = post else { return false }
        let newState = await bookmarksController.toggle(post: currentPost)
        var updatedPost = currentPost
        updatedPost.isBookmarked = newState
        post = updatedPost
        return newState
    }

    @MainActor
    public func voteOnComment(_ comment: Comment, upvote: Bool) async throws {
        guard upvote else { return }
        guard let post else { return }

        comment.upvoted = true

        do {
            try await voteUseCase.upvote(comment: comment, for: post)
        } catch {
            comment.upvoted = false
            throw error
        }
    }

    @MainActor
    @discardableResult
    public func revealComment(withId id: Int) -> Bool {
        guard let index = comments.firstIndex(where: { $0.id == id }) else { return false }
        let targetComment = comments[index]
        targetComment.visibility = .visible

        if targetComment.level > 0 {
            ensureAncestorVisibility(forCommentAt: index)
        }

        updateVisibleComments()
        return true
    }

    @MainActor
    public func toggleCommentVisibility(_ comment: Comment) {
        let visible = comment.visibility == .visible
        comment.visibility = visible ? .compact : .visible

        if let commentIndex = indexOfComment(comment, source: comments) {
            let childrenCount = countChildren(comment)

            if childrenCount > 0 {
                for childIndex in 1 ... childrenCount {
                    let currentComment = comments[commentIndex + childIndex]

                    if visible, currentComment.visibility == .hidden { continue }

                    currentComment.visibility = visible ? .hidden : .visible
                }
            }
        }

        updateVisibleComments()
    }

    @MainActor
    @discardableResult
    public func hideCommentBranch(_ comment: Comment) -> Comment? {
        guard let rootIndex = indexOfVisibleRootComment(of: comment) else { return nil }

        let rootComment = visibleComments[rootIndex]
        toggleCommentVisibility(rootComment)
        return rootComment
    }

    private func updateVisibleComments() {
        visibleComments = comments.filter { $0.visibility != .hidden }
    }

    private func indexOfComment(_ comment: Comment, source: [Comment]) -> Int? {
        source.firstIndex(where: { $0.id == comment.id })
    }

    private func indexOfVisibleRootComment(of comment: Comment) -> Int? {
        guard let commentIndex = indexOfComment(comment, source: visibleComments) else { return nil }

        for index in (0 ... commentIndex).reversed() where visibleComments[index].level == 0 {
            return index
        }

        return nil
    }

    private func countChildren(_ comment: Comment) -> Int {
        guard let startIndex = indexOfComment(comment, source: comments) else { return 0 }
        let nextIndex = startIndex + 1
        var count = 0

        guard nextIndex < comments.count else {
            return 0
        }

        for index in nextIndex ..< comments.count {
            let currentComment = comments[index]
            if currentComment.level > comment.level {
                count += 1
            } else {
                break
            }
        }

        return count
    }

    private func ensureAncestorVisibility(forCommentAt index: Int) {
        var remainingLevel = comments[index].level
        guard remainingLevel > 0 else { return }

        var searchIndex = index - 1
        while searchIndex >= 0, remainingLevel > 0 {
            let candidate = comments[searchIndex]
            if candidate.level == remainingLevel - 1 {
                candidate.visibility = .visible
                remainingLevel -= 1
            }
            searchIndex -= 1
        }
    }
}
