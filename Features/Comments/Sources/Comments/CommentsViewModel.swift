//
//  CommentsViewModel.swift
//  Comments
//
//  Copyright © 2025 Weiran Zhang. All rights reserved.
//

import Domain
import Foundation
import Shared
import SwiftUI

@Observable
public final class CommentsViewModel: @unchecked Sendable {
    public let postID: Int
    public var post: Post?
    public var visibleComments: [Comment] = []

    // Callback for when comments are loaded (used for HTML parsing in the view layer)
    public var onCommentsLoaded: (([Comment]) -> Void)?

    private let postUseCase: any PostUseCase
    private let commentUseCase: any CommentUseCase
    private let voteUseCase: any VoteUseCase
    private let commentsLoader: LoadingStateManager<[Comment]>

    public var comments: [Comment] { commentsLoader.data }
    public var isLoading: Bool { commentsLoader.isLoading }
    public var error: Error? { commentsLoader.error }
    public private(set) var isPostLoading: Bool

    public init(
        postID: Int,
        initialPost: Post? = nil,
        postUseCase: any PostUseCase = DependencyContainer.shared.getPostUseCase(),
        commentUseCase: any CommentUseCase = DependencyContainer.shared.getCommentUseCase(),
        voteUseCase: any VoteUseCase = DependencyContainer.shared.getVoteUseCase()
    ) {
        self.postID = postID
        post = initialPost
        isPostLoading = initialPost == nil
        self.postUseCase = postUseCase
        self.commentUseCase = commentUseCase
        self.voteUseCase = voteUseCase

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
    }

    public convenience init(
        post: Post,
        postUseCase: any PostUseCase = DependencyContainer.shared.getPostUseCase(),
        commentUseCase: any CommentUseCase = DependencyContainer.shared.getCommentUseCase(),
        voteUseCase: any VoteUseCase = DependencyContainer.shared.getVoteUseCase()
    ) {
        self.init(
            postID: post.id,
            initialPost: post,
            postUseCase: postUseCase,
            commentUseCase: commentUseCase,
            voteUseCase: voteUseCase
        )
    }

    @MainActor
    public func loadComments() async {
        if post == nil {
            isPostLoading = true
        }
        await commentsLoader.loadIfNeeded()
        updateVisibleComments()
    }

    @MainActor
    public func refreshComments() async {
        if post == nil {
            isPostLoading = true
        }
        await commentsLoader.refresh()
        updateVisibleComments()
    }

    private func fetchComments() async throws -> [Comment] {
        do {
            let postWithComments = try await postUseCase.getPost(id: postID)
            let loadedComments = postWithComments.comments ?? []
            let commentCountExcludingStoryText = loadedComments.count(where: { $0.id >= 0 })

            await MainActor.run {
                self.post = postWithComments
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
    public func hideCommentBranch(_ comment: Comment) {
        if let rootIndex = indexOfVisibleRootComment(of: comment) {
            let rootComment = visibleComments[rootIndex]
            toggleCommentVisibility(rootComment)
        }
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
