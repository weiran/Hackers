//
//  DependencyContainer.swift
//  Shared
//
//  Copyright © 2025 Weiran Zhang. All rights reserved.
//

import Data
import Domain
import Foundation
import Networking

public final class DependencyContainer: @unchecked Sendable {
    public static let shared = DependencyContainer()

    // Use type-level singletons to guarantee identity across access sites and threads
    private static let networkManager: NetworkManagerProtocol = NetworkManager()
    private static let postRepository: PostRepository = .init(networkManager: networkManager)
    private static let settingsRepository: SettingsRepository = .init()
    private static let votingService: VotingService = DefaultVotingService(voteUseCase: postRepository)
    private static let authenticationRepository: AuthenticationRepository =
        .init(networkManager: networkManager)
    private static let onboardingRepository: OnboardingRepository = .init()

    @MainActor
    private lazy var toastPresenter = ToastPresenter()

    private init() {}

    public func getPostUseCase() -> any PostUseCase {
        Self.postRepository
    }

    public func getVoteUseCase() -> any VoteUseCase {
        Self.postRepository
    }

    public func getCommentUseCase() -> any CommentUseCase {
        Self.postRepository
    }

    public func getSettingsUseCase() -> any SettingsUseCase {
        Self.settingsRepository
    }

    public func getVotingService() -> any VotingService {
        Self.votingService
    }

    public func getCommentVotingService() -> any CommentVotingService {
        guard let defaultVotingService = Self.votingService as? DefaultVotingService else {
            fatalError("VotingService must be DefaultVotingService to conform to CommentVotingService")
        }
        return defaultVotingService
    }

    public func getAuthenticationUseCase() -> any AuthenticationUseCase {
        Self.authenticationRepository
    }

    public func getOnboardingUseCase() -> any OnboardingUseCase {
        Self.onboardingRepository
    }

    @MainActor
    public func makeSessionService() -> SessionService {
        SessionService(authenticationUseCase: getAuthenticationUseCase())
    }

    @MainActor
    public func makeToastPresenter() -> ToastPresenter {
        toastPresenter
    }
}
