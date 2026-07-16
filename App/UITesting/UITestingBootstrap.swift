#if DEBUG
import Domain
import Foundation
import Shared
import SwiftUI

enum UITestingBootstrap {
    static let postID = UITestFixtureReference.screenshotPostID
    static let configuration: UITestLaunchConfiguration? = {
        do {
            return try UITestLaunchConfiguration.parse(
                environment: ProcessInfo.processInfo.environment
            )
        } catch {
            preconditionFailure("Invalid UI-test launch configuration: \(error)")
        }
    }()

    static let fixtures: UITestFixtures? = {
        guard let configuration else { return nil }
        let fixtures = UITestFixtures(profile: configuration.fixtureProfile)
        do {
            try fixtures.validate(configuration: configuration)
        } catch {
            preconditionFailure("Invalid UI-test fixture route: \(error)")
        }
        return fixtures
    }()

    static var isEnabled: Bool {
        configuration != nil
    }

    static var runtimePolicy: AppRuntimePolicy {
        isEnabled ? .automation : .standard
    }

    @MainActor
    static func configureIfNeeded() {
        guard configuration != nil, let fixtures else { return }

        let settingsUseCase = UITestSettingsUseCase()
        let authenticationUseCase = UITestAuthenticationUseCase()
        let bookmarksUseCase = UITestBookmarksUseCase()
        let readStatusUseCase = UITestReadStatusUseCase()
        let votingStateProvider = UITestVotingStateProvider()
        let bookmarksController = BookmarksController(bookmarksUseCase: bookmarksUseCase)
        let readStatusController = ReadStatusController(readStatusUseCase: readStatusUseCase)

        DependencyContainer.setOverrides(DependencyContainer.Overrides(
            postUseCase: { fixtures },
            voteUseCase: { votingStateProvider },
            commentUseCase: { fixtures },
            settingsUseCase: { settingsUseCase },
            bookmarksUseCase: { bookmarksUseCase },
            readStatusUseCase: { readStatusUseCase },
            searchUseCase: { fixtures },
            supportUseCase: { UITestSupportUseCase() },
            votingStateProvider: { votingStateProvider },
            commentVotingStateProvider: { votingStateProvider },
            authenticationUseCase: { authenticationUseCase },
            whatsNewUseCase: { UITestWhatsNewUseCase() },
            sessionService: { SessionService(authenticationUseCase: authenticationUseCase) },
            bookmarksController: { bookmarksController },
            readStatusController: { readStatusController }
        ))
    }
}
#endif
