//
//  DependencyContainer.swift
//  Shared
//
//  Dependency injection container
//

import Foundation
import Domain
import Data
import Networking

public final class DependencyContainer: @unchecked Sendable {
    public static let shared = DependencyContainer()

    private lazy var networkManager: NetworkManagerProtocol = NetworkManager()
    private lazy var postRepository: PostRepository = PostRepository(networkManager: networkManager)
    private lazy var settingsRepository: SettingsRepository = SettingsRepository()

    private init() {}

    public func getPostUseCase() -> any PostUseCase {
        return postRepository
    }

    public func getVoteUseCase() -> any VoteUseCase {
        return postRepository
    }

    public func getCommentUseCase() -> any CommentUseCase {
        return postRepository
    }

    public func getSettingsUseCase() -> any SettingsUseCase {
        return settingsRepository
    }
}
