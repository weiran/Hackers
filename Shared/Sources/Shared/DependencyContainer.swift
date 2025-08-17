import Foundation
import Domain
import Data
import Networking

public final class DependencyContainer: Sendable {
    public static let shared = DependencyContainer()

    private let networkManager: NetworkManagerProtocol
    private let postRepository: PostRepository
    private let settingsRepository: SettingsRepository

    private init() {
        self.networkManager = NetworkManager()
        self.postRepository = PostRepository(networkManager: networkManager)
        self.settingsRepository = SettingsRepository()
    }

    public func getPostUseCase() -> PostUseCase {
        return postRepository
    }

    public func getVoteUseCase() -> VoteUseCase {
        return postRepository
    }

    public func getCommentUseCase() -> CommentUseCase {
        return postRepository
    }

    public func getSettingsUseCase() -> SettingsUseCase {
        return settingsRepository
    }
}