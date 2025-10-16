//
//  DependencyContainerTests.swift
//  SharedTests
//
//  Copyright © 2025 Weiran Zhang. All rights reserved.
//

@testable import Data
@testable import Domain
import Foundation
@testable import Shared
import Testing

@Suite("DependencyContainer Overrides")
struct DependencyContainerTests {
    init() {
        DependencyContainer.resetOverrides()
    }

    @MainActor
    @Test("Overrides inject custom implementations")
    func overridesInjectCustomDependencies() async {
        let stubRepository = StubPostRepository()
        let stubSettings = StubSettingsUseCase()
        let stubVoting = StubVotingService()
        let stubAuth = StubAuthenticationUseCase()
        let stubOnboarding = StubOnboardingUseCase()
        let sessionService = SessionService(authenticationUseCase: stubAuth)
        let toastPresenter = ToastPresenter()

        DependencyContainer.setOverrides(
            DependencyContainer.Overrides(
                postUseCase: { stubRepository },
                voteUseCase: { stubRepository },
                commentUseCase: { stubRepository },
                settingsUseCase: { stubSettings },
                votingService: { stubVoting },
                commentVotingService: { stubVoting },
                authenticationUseCase: { stubAuth },
                onboardingUseCase: { stubOnboarding },
                sessionService: { sessionService },
                toastPresenter: { toastPresenter }
            )
        )

        let container = DependencyContainer.shared

        #expect((container.getPostUseCase() as? StubPostRepository) === stubRepository)
        #expect((container.getVoteUseCase() as? StubPostRepository) === stubRepository)
        #expect((container.getCommentUseCase() as? StubPostRepository) === stubRepository)
        #expect((container.getSettingsUseCase() as? StubSettingsUseCase) === stubSettings)
        #expect((container.getVotingService() as? StubVotingService) === stubVoting)
        #expect((container.getCommentVotingService() as? StubVotingService) === stubVoting)
        #expect((container.getAuthenticationUseCase() as? StubAuthenticationUseCase) === stubAuth)
        #expect((container.getOnboardingUseCase() as? StubOnboardingUseCase) === stubOnboarding)
        #expect(await container.makeSessionService() === sessionService)
        #expect(await container.makeToastPresenter() === toastPresenter)

        DependencyContainer.resetOverrides()
    }

    @Test("Resetting overrides restores default singleton graph")
    func resetOverridesRestoresDefaults() {
        DependencyContainer.resetOverrides()
        let container = DependencyContainer.shared

        let postUseCase1 = container.getPostUseCase()
        let postUseCase2 = container.getPostUseCase()
        #expect((postUseCase1 as? PostRepository) === (postUseCase2 as? PostRepository))
        #expect((container.getSettingsUseCase() as? SettingsRepository) != nil)
    }

    @Test("Default graph shares post repository across protocols")
    func defaultGraphSharesPostRepository() {
        DependencyContainer.resetOverrides()
        let container = DependencyContainer.shared

        let post = container.getPostUseCase()
        let vote = container.getVoteUseCase()
        let comment = container.getCommentUseCase()

        #expect((post as? PostRepository) === (vote as? PostRepository))
        #expect((vote as? PostRepository) === (comment as? PostRepository))
    }

    @MainActor
    @Test("Overrides can be partially specified without affecting defaults")
    func partialOverridesFallbackToDefaults() async {
        DependencyContainer.resetOverrides()
        let stubSettings = StubSettingsUseCase()
        DependencyContainer.setOverrides(
            DependencyContainer.Overrides(
                settingsUseCase: { stubSettings }
            )
        )

        let container = DependencyContainer.shared
        #expect((container.getSettingsUseCase() as? StubSettingsUseCase) === stubSettings)
        #expect((container.getPostUseCase() as? PostRepository) != nil)

        DependencyContainer.resetOverrides()
    }
}

// MARK: - Stubs

private final class StubPostRepository: PostUseCase, VoteUseCase, CommentUseCase, @unchecked Sendable {
    func getPosts(type _: PostType, page _: Int, nextId _: Int?) async throws -> [Post] { [] }
    func getPost(id _: Int) async throws -> Post { throw HackersKitError.scraperError }
    func getComments(for _: Post) async throws -> [Domain.Comment] { [] }
    func upvote(post _: Post) async throws {}
    func upvote(comment _: Domain.Comment, for _: Post) async throws {}
}

private final class StubSettingsUseCase: SettingsUseCase, @unchecked Sendable {
    var safariReaderMode: Bool = false
    var openInDefaultBrowser: Bool = false
    var showThumbnails: Bool = true
    var rememberLastPostType: Bool = false
    var lastPostType: PostType?
    var textSize: TextSize = .medium
    func clearCache() {}
    func cacheUsageBytes() async -> Int64 { 0 }
}

private final class StubVotingService: VotingService, CommentVotingService, @unchecked Sendable {
    func votingState(for item: any Votable) -> VotingState {
        VotingState(isUpvoted: item.upvoted, score: nil, canVote: true, isVoting: false)
    }

    func upvote(item _: any Votable) async throws {}
    func upvoteComment(_ comment: Domain.Comment, for _: Post) async throws {
        comment.upvoted = true
    }
}

private final class StubAuthenticationUseCase: AuthenticationUseCase, @unchecked Sendable {
    func authenticate(username _: String, password _: String) async throws {}
    func logout() async throws {}
    func isAuthenticated() async -> Bool { false }
    func getCurrentUser() async -> User? { nil }
}

private final class StubOnboardingUseCase: OnboardingUseCase, @unchecked Sendable {
    private var shouldShow = true

    func shouldShowOnboarding(currentVersion _: String, forceShow: Bool) -> Bool {
        forceShow || shouldShow
    }

    func markOnboardingShown(for _: String) {
        shouldShow = false
    }
}
