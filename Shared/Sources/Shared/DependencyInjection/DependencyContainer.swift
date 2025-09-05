//
//  DependencyContainer.swift
//  Shared
//
//  Copyright © 2025 Weiran Zhang. All rights reserved.
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
    private lazy var votingService: VotingService = DefaultVotingService(voteUseCase: postRepository)

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

    public func getVotingService() -> any VotingService {
        return votingService
    }

    public func getCommentVotingService() -> any CommentVotingService {
        guard let defaultVotingService = votingService as? DefaultVotingService else {
            fatalError("VotingService must be DefaultVotingService to conform to CommentVotingService")
        }
        return defaultVotingService
    }
}
