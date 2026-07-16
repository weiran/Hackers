#if DEBUG
import Domain
import Foundation
import Shared
import SwiftUI

final class UITestSettingsUseCase: SettingsUseCase, @unchecked Sendable {
    var safariReaderMode = false
    var linkBrowserMode: LinkBrowserMode
    var showThumbnails: Bool
    var rememberFeedCategory = false
    var lastFeedCategory: PostType?
    var textSize: TextSize = .medium
    var compactFeedDesign = false
    var dimReadPosts: Bool

    init() {
        guard let configuration = UITestingBootstrap.configuration else {
            preconditionFailure("UI-test settings require an active launch configuration")
        }
        linkBrowserMode = configuration.browserMode
        showThumbnails = configuration.showThumbnails
        dimReadPosts = configuration.dimReadPosts
    }

    func clearCache() {}

    func cacheUsageBytes() async -> Int64 {
        0
    }
}

final class UITestBookmarksUseCase: BookmarksUseCase, @unchecked Sendable {
    private let lock = NSLock()
    private var postsByID: [Int: Post] = [:]

    func bookmarkedIDs() async -> Set<Int> {
        lock.withLock { Set(postsByID.keys) }
    }

    func bookmarkedPosts() async -> [Post] {
        lock.withLock { Array(postsByID.values).sorted { $0.id < $1.id } }
    }

    func toggleBookmark(post: Post) async throws -> Bool {
        lock.withLock {
            if postsByID[post.id] == nil {
                postsByID[post.id] = post
                return true
            }
            postsByID[post.id] = nil
            return false
        }
    }
}

final class UITestReadStatusUseCase: ReadStatusUseCase, @unchecked Sendable {
    private let lock = NSLock()
    private var readIDs: Set<Int>

    init() {
        readIDs = UITestingBootstrap.configuration?.readPostIDs ?? []
    }

    func readPostIDs() async -> Set<Int> {
        lock.withLock { readIDs }
    }

    func markPostRead(id: Int) async {
        lock.withLock {
            _ = readIDs.insert(id)
        }
    }
}

final class UITestAuthenticationUseCase: AuthenticationUseCase, @unchecked Sendable {
    private let lock = NSLock()
    private var user: User?

    func authenticate(username: String, password: String) async throws {
        guard username == "ui-user", password == "password" else {
            throw HackersKitError.authenticationError(error: .badCredentials)
        }
        lock.withLock {
            user = User(username: username, karma: 1_337, joined: Date(timeIntervalSince1970: 1_700_000_000))
        }
    }

    func logout() async throws {
        lock.withLock { user = nil }
    }

    func isAuthenticated() async -> Bool {
        lock.withLock { user != nil }
    }

    func getCurrentUser() async -> User? {
        lock.withLock { user }
    }
}

final class UITestVotingStateProvider: VoteUseCase,
    VotingStateProvider,
    CommentVotingStateProvider,
    @unchecked Sendable {
    private let lock = NSLock()
    private var upvotedIDs: Set<Int> = []

    func votingState(for item: any Votable) -> VotingState {
        let isUpvoted = lock.withLock { upvotedIDs.contains(item.id) || item.upvoted }
        let score = (item as? any ScoredVotable)?.score
        return VotingState(
            isUpvoted: isUpvoted,
            score: score.map { isUpvoted && !item.upvoted ? $0 + 1 : $0 },
            canVote: item.voteLinks?.upvote != nil && !isUpvoted,
            canUnvote: isUpvoted,
            isVoting: false
        )
    }

    func upvote(post: Post) async throws {
        lock.withLock { _ = upvotedIDs.insert(post.id) }
    }

    func upvote(comment: Comment, for post: Post) async throws {
        lock.withLock { _ = upvotedIDs.insert(comment.id) }
    }

    func unvote(post: Post) async throws {
        lock.withLock { _ = upvotedIDs.remove(post.id) }
    }

    func unvote(comment: Comment, for post: Post) async throws {
        lock.withLock { _ = upvotedIDs.remove(comment.id) }
    }

    func upvote(item: any Votable) async throws {
        lock.withLock { _ = upvotedIDs.insert(item.id) }
    }

    func unvote(item: any Votable) async throws {
        lock.withLock { _ = upvotedIDs.remove(item.id) }
    }

    func upvoteComment(_ comment: Comment, for post: Post) async throws {
        try await upvote(comment: comment, for: post)
    }

    func unvoteComment(_ comment: Comment, for post: Post) async throws {
        try await unvote(comment: comment, for: post)
    }
}

struct UITestWhatsNewUseCase: WhatsNewUseCase {
    func shouldShowWhatsNew(currentVersion: String, forceShow: Bool) -> Bool {
        forceShow
    }

    func markWhatsNewShown(for version: String) {}
}

struct UITestSupportUseCase: SupportUseCase {
    func availableProducts() async throws -> [SupportProduct] {
        []
    }

    func purchase(productId: String) async throws -> SupportPurchaseResult {
        .userCancelled
    }

    func restorePurchases() async throws -> SupportPurchaseResult {
        .userCancelled
    }

    func hasActiveSubscription(productId: String) async -> Bool {
        false
    }
}
#endif
