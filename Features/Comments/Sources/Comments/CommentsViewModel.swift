import Foundation
import Domain
import Shared
import SwiftUI

@Observable
public final class CommentsViewModel: @unchecked Sendable {
    public var post: Post
    public var comments: [Comment] = []
    public var visibleComments: [Comment] = []
    public var isLoading = false
    public var error: Error?
    
    // Callback for when comments are loaded (used for HTML parsing in the view layer)
    public var onCommentsLoaded: (([Comment]) -> Void)?
    
    private let postUseCase: any PostUseCase
    private let commentUseCase: any CommentUseCase
    private let voteUseCase: any VoteUseCase
    
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
    }
    
    @MainActor
    public func loadComments() async {
        guard !isLoading else { return }
        
        isLoading = true
        error = nil
        
        do {
            let postWithComments = try await postUseCase.getPost(id: post.id)
            self.post = postWithComments
            
            let loadedComments = postWithComments.comments ?? []
            
            // Call the callback for HTML parsing if provided
            onCommentsLoaded?(loadedComments)
            
            self.comments = loadedComments
            updateVisibleComments()
            
            // Update the comments count with the actual number of comments
            self.post.commentsCount = loadedComments.count
            
            isLoading = false
        } catch {
            self.error = error
            isLoading = false
        }
    }
    
    @MainActor
    public func refreshComments() async {
        await loadComments()
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