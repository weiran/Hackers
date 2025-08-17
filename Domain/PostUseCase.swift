import Foundation

public protocol PostUseCase: Sendable {
    func getPosts(type: PostType, page: Int, nextId: Int?) async throws -> [Post]
    func getPost(id: Int) async throws -> Post
}