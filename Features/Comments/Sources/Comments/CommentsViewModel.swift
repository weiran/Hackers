//
//  CommentsViewModel.swift
//  Comments
//
//  Copyright © 2025 Weiran Zhang. All rights reserved.
//

import Foundation
import Domain
import Shared
import SwiftUI

@Observable
public final class CommentsViewModel: @unchecked Sendable {
    public var post: Post
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

    public init(
        post: Post,
        postUseCase: any PostUseCase = DependencyContainer.shared.getPostUseCase(),
        commentUseCase: any CommentUseCase = DependencyContainer.shared.getCommentUseCase(),
        voteUseCase: any VoteUseCase = DependencyContainer.shared.getVoteUseCase()
    ) {
        self.post = post
        self.postUseCase = postUseCase
        self.commentUseCase = commentUseCase
        self.voteUseCase = voteUseCase
        self.commentsLoader = LoadingStateManager(initialData: [])

        // Set up the loading function after initialization
        commentsLoader.setLoadFunction(
            shouldSkipLoad: { !$0.isEmpty },
            loadData: { [weak self] in
                try await self?.fetchComments() ?? []
            }
        )
    }

    @MainActor
    public func loadComments() async {
        await commentsLoader.loadIfNeeded()
        updateVisibleComments()
    }

    @MainActor
    public func refreshComments() async {
        await commentsLoader.refresh()
        updateVisibleComments()
    }

    private func fetchComments() async throws -> [Comment] {
        do {
            let postWithComments = try await postUseCase.getPost(id: post.id)

            await MainActor.run {
                self.post = postWithComments
            }

            let loadedComments = postWithComments.comments ?? []

            // Call the callback for HTML parsing if provided
            await MainActor.run {
                onCommentsLoaded?(loadedComments)
            }

            // Update the comments count with the actual number of comments
            await MainActor.run {
                self.post.commentsCount = loadedComments.count
            }

            return loadedComments
        } catch {
            throw error
        }
    }

    @MainActor
    public func voteOnPost(upvote: Bool) async throws {
        post.upvoted = upvote
        post.score += upvote ? 1 : -1

        do {
            if upvote {
                try await voteUseCase.upvote(post: post)
            } else {
                try await voteUseCase.unvote(post: post)
            }
        } catch {
            post.upvoted = !upvote
            post.score += upvote ? -1 : 1
            throw error
        }
    }

    @MainActor
    public func voteOnComment(_ comment: Comment, upvote: Bool) async throws {
        comment.upvoted = upvote

        do {
            if upvote {
                try await voteUseCase.upvote(comment: comment, for: post)
            } else {
                try await voteUseCase.unvote(comment: comment, for: post)
            }
        } catch {
            comment.upvoted = !upvote
            throw error
        }
    }

    @MainActor
    public func toggleCommentVisibility(_ comment: Comment) {
        let visible = comment.visibility == .visible
        comment.visibility = visible ? .compact : .visible

        if let commentIndex = indexOfComment(comment, source: comments) {
            let childrenCount = countChildren(comment)

            if childrenCount > 0 {
                for childIndex in 1...childrenCount {
                    let currentComment = comments[commentIndex + childIndex]

                    if visible && currentComment.visibility == .hidden { continue }

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
        return source.firstIndex(where: { $0.id == comment.id })
    }

    private func indexOfVisibleRootComment(of comment: Comment) -> Int? {
        guard let commentIndex = indexOfComment(comment, source: visibleComments) else { return nil }

        for index in (0...commentIndex).reversed() where visibleComments[index].level == 0 {
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

        for index in nextIndex..<comments.count {
            let currentComment = comments[index]
            if currentComment.level > comment.level {
                count += 1
            } else {
                break
            }
        }

        return count
    }
}
