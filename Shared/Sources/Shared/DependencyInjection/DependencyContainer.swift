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

    // Use type-level singletons to guarantee identity across access sites and threads
    private static let networkManager: NetworkManagerProtocol = NetworkManager()
    private static let postRepository: PostRepository = PostRepository(networkManager: networkManager)
    private static let settingsRepository: SettingsRepository = SettingsRepository()
    private static let votingService: VotingService = DefaultVotingService(voteUseCase: postRepository)
    private static let authenticationRepository: AuthenticationRepository =
        AuthenticationRepository(networkManager: networkManager)

    private init() {}

    public func getPostUseCase() -> any PostUseCase {
        return Self.postRepository
    }

    public func getVoteUseCase() -> any VoteUseCase {
        return Self.postRepository
    }

    public func getCommentUseCase() -> any CommentUseCase {
        return Self.postRepository
    }

    public func getSettingsUseCase() -> any SettingsUseCase {
        return Self.settingsRepository
    }

    public func getVotingService() -> any VotingService {
        return Self.votingService
    }

    public func getCommentVotingService() -> any CommentVotingService {
        guard let defaultVotingService = Self.votingService as? DefaultVotingService else {
            fatalError("VotingService must be DefaultVotingService to conform to CommentVotingService")
        }
        return defaultVotingService
    }

    public func getAuthenticationUseCase() -> any AuthenticationUseCase {
        return Self.authenticationRepository
    }
}
