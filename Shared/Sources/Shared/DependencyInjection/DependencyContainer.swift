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
        var bookmarksUseCase: (() -> any BookmarksUseCase)?
        var supportUseCase: (() -> any SupportUseCase)?
        var votingStateProvider: (() -> any VotingStateProvider)?
        var commentVotingStateProvider: (() -> any CommentVotingStateProvider)?
        var authenticationUseCase: (() -> any AuthenticationUseCase)?
        var onboardingUseCase: (() -> any OnboardingUseCase)?
        var sessionService: (@MainActor () -> SessionService)?
        var toastPresenter: (@MainActor () -> ToastPresenter)?
        var bookmarksController: (@MainActor () -> BookmarksController)?
    }

    // Use type-level singletons to guarantee identity across access sites and threads
    private static let networkManager: NetworkManagerProtocol = NetworkManager()
    private static let postRepository: PostRepository = .init(networkManager: networkManager)
    private static let bookmarksRepository: BookmarksRepository = .init()
    private static let settingsRepository: SettingsRepository = .init()
    private static let supportRepository: SupportPurchaseRepository = .init()
    private static let votingStateProvider: VotingStateProvider =
        DefaultVotingStateProvider(voteUseCase: postRepository)
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
    @MainActor
    private lazy var bookmarksController = BookmarksController(bookmarksUseCase: getBookmarksUseCase())

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

    public func getBookmarksUseCase() -> any BookmarksUseCase {
        Self.overrides?.bookmarksUseCase?() ?? Self.bookmarksRepository
    }

    public func getSupportUseCase() -> any SupportUseCase {
        Self.overrides?.supportUseCase?() ?? Self.supportRepository
    }

    public func getVotingStateProvider() -> any VotingStateProvider {
        Self.overrides?.votingStateProvider?() ?? Self.votingStateProvider
    }

    public func getCommentVotingStateProvider() -> any CommentVotingStateProvider {
        if let override = Self.overrides?.commentVotingStateProvider?() {
            return override
        }

        let votingStateProvider = getVotingStateProvider()
        if let commentVoting = votingStateProvider as? CommentVotingStateProvider {
            return commentVoting
        }

        fatalError("VotingStateProvider must conform to CommentVotingStateProvider")
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

    @MainActor
    public func makeBookmarksController() -> BookmarksController {
        if let factory = Self.overrides?.bookmarksController {
            return factory()
        }
        return bookmarksController
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
