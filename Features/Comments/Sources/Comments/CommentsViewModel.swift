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
    private var visibleIndexByID: [Int: Int] = [:]
    private var visibleSignature: [VisibleCommentSignature] = []
    private var collapsedCommentIDs: Set<Int> = []

    public var comments: [Comment] { commentsLoader.data }
    public var isLoading: Bool { commentsLoader.isLoading }
    public var error: Error? { commentsLoader.error }
    public private(set) var isPostLoading: Bool

    /// Mutable access to the loaded comments for value-type updates (visibility, voting).
    /// `comments` is read-only; mutating state goes through here so changes also trigger
    /// the visible-projection refresh where appropriate.
    private var allComments: [Comment] {
        get { commentsLoader.data }
        set { commentsLoader.data = newValue }
    }

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
            shouldSkipLoad: { comments in !comments.isEmpty },
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
    @discardableResult
    public func revealComment(withId id: Int) -> Bool {
        guard let index = indexByID[id] else { return false }
        let targetComment = allComments[index]
        collapsedCommentIDs.remove(targetComment.id)
        allComments[index] = targetComment.withVisibility(.visible)

        if targetComment.level > 0 {
            ensureAncestorVisibility(forCommentAt: index)
        }

        updateVisibleComments()
        return true
    }

    @MainActor
    public func toggleCommentVisibility(_ comment: Comment) {
        _ = toggleCommentVisibility(withID: comment.id)
    }

    @MainActor
    @discardableResult
    public func toggleCommentVisibility(withID id: Int) -> Comment? {
        guard let index = indexByID[id] else { return nil }
        let comment = allComments[index]
        let updated: Comment
        if collapsedCommentIDs.contains(comment.id) {
            collapsedCommentIDs.remove(comment.id)
            updated = comment.withVisibility(.visible)
        } else {
            collapsedCommentIDs.insert(comment.id)
            updated = comment.withVisibility(.compact)
        }
        allComments[index] = updated

        updateVisibleComments()
        return updated
    }

    @MainActor
    public func comment(withID id: Int) -> Comment? {
        guard let index = indexByID[id] else { return nil }
        return comments[index]
    }

    /// Writes an updated comment back into the loaded set by id, used for value-type
    /// optimistic updates (voting) where the caller cannot mutate a shared instance.
    ///
    /// Unlike collapse/expand, a vote changes a comment's content (e.g. `upvoted`) without
    /// changing which comments are visible. The visible-projection signature only tracks
    /// collapse state, so we must force `visibleComments` to be reassigned and
    /// `visibleRevision` bumped or the row won't re-render.
    @MainActor
    public func replace(comment updated: Comment) {
        guard let index = indexByID[updated.id], allComments.indices.contains(index) else { return }
        allComments[index] = updated
        rebuildVisibleComments(forceRevisionBump: true)
    }

    @MainActor
    public func visibleComment(withID id: Int) -> Comment? {
        guard let index = visibleIndexByID[id] else { return nil }
        return visibleComments[index]
    }

    @MainActor
    public func isCommentCollapsed(withID id: Int) -> Bool {
        collapsedCommentIDs.contains(id)
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
        guard let commentID, let index = visibleIndexByID[commentID] else {
            return visibleComments.first?.id
        }

        let nextIndex = visibleComments.index(after: index)
        guard nextIndex < visibleComments.endIndex else { return nil }
        return visibleComments[nextIndex].id
    }

    @MainActor
    public func hasNextVisibleComment(after commentID: Int?) -> Bool {
        nextVisibleCommentID(after: commentID) != nil
    }

    @MainActor
    public func showsRootSeparator(afterCommentID commentID: Int) -> Bool {
        guard let index = visibleIndexByID[commentID] else { return false }

        let nextIndex = visibleComments.index(after: index)
        guard nextIndex < visibleComments.endIndex else { return false }

        return visibleComments[nextIndex].level == 0
    }

    @MainActor
    public func nextVisibleThreadID(after commentID: Int?) -> Int? {
        guard !visibleComments.isEmpty else { return nil }
        guard let commentID, let index = visibleIndexByID[commentID] else {
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

        var validCommentIDs = Set<Int>()
        var stack: [(index: Int, id: Int, level: Int)] = []
        // Mutate a local copy and assign once: writing through the allComments computed
        // setter per-element is O(n) each (whole-array copy) and fragile if the accessor
        // ever stops returning the live backing array.
        var updated = allComments
        var didUpdate = false
        for index in updated.indices {
            let comment = updated[index]
            validCommentIDs.insert(comment.id)
            indexByID[comment.id] = index
            if comment.visibility == .compact {
                collapsedCommentIDs.insert(comment.id)
            } else if comment.visibility == .hidden {
                updated[index] = comment.withVisibility(.visible)
                didUpdate = true
            }

            while let last = stack.last, comment.level <= last.level {
                stack.removeLast()
            }

            if let parent = stack.last {
                parentIndexByID[comment.id] = parent.index
            }

            stack.append((index: index, id: comment.id, level: comment.level))
        }

        if didUpdate { allComments = updated }
        collapsedCommentIDs.formIntersection(validCommentIDs)
    }

    func updateVisibleComments() {
        rebuildVisibleComments(forceRevisionBump: false)
    }

    /// Rebuilds `visibleComments` from the full comment list. When `forceRevisionBump` is
    /// false (collapse/expand path), it skips the work when only the collapse signature is
    /// unchanged. When true (voting/content-update path), it always reassigns
    /// `visibleComments` and bumps `visibleRevision` because a comment's content changed
    /// even though its presence/visibility did not.
    func rebuildVisibleComments(forceRevisionBump: Bool) {
        var updatedComments: [Comment] = []
        var hiddenUntilLevel: Int?

        for comment in comments {
            if let hiddenLevel = hiddenUntilLevel {
                guard comment.level <= hiddenLevel else { continue }
                hiddenUntilLevel = nil
            }

            updatedComments.append(comment)

            if collapsedCommentIDs.contains(comment.id) {
                hiddenUntilLevel = comment.level
            }
        }

        let updatedSignature = updatedComments.map { comment in
            VisibleCommentSignature(
                id: comment.id,
                visibility: collapsedCommentIDs.contains(comment.id) ? .compact : .visible
            )
        }

        if !forceRevisionBump, updatedSignature == visibleSignature {
            return
        }
        visibleComments = updatedComments
        visibleIndexByID = Dictionary(uniqueKeysWithValues: updatedComments.enumerated().map { index, comment in
            (comment.id, index)
        })
        visibleSignature = updatedSignature
        visibleRevision += 1
    }

    func visibleRootComment(of comment: Comment) -> Comment? {
        guard let commentIndex = indexByID[comment.id] else { return nil }

        for index in (0 ... commentIndex).reversed()
            where comments[index].level == 0 {
            return comments[index]
        }

        return nil
    }

    func ensureAncestorVisibility(forCommentAt index: Int) {
        // Mutate a local copy and assign once for the same reason as rebuildCommentIndexes.
        var updated = allComments
        var currentCommentID = updated[index].id
        while let parentIndex = parentIndexByID[currentCommentID] {
            let parent = updated[parentIndex]
            collapsedCommentIDs.remove(parent.id)
            updated[parentIndex] = parent.withVisibility(.visible)
            currentCommentID = parent.id
        }
        allComments = updated
    }
}
