#if DEBUG
import Domain
import Foundation
import Shared
import SwiftUI

enum UITestingBootstrap {
    private static let argument = "--ui-testing"
    static let postID = 48_007_145

    static var isEnabled: Bool {
        ProcessInfo.processInfo.arguments.contains(argument)
            || ProcessInfo.processInfo.environment["HACKERS_UI_TESTING"] == "1"
    }

    @MainActor
    static func configureIfNeeded() {
        guard isEnabled else { return }

        let settingsUseCase = UITestSettingsUseCase()
        let authenticationUseCase = UITestAuthenticationUseCase()
        let fixtures = UITestFixtures()
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

final class UITestFixtures: PostUseCase, CommentUseCase, SearchUseCase, @unchecked Sendable {
    private let posts: [Post]
    private let comments: [Comment]

    init() {
        comments = [
            Comment(
                id: 48_007_201,
                age: "17 minutes ago",
                text: "The most interesting detail is that service and installed-base work changes the economics.",
                by: "cassianoleal",
                level: 0,
                upvoted: false,
                voteLinks: VoteLinks(
                    upvote: URL(string: "https://news.ycombinator.com/vote?id=48007201&how=up&goto=item%3Fid%3D48007145"),
                    unvote: nil
                )
            ),
            Comment(
                id: 48_007_202,
                age: "11 minutes ago",
                text: "This is a useful snapshot for testing because it includes an outbound article and comments.",
                by: "layer8",
                level: 1,
                upvoted: false,
                voteLinks: VoteLinks(
                    upvote: URL(string: "https://news.ycombinator.com/vote?id=48007202&how=up&goto=item%3Fid%3D48007145"),
                    unvote: nil
                )
            ),
            Comment(
                id: 48_007_203,
                age: "6 minutes ago",
                text: "I would still want to compare this with ASML's latest annual report.",
                by: "throwaway42",
                level: 0,
                upvoted: false,
                voteLinks: nil
            )
        ]

        posts = [
            Post(
                id: 48_000_001,
                url: URL(string: "https://www.bbc.co.uk/news/articles/cn0p8yled1do")!,
                title: "GameStop makes $55.5B takeover offer for eBay",
                age: "36 minutes ago",
                commentsCount: 48,
                by: "vistapeak",
                score: 121,
                postType: .news,
                upvoted: false,
                voteLinks: VoteLinks(
                    upvote: URL(string: "https://news.ycombinator.com/vote?id=48000001&how=up&goto=news"),
                    unvote: nil
                )
            ),
            Post(
                id: UITestingBootstrap.postID,
                url: URL(string: "https://www.siliconimist.com/p/asmls-best-selling-product")!,
                title: "ASML's Best Selling Product Isn't What You Think It Is",
                age: "22 minutes ago",
                commentsCount: comments.count,
                by: "cassianoleal",
                score: 33,
                postType: .news,
                upvoted: false,
                voteLinks: VoteLinks(
                    upvote: URL(string: "https://news.ycombinator.com/vote?id=48007145&how=up&goto=news"),
                    unvote: nil
                ),
                comments: comments
            ),
            Post(
                id: 48_000_002,
                url: URL(string: "https://notepad-plus-plus.org/news/npp-trademark-infringement/")!,
                title: "Trademark Violation: Fake Notepad++ for Mac",
                age: "51 minutes ago",
                commentsCount: 19,
                by: "notepad_team",
                score: 84,
                postType: .news,
                upvoted: false,
                voteLinks: nil
            ),
            Post(
                id: 48_000_003,
                url: URL(string: "https://example.com/cia-magic-heartbeat-sensor")!,
                title: "Debunking the CIA's \"magic\" heartbeat sensor [video]",
                age: "1 hour ago",
                commentsCount: 7,
                by: "sensors",
                score: 42,
                postType: .news,
                upvoted: false,
                voteLinks: nil
            )
        ]
    }

    func getPosts(type: PostType, page: Int, nextId: Int?) async throws -> [Post] {
        guard page == 1, nextId == nil else { return [] }
        switch type {
        case .news, .best, .active:
            return posts
        case .newest:
            return posts.reversed()
        case .ask:
            return [askPost]
        case .show:
            return [showPost]
        case .jobs:
            return [jobPost]
        case .bookmarks:
            return []
        }
    }

    func getPost(id: Int) async throws -> Post {
        guard var post = posts.first(where: { $0.id == id }) ?? [askPost, showPost, jobPost].first(where: { $0.id == id }) else {
            throw HackersKitError.scraperError
        }
        post.comments = id == UITestingBootstrap.postID ? comments : []
        post.commentsCount = post.comments?.count ?? 0
        return post
    }

    func getComments(for post: Post) async throws -> [Comment] {
        try await getPost(id: post.id).comments ?? []
    }

    func searchPosts(query: String) async throws -> [Post] {
        let normalizedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !normalizedQuery.isEmpty else { return [] }
        return posts.filter { post in
            post.title.lowercased().contains(normalizedQuery)
                || post.by.lowercased().contains(normalizedQuery)
                || post.url.host?.lowercased().contains(normalizedQuery) == true
        }
    }

    private var askPost: Post {
        Post(
            id: 48_000_101,
            url: URL(string: "https://news.ycombinator.com/item?id=48000101")!,
            title: "Ask HN: What are you using for iOS UI testing in 2026?",
            age: "14 minutes ago",
            commentsCount: 5,
            by: "fixture_ask",
            score: 18,
            postType: .ask,
            upvoted: false
        )
    }

    private var showPost: Post {
        Post(
            id: 48_000_201,
            url: URL(string: "https://example.com/show-hn-offline-fixtures")!,
            title: "Show HN: Offline fixtures for deterministic mobile UI tests",
            age: "44 minutes ago",
            commentsCount: 12,
            by: "fixture_show",
            score: 67,
            postType: .show,
            upvoted: false
        )
    }

    private var jobPost: Post {
        Post(
            id: 48_000_301,
            url: URL(string: "https://example.com/jobs/ios-engineer")!,
            title: "Fixture Labs is hiring an iOS engineer",
            age: "2 hours ago",
            commentsCount: 0,
            by: "fixture_jobs",
            score: 1,
            postType: .jobs,
            upvoted: false
        )
    }
}

final class UITestSettingsUseCase: SettingsUseCase, @unchecked Sendable {
    var safariReaderMode = false
    var linkBrowserMode: LinkBrowserMode
    var showThumbnails = false
    var rememberFeedCategory = false
    var lastFeedCategory: PostType?
    var textSize: TextSize = .medium
    var compactFeedDesign = false
    var dimReadPosts = true

    init() {
        let mode = ProcessInfo.processInfo.environment["HACKERS_UI_LINK_BROWSER_MODE"]
        linkBrowserMode = mode == "inApp" ? .inAppBrowser : .customBrowser
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
    private var readIDs: Set<Int> = []

    func readPostIDs() async -> Set<Int> {
        lock.withLock { readIDs }
    }

    func markPostRead(id: Int) async {
        lock.withLock {
            readIDs.insert(id)
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

final class UITestVotingStateProvider: VoteUseCase, VotingStateProvider, CommentVotingStateProvider, @unchecked Sendable {
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
        lock.withLock { upvotedIDs.insert(post.id) }
    }

    func upvote(comment: Comment, for post: Post) async throws {
        lock.withLock { upvotedIDs.insert(comment.id) }
    }

    func unvote(post: Post) async throws {
        lock.withLock { upvotedIDs.remove(post.id) }
    }

    func unvote(comment: Comment, for post: Post) async throws {
        lock.withLock { upvotedIDs.remove(comment.id) }
    }

    func upvote(item: any Votable) async throws {
        lock.withLock { upvotedIDs.insert(item.id) }
    }

    func unvote(item: any Votable) async throws {
        lock.withLock { upvotedIDs.remove(item.id) }
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

struct UITestArticleContent: Equatable {
    let title: String
    let body: String
}

enum UITestArticleFixtures {
    static func article(for url: URL) -> UITestArticleContent? {
        guard UITestingBootstrap.isEnabled,
              url.host?.contains("siliconimist.com") == true
        else { return nil }
        return UITestArticleContent(
            title: "ASML's Best Selling Product Isn't What You Think It Is",
            body: "Fixture article loaded from the UI-test Hacker News snapshot."
        )
    }
}
#endif
