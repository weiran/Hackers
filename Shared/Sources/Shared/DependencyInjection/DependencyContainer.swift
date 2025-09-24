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
import os

public final class DependencyContainer: @unchecked Sendable {
    public static let shared = DependencyContainer()

    struct Overrides: @unchecked Sendable {
        var postUseCase: (() -> any PostUseCase)?
        var voteUseCase: (() -> any VoteUseCase)?
        var commentUseCase: (() -> any CommentUseCase)?
        var settingsUseCase: (() -> any SettingsUseCase)?
        var votingService: (() -> any VotingService)?
        var commentVotingService: (() -> any CommentVotingService)?
        var authenticationUseCase: (() -> any AuthenticationUseCase)?
        var onboardingUseCase: (() -> any OnboardingUseCase)?
        var sessionService: (@MainActor () -> SessionService)?
        var toastPresenter: (@MainActor () -> ToastPresenter)?
    }

    // Use type-level singletons to guarantee identity across access sites and threads
    private static let networkManager: NetworkManagerProtocol = NetworkManager()
    private static let postRepository: PostRepository = .init(networkManager: networkManager)
    private static let settingsRepository: SettingsRepository = .init()
    private static let votingService: VotingService = DefaultVotingService(voteUseCase: postRepository)
    private static let authenticationRepository: AuthenticationRepository =
        .init(networkManager: networkManager)
    private static let onboardingRepository: OnboardingRepository = .init()
    private static let overridesLock = OSAllocatedUnfairLock<Overrides?>(initialState: nil)
    private static var overrides: Overrides? {
        get { overridesLock.withLock { $0 } }
        set { overridesLock.withLock { $0 = newValue } }
    }

    @MainActor
    private lazy var toastPresenter = ToastPresenter()

    private init() {}

    public func getPostUseCase() -> any PostUseCase {
        Self.overrides?.postUseCase?() ?? Self.postRepository
    }

    public func getVoteUseCase() -> any VoteUseCase {
        Self.overrides?.voteUseCase?() ?? Self.postRepository
    }

    public func getCommentUseCase() -> any CommentUseCase {
        Self.overrides?.commentUseCase?() ?? Self.postRepository
    }

    public func getSettingsUseCase() -> any SettingsUseCase {
        Self.overrides?.settingsUseCase?() ?? Self.settingsRepository
    }

    public func getVotingService() -> any VotingService {
        Self.overrides?.votingService?() ?? Self.votingService
    }

    public func getCommentVotingService() -> any CommentVotingService {
        if let override = Self.overrides?.commentVotingService?() {
            return override
        }

        let votingService = getVotingService()
        if let commentVoting = votingService as? CommentVotingService {
            return commentVoting
        }

        fatalError("VotingService must conform to CommentVotingService")
    }

    public func getAuthenticationUseCase() -> any AuthenticationUseCase {
        Self.overrides?.authenticationUseCase?() ?? Self.authenticationRepository
    }

    public func getOnboardingUseCase() -> any OnboardingUseCase {
        Self.overrides?.onboardingUseCase?() ?? Self.onboardingRepository
    }

    @MainActor
    public func makeSessionService() -> SessionService {
        if let factory = Self.overrides?.sessionService {
            return factory()
        }
        return SessionService(authenticationUseCase: getAuthenticationUseCase())
    }

    @MainActor
    public func makeToastPresenter() -> ToastPresenter {
        if let factory = Self.overrides?.toastPresenter {
            return factory()
        }
        return toastPresenter
    }
}

// MARK: - Testing Support

extension DependencyContainer {
    static func setOverrides(_ overrides: Overrides?) {
        self.overrides = overrides
    }

    static func resetOverrides() {
        overrides = nil
    }
}
