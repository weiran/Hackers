import Foundation

public protocol VoteUseCase: Sendable {
    func upvote(post: Post) async throws
    func unvote(post: Post) async throws
    func upvote(comment: Comment, for post: Post) async throws
    func unvote(comment: Comment, for post: Post) async throws
}
