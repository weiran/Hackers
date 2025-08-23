import Foundation

public protocol CommentUseCase: Sendable {
    func getComments(for post: Post) async throws -> [Comment]
}
