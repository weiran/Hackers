//
//  CommentsViewModel.swift
//  Comments
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
public final class CommentsViewModel: @unchecked Sendable {
    public let postID: Int
    public var post: Post? {
        didSet {
            onPostUpdated?(post)
        }
    }
    public var visibleComments: [Comment] = []
    public private(set) var visibleRevision = 0
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
    private var indexByID: [Int: Int] = [:]
    private var parentIndexByID: [Int: Int] = [:]
    private var subtreeEndIndexByID: [Int: Int] = [:]
    private var visibleSignature: [VisibleCommentSignature] = []

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
                return !comments.isEmpty
            },
            loadData: { [weak self] in
                try await self?.fetchComments() ?? []
            }
        )

        rebuildCommentIndexes()
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
        rebuildCommentIndexes()
        updateVisibleComments()
    }

    @MainActor
    public func refreshComments() async {
        if post == nil {
            isPostLoading = true
        }
        await bookmarksController.refreshBookmarks()
        await commentsLoader.refresh()
        rebuildCommentIndexes()
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
                self.post?.commentsCount = max(annotatedPost.commentsCount, commentCountExcludingStoryText)
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
        guard let index = indexByID[id] else { return false }
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

        if let commentIndex = indexByID[comment.id] {
            let subtreeEndIndex = subtreeEndIndexByID[comment.id] ?? (commentIndex + 1)

            if commentIndex + 1 < subtreeEndIndex {
                for childIndex in (commentIndex + 1) ..< subtreeEndIndex {
                    let currentComment = comments[childIndex]
                    if visible, currentComment.visibility == .hidden {
                        continue
                    }
                    currentComment.visibility = visible ? .hidden : .visible
                }
            }
        }

        updateVisibleComments()
    }

    @MainActor
    @discardableResult
    public func hideCommentBranch(_ comment: Comment) -> Comment? {
        guard let rootComment = visibleRootComment(of: comment) else { return nil }

        toggleCommentVisibility(rootComment)
        return rootComment
    }

    @MainActor
    public func nextVisibleCommentID(after commentID: Int?) -> Int? {
        guard !visibleComments.isEmpty else { return nil }
        guard let commentID,
              let index = visibleComments.firstIndex(where: { $0.id == commentID })
        else {
            return visibleComments.first?.id
        }

        let nextIndex = visibleComments.index(after: index)
        guard nextIndex < visibleComments.endIndex else { return nil }
        return visibleComments[nextIndex].id
    }

    @MainActor
    public func nextVisibleThreadID(after commentID: Int?) -> Int? {
        guard !visibleComments.isEmpty else { return nil }
        guard let commentID,
              let index = visibleComments.firstIndex(where: { $0.id == commentID })
        else {
            return visibleComments.first(where: { $0.level == 0 })?.id
        }

        let nextIndex = visibleComments.index(after: index)
        guard nextIndex < visibleComments.endIndex else { return nil }
        return visibleComments[nextIndex...].first(where: { $0.level == 0 })?.id
    }
}

private extension CommentsViewModel {
    struct VisibleCommentSignature: Equatable {
        let id: Int
        let visibility: CommentVisibilityType
    }

    func rebuildCommentIndexes() {
        indexByID = [:]
        parentIndexByID = [:]
        subtreeEndIndexByID = [:]

        var stack: [(index: Int, id: Int, level: Int)] = []
        for index in comments.indices {
            let comment = comments[index]
            indexByID[comment.id] = index

            while let last = stack.last, comment.level <= last.level {
                subtreeEndIndexByID[last.id] = index
                stack.removeLast()
            }

            if let parent = stack.last {
                parentIndexByID[comment.id] = parent.index
            }

            stack.append((index: index, id: comment.id, level: comment.level))
        }

        for item in stack {
            subtreeEndIndexByID[item.id] = comments.endIndex
        }
    }

    func updateVisibleComments() {
        let updatedComments = comments.filter { $0.visibility != .hidden }
        let updatedSignature = updatedComments.map {
            VisibleCommentSignature(id: $0.id, visibility: $0.visibility)
        }

        guard updatedSignature != visibleSignature else { return }
        visibleComments = updatedComments
        visibleSignature = updatedSignature
        visibleRevision += 1
    }

    func visibleRootComment(of comment: Comment) -> Comment? {
        guard let commentIndex = indexByID[comment.id] else { return nil }

        for index in (0 ... commentIndex).reversed()
            where comments[index].level == 0 && comments[index].visibility != .hidden {
            return comments[index]
        }

        return nil
    }

    func ensureAncestorVisibility(forCommentAt index: Int) {
        var currentCommentID = comments[index].id
        while let parentIndex = parentIndexByID[currentCommentID] {
            comments[parentIndex].visibility = .visible
            currentCommentID = comments[parentIndex].id
        }
    }
}
