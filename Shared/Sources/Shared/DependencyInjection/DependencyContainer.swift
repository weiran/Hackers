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

    public struct Overrides: @unchecked Sendable {
        public var postUseCase: (() -> any PostUseCase)?
        public var voteUseCase: (() -> any VoteUseCase)?
        public var commentUseCase: (() -> any CommentUseCase)?
        public var settingsUseCase: (() -> any SettingsUseCase)?
        public var bookmarksUseCase: (() -> any BookmarksUseCase)?
        public var readStatusUseCase: (() -> any ReadStatusUseCase)?
        public var searchUseCase: (() -> any SearchUseCase)?
        public var supportUseCase: (() -> any SupportUseCase)?
        public var votingStateProvider: (() -> any VotingStateProvider)?
        public var commentVotingStateProvider: (() -> any CommentVotingStateProvider)?
        public var authenticationUseCase: (() -> any AuthenticationUseCase)?
        public var whatsNewUseCase: (() -> any WhatsNewUseCase)?
        public var sessionService: (@MainActor () -> SessionService)?
        public var toastPresenter: (@MainActor () -> ToastPresenter)?
        public var bookmarksController: (@MainActor () -> BookmarksController)?
        public var readStatusController: (@MainActor () -> ReadStatusController)?

        public init(
            postUseCase: (() -> any PostUseCase)? = nil,
            voteUseCase: (() -> any VoteUseCase)? = nil,
            commentUseCase: (() -> any CommentUseCase)? = nil,
            settingsUseCase: (() -> any SettingsUseCase)? = nil,
            bookmarksUseCase: (() -> any BookmarksUseCase)? = nil,
            readStatusUseCase: (() -> any ReadStatusUseCase)? = nil,
            searchUseCase: (() -> any SearchUseCase)? = nil,
            supportUseCase: (() -> any SupportUseCase)? = nil,
            votingStateProvider: (() -> any VotingStateProvider)? = nil,
            commentVotingStateProvider: (() -> any CommentVotingStateProvider)? = nil,
            authenticationUseCase: (() -> any AuthenticationUseCase)? = nil,
            whatsNewUseCase: (() -> any WhatsNewUseCase)? = nil,
            sessionService: (@MainActor () -> SessionService)? = nil,
            toastPresenter: (@MainActor () -> ToastPresenter)? = nil,
            bookmarksController: (@MainActor () -> BookmarksController)? = nil,
            readStatusController: (@MainActor () -> ReadStatusController)? = nil
        ) {
            self.postUseCase = postUseCase
            self.voteUseCase = voteUseCase
            self.commentUseCase = commentUseCase
            self.settingsUseCase = settingsUseCase
            self.bookmarksUseCase = bookmarksUseCase
            self.readStatusUseCase = readStatusUseCase
            self.searchUseCase = searchUseCase
            self.supportUseCase = supportUseCase
            self.votingStateProvider = votingStateProvider
            self.commentVotingStateProvider = commentVotingStateProvider
            self.authenticationUseCase = authenticationUseCase
            self.whatsNewUseCase = whatsNewUseCase
            self.sessionService = sessionService
            self.toastPresenter = toastPresenter
            self.bookmarksController = bookmarksController
            self.readStatusController = readStatusController
        }
    }

    // Use type-level singletons to guarantee identity across access sites and threads
    private static let networkManager: NetworkManagerProtocol = NetworkManager()
    private static let postRepository: PostRepository = .init(networkManager: networkManager)
    private static let bookmarksRepository: BookmarksRepository = .init()
    private static let readStatusRepository: ReadStatusRepository = .init()
    private static let searchRepository: SearchRepository = .init()
    private static let settingsRepository: SettingsRepository = .init()
    private static let supportRepository: SupportPurchaseRepository = .init()
    private static let votingStateProvider: VotingStateProvider =
        DefaultVotingStateProvider(voteUseCase: postRepository)
    private static let authenticationRepository: AuthenticationRepository =
        .init(networkManager: networkManager)
    private static let whatsNewRepository: WhatsNewRepository = .init()
    private static let overridesLock = OSAllocatedUnfairLock<Overrides?>(initialState: nil)
    private static var overrides: Overrides? {
        get { overridesLock.withLock { $0 } }
        set { overridesLock.withLock { $0 = newValue } }
    }

    @MainActor
    private lazy var toastPresenter = ToastPresenter()
    @MainActor
    private lazy var bookmarksController = BookmarksController(bookmarksUseCase: getBookmarksUseCase())
    @MainActor
    private lazy var readStatusController = ReadStatusController(readStatusUseCase: getReadStatusUseCase())

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

    public func getReadStatusUseCase() -> any ReadStatusUseCase {
        Self.overrides?.readStatusUseCase?() ?? Self.readStatusRepository
    }

    public func getSearchUseCase() -> any SearchUseCase {
        Self.overrides?.searchUseCase?() ?? Self.searchRepository
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

    public func getWhatsNewUseCase() -> any WhatsNewUseCase {
        Self.overrides?.whatsNewUseCase?() ?? Self.whatsNewRepository
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

    @MainActor
    public func makeReadStatusController() -> ReadStatusController {
        if let factory = Self.overrides?.readStatusController {
            return factory()
        }
        return readStatusController
    }
}

// MARK: - Testing Support

extension DependencyContainer {
    public static func setOverrides(_ overrides: Overrides?) {
        self.overrides = overrides
    }

    public static func resetOverrides() {
        overrides = nil
    }
}
