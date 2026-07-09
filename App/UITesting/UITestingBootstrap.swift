#if DEBUG
import Domain
import Foundation
import Shared
import SwiftUI

// swiftlint:disable type_body_length function_body_length

enum UITestingBootstrap {
    private static let argument = "--ui-testing"
    static let postID = 48_350_598

    static var isEnabled: Bool {
        ProcessInfo.processInfo.arguments.contains(argument)
            || ProcessInfo.processInfo.environment["HACKERS_UI_TESTING"] == "1"
    }

    static var isScreenshotMode: Bool {
        ProcessInfo.processInfo.arguments.contains("--screenshots")
            || ProcessInfo.processInfo.environment["HACKERS_SCREENSHOTS"] == "1"
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
    static let largeCommentsPostID = 48_399_999

    private let posts: [Post]
    private let commentsByPostID: [Int: [Comment]]

    init() {
        commentsByPostID = Self.makeCommentsByPostID()
        posts = Self.makeActivePosts()
    }

    private static func makeActivePosts() -> [Post] {
        [
            makePost(
                id: largeCommentsPostID,
                url: "https://example.com/ui-test-large-comments",
                title: "UI Test: Large Comments Performance Fixture",
                age: "1 minute ago",
                commentsCount: 720,
                by: "perf_fixture",
                score: 999
            ),
            makePost(
                id: 48_345_248,
                url: "https://simpleflying.com/united-airlines-767-returns-newark-bluetooth-name-alert/",
                title: "United Airlines 767 returns to Newark after Bluetooth name sparks alert",
                age: "21 hours ago",
                commentsCount: 689,
                by: "Eridanus2",
                score: 355
            ),
            makePost(
                id: 48_347_354,
                url: "https://techcrunch.com/2026/05/27/meta-officially-launches-instagram-facebook-and-whatsapp-subscriptions-with-more-to-come-including-ai-plans/",
                title: "Meta launches Instagram, Facebook, and WhatsApp subscriptions",
                age: "16 hours ago",
                commentsCount: 354,
                by: "tambourine_man",
                score: 224
            ),
            makePost(
                id: 48_345_840,
                url: "https://hacktivis.me/articles/cloudflare-turnstile-webgl-fingerprinting",
                title: "Cloudflare Turnstile requiring fingerprintable WebGL",
                age: "19 hours ago",
                commentsCount: 366,
                by: "HypnoticOcelot",
                score: 675
            ),
            makePost(
                id: UITestingBootstrap.postID,
                url: "https://www.swift.org/blog/swift-6.2-released/",
                title: "Swift 6.2 Released",
                age: "10 hours ago",
                commentsCount: 202,
                by: "swiftlang",
                score: 279
            ),
            makePost(
                id: 48_349_527,
                url: "https://arstechnica.com/health/2026/05/us-healthcare-still-stupidly-expensive-with-pathetic-outcomes-study-finds/",
                title: "US healthcare still stupidly expensive, with pathetic outcomes, study finds",
                age: "13 hours ago",
                commentsCount: 161,
                by: "rbanffy",
                score: 142
            ),
            makePost(
                id: 48_353_497,
                url: "https://apnews.com/article/malaysia-social-media-ban-16-bfaa7b01163b61b5d53c4ecfa870d133",
                title: "Malaysia enforces ban on social media accounts for children younger than 16",
                age: "2 hours ago",
                commentsCount: 104,
                by: "01-_-",
                score: 118
            ),
            makePost(
                id: 48_346_257,
                url: "https://prismml.com/news/bonsai-image-4b",
                title: "1-Bit Bonsai Image 4B Image Generation for Local Devices",
                age: "18 hours ago",
                commentsCount: 153,
                by: "modinfo",
                score: 388
            ),
            makePost(
                id: 48_348_864,
                url: "https://variety.com/2026/film/box-office/backrooms-box-office-record-opening-weekend-obsession-jumps-star-wars-crumbles-1236763355/",
                title: "'Backrooms' Stuns with $81M Debut",
                age: "14 hours ago",
                commentsCount: 125,
                by: "mindcrime",
                score: 198
            ),
            makePost(
                id: 48_350_149,
                url: "https://mail.cyberneticforests.com/its-not-just-data-its-post-training/",
                title: "It's Not Just X. It's Y",
                age: "12 hours ago",
                commentsCount: 128,
                by: "mooreds",
                score: 158
            ),
            makePost(
                id: 48_345_896,
                url: "https://thoughts.hmmz.org/2026-05-31.html",
                title: "The solution might be cancelling my AI subscription",
                age: "19 hours ago",
                commentsCount: 229,
                by: "dmw_ng",
                score: 360
            ),
            makePost(
                id: 48_345_282,
                url: "https://paulgraham.com/boss.html",
                title: "You weren't meant to have a boss (2008)",
                age: "21 hours ago",
                commentsCount: 155,
                by: "downbad_",
                score: 133
            ),
            makePost(
                id: 48_344_961,
                url: "https://jbkempf.com/blog/2026/dav2d/",
                title: "Dav2d",
                age: "22 hours ago",
                commentsCount: 173,
                by: "captain_bender",
                score: 487
            ),
            makePost(
                id: 48_349_487,
                url: "https://www.promptarmor.com/resources/gpt-for-google-sheets-data-exfiltration",
                title: "ChatGPT for Google Sheets exfiltrates workbooks",
                age: "13 hours ago",
                commentsCount: 75,
                by: "hackerBanana",
                score: 216
            ),
            makePost(
                id: 48_345_694,
                url: "https://blog.tymscar.com/posts/v100localllm/",
                title: "I put a datacenter GPU in my gaming PC",
                age: "20 hours ago",
                commentsCount: 171,
                by: "birdculture",
                score: 305
            ),
            makePost(
                id: 48_352_939,
                url: "https://www.nvidia.com/en-us/products/rtx-spark/",
                title: "Nvidia RTX Spark",
                age: "4 hours ago",
                commentsCount: 65,
                by: "shenli3514",
                score: 72
            ),
            makePost(
                id: 48_350_131,
                url: "https://peninsulaforeveryone.org/blog/atherton-spent-145k-to-delay-caltrain-electrification-the-rest-of-us-paid-400-million-and-waited-3-extra-years/",
                title: "Atherton spent $145K to delay train electrification. The rest of us paid $400M",
                age: "12 hours ago",
                commentsCount: 91,
                by: "mslate",
                score: 194
            ),
            makePost(
                id: 48_347_153,
                url: "https://darylcecile.net/notes/speed-of-prototyping-age-of-ai",
                title: "The Speed of Prototyping in the Age of AI",
                age: "17 hours ago",
                commentsCount: 83,
                by: "mooreds",
                score: 163
            ),
            makePost(
                id: 48_340_411,
                url: "https://www.brethorsting.com/blog/2026/05/domain-expertise-has-always-been-the-real-moat/",
                title: "Domain expertise has always been the real moat",
                age: "1 day ago",
                commentsCount: 526,
                by: "aaronbrethorst",
                score: 834
            ),
            makePost(
                id: 48_352_627,
                url: "https://blogs.windows.com/devices/2026/05/31/introducing-surface-laptop-ultra-made-for-world-makers/",
                title: "Surface Laptop Ultra: Made for World Makers",
                age: "5 hours ago",
                commentsCount: 56,
                by: "berlianta",
                score: 30
            ),
            makePost(
                id: 48_343_683,
                url: "https://specification.website/",
                title: "The Website Specification",
                age: "1 day ago",
                commentsCount: 200,
                by: "k1m",
                score: 501
            ),
            makePost(
                id: 48_346_693,
                url: "https://github.com/pewdiepie-archdaemon/odysseus",
                title: "Odysseus - self-hosted AI workspace",
                age: "18 hours ago",
                commentsCount: 82,
                by: "Dzheky",
                score: 175
            ),
            makePost(
                id: 48_345_090,
                url: "https://www.lucasfcosta.com/blog/backpressure-is-all-you-need",
                title: "Backpressure is all you need",
                age: "21 hours ago",
                commentsCount: 103,
                by: "lucasfcosta",
                score: 190
            )
        ]
    }

    private static func makePost(
        id: Int,
        url: String,
        title: String,
        age: String,
        commentsCount: Int,
        by: String,
        score: Int
    ) -> Post {
        Post(
            id: id,
            url: URL(string: url)!,
            title: title,
            age: age,
            commentsCount: commentsCount,
            by: by,
            score: score,
            postType: .news,
            upvoted: false,
            voteLinks: VoteLinks(
                upvote: URL(string: "https://news.ycombinator.com/vote?id=\(id)&how=up&goto=news"),
                unvote: nil
            )
        )
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
        post.comments = commentsByPostID[id] ?? []
        if let commentCount = post.comments?.count, commentCount > 0 {
            post.commentsCount = max(post.commentsCount, commentCount)
        }
        return post
    }

    func getComments(for post: Post) async throws -> [Comment] {
        try await getPost(id: post.id).comments ?? []
    }

    func searchPosts(
        query: String,
        sort _: SearchSort,
        dateRange _: SearchDateRange,
        page: Int,
        hitsPerPage: Int
    ) async throws -> SearchResultsPage {
        let normalizedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !normalizedQuery.isEmpty else {
            return SearchResultsPage(posts: [], page: page, totalPages: 0, totalResults: 0, hasMore: false)
        }
        let matches = posts.filter { post in
            post.title.lowercased().contains(normalizedQuery)
                || post.by.lowercased().contains(normalizedQuery)
                || post.url.host?.lowercased().contains(normalizedQuery) == true
        }
        let pageSize = max(hitsPerPage, 1)
        let start = page * pageSize
        let pagePosts = start < matches.count ? Array(matches.dropFirst(start).prefix(pageSize)) : []
        let totalPages = Int(ceil(Double(matches.count) / Double(pageSize)))
        return SearchResultsPage(
            posts: pagePosts,
            page: page,
            totalPages: totalPages,
            totalResults: matches.count,
            hasMore: page + 1 < totalPages
        )
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

    private static func makeCommentsByPostID() -> [Int: [Comment]] {
        [
            largeCommentsPostID: makeLargeCommentThread(count: 720),
            48_345_248: [
                makeComment(
                    id: 48_348_695,
                    by: "neilv",
                    age: "13 hours ago",
                    text: "Aviation software culture is conservative for good reasons, but the boundary between caution and theatre can get blurry."
                ),
                makeComment(
                    id: 48_353_216,
                    by: "klustregrif",
                    age: "2 hours ago",
                    text: "This sounds like a Bluetooth device name that became more dramatic as the story moved through each retelling."
                )
            ],
            48_345_840: [
                makeComment(
                    id: 48_346_154,
                    by: "denysvitali",
                    age: "17 hours ago",
                    text: """
                    <p>kudos to Louis Rossmann for doing a ton of work on Right to repair, and the website called Consumer Rights Wiki to document anti-consumer practices.</p>
                    <p><a href="https://consumerrights.wiki/w/Main_Page">https://consumerrights.wiki/w/Main_Page</a></p>
                    <p>He is involved with FULU Foundation which has a bounty for running without Amazon's servers.</p>
                    <p><a href="https://bounties.fulu.org/bounties/ring-video-doorbells">https://bounties.fulu.org/bounties/ring-video-doorbells</a></p>
                    """
                ),
                makeComment(
                    id: 48_354_612,
                    by: "account42",
                    age: "just now",
                    text: "Fingerprinting looks practical only because every site is trying to police abuse alone instead of relying on shared enforcement.",
                    level: 1
                ),
                makeComment(
                    id: 48_346_670,
                    by: "b65e8bee43c2ed0",
                    age: "16 hours ago",
                    text: "The irony is that the protection is often good enough to frustrate ordinary visitors, but not determined scrapers.",
                    level: 1
                ),
                makeComment(
                    id: 48_346_686,
                    by: "ACCount37",
                    age: "16 hours ago",
                    text: "Exactly. If your IP range looks suspicious, the casual browsing experience can become a stream of challenges.",
                    level: 2
                ),
                makeComment(
                    id: 48_350_831,
                    by: "ranger_danger",
                    age: "10 hours ago",
                    text: "When a challenge fails on a normal browser setup, I usually leave instead of changing extensions just for one site.",
                    level: 2
                ),
                makeComment(
                    id: 48_351_831,
                    by: "aboardRat4",
                    age: "8 hours ago",
                    text: "That gets harder when the site is a bank, airline, utility, or government service rather than a blog.",
                    level: 3
                ),
                makeComment(
                    id: 48_354_157,
                    by: "AgentReinAi",
                    age: "10 minutes ago",
                    text: "The frustrating part is that privacy-preserving CAPTCHA alternatives can still drift toward the same tracking tradeoffs."
                ),
                makeComment(
                    id: 48_347_466,
                    by: "jeroenhd",
                    age: "15 hours ago",
                    text: "Strict privacy settings can break ordinary browsing, so browsers are stuck balancing fingerprint resistance against compatibility."
                ),
                makeComment(
                    id: 48_352_616,
                    by: "drnick1",
                    age: "5 hours ago",
                    text: "Spoofing time zones and device capabilities reduces uniqueness, but it can also create mismatches that make users stand out differently.",
                    level: 1
                ),
                makeComment(
                    id: 48_347_534,
                    by: "croes",
                    age: "15 hours ago",
                    text: "I expect some breakage from strict privacy settings. I do not expect a major fingerprinting surface to stay wide open.",
                    level: 1
                ),
                makeComment(
                    id: 48_353_781,
                    by: "jeroenhd",
                    age: "2 hours ago",
                    text: "Even aggressive fingerprint resistance is not full immunity, and every extra layer tends to create another class of site bugs.",
                    level: 2
                ),
                makeComment(
                    id: 48_348_985,
                    by: "userbinator",
                    age: "13 hours ago",
                    text: "A web where only approved browser profiles work starts to feel less open, even if the stated goal is stopping automated abuse."
                ),
                makeComment(
                    id: 48_349_298,
                    by: "0x59",
                    age: "13 hours ago",
                    text: "For public content, rate limits and cheaper pages seem more aligned with the web than requiring every visitor to prove their browser.",
                    level: 1
                ),
                makeComment(
                    id: 48_349_879,
                    by: "pmdr",
                    age: "12 hours ago",
                    text: "Heavy client-side pages make the situation worse: the more expensive each request is, the stronger the incentive to gate everything.",
                    level: 2
                ),
                makeComment(
                    id: 48_349_947,
                    by: "remus",
                    age: "12 hours ago",
                    text: "Some crawlers are polite, but the bad ones can still create real bandwidth and compute cost for small sites.",
                    level: 3
                ),
                makeComment(
                    id: 48_353_873,
                    by: "MartijnHols",
                    age: "2 hours ago",
                    text: "Rate limits get much less reliable once abuse traffic rotates through residential networks on every request.",
                    level: 2
                ),
                makeComment(
                    id: 48_351_392,
                    by: "matheusmoreira",
                    age: "9 hours ago",
                    text: "The worrying future is remote attestation becoming the normal ticket for accessing ordinary websites.",
                    level: 1
                ),
                makeComment(
                    id: 48_353_409,
                    by: "raxxorraxor",
                    age: "3 hours ago",
                    text: "If privacy-focused browsers fail these checks, the pressure should land on the sites choosing the gatekeeper.",
                    level: 1
                ),
                makeComment(
                    id: 48_353_851,
                    by: "dchest",
                    age: "2 hours ago",
                    text: "In practice support desks often reduce this to clearing cookies or trying the same flow in Chrome.",
                    level: 2
                ),
                makeComment(
                    id: 48_354_384,
                    by: "UqWBcuFx6NV4r",
                    age: "2 hours ago",
                    text: "Most people will not notice the policy debate. They will just use whatever browser gets them through checkout.",
                    level: 2
                ),
                makeComment(
                    id: 48_347_606,
                    by: "mootothemax",
                    age: "15 hours ago",
                    text: "From the operator side, these systems can still filter out a large amount of low-effort abuse even if experts get through.",
                    level: 2
                ),
                makeComment(
                    id: 48_354_288,
                    by: "Chris2048",
                    age: "1 hour ago",
                    text: "The proof-of-work angle is interesting because it shifts cost to the client, but it does not answer the privacy question.",
                    level: 3
                ),
                makeComment(
                    id: 48_349_395,
                    by: "TkTech",
                    age: "12 hours ago",
                    text: "Old-school rate limiting with redirects and log analysis was crude, but at least users could understand what the server was doing.",
                    level: 3
                ),
                makeComment(
                    id: 48_350_393,
                    by: "mcosta",
                    age: "11 hours ago",
                    text: "Observability matters here. Without clear logs it is hard to know whether a mitigation stopped abuse or just blocked people.",
                    level: 4
                ),
                makeComment(
                    id: 48_349_682,
                    by: "dotancohen",
                    age: "12 hours ago",
                    text: "I would rather see transparent per-IP or per-account limits than an opaque browser fingerprint challenge.",
                    level: 3
                ),
                makeComment(
                    id: 48_353_362,
                    by: "dotancohen",
                    age: "3 hours ago",
                    text: "The tooling is better now, but the same tradeoff remains: block too loosely and costs spike, block too tightly and users leave.",
                    level: 4
                )
            ],
            48_347_354: [
                makeComment(
                    id: 48_350_036,
                    by: "qqtt",
                    age: "11 hours ago",
                    text: "Subscriptions could be healthier than pure ad targeting if they actually reduce the incentives behind engagement farming."
                ),
                makeComment(
                    id: 48_353_996,
                    by: "dabedee",
                    age: "28 minutes ago",
                    text: "WhatsApp is so embedded in parts of Europe that asking people to switch messengers creates its own social friction."
                )
            ],
            UITestingBootstrap.postID: [
                makeComment(
                    id: 48_354_262,
                    by: "manakov_dev",
                    age: "1 minute ago",
                    text: "Tiny machines make sense when travel weight matters more than benchmark numbers, especially for light terminal and browser work."
                ),
                makeComment(
                    id: 48_353_305,
                    by: "lexicality",
                    age: "2 hours ago",
                    text: "Cheap small laptops can be rough around the edges and still hit a strange sweet spot for vacation or couch computing."
                ),
                makeComment(
                    id: 48_353_877,
                    by: "tinythinkpad",
                    age: "2 hours ago",
                    text: "The appeal is not raw speed. It is being able to throw a real keyboard and a full browser into the smallest corner of a bag.",
                    level: 1
                ),
                makeComment(
                    id: 48_353_928,
                    by: "luggable",
                    age: "2 hours ago",
                    text: "For SSH, notes, and light code review these devices are closer to tools than toys. The moment you expect workstation behavior they get frustrating.",
                    level: 1
                ),
                makeComment(
                    id: 48_354_047,
                    by: "michaelcampbell",
                    age: "1 hour ago",
                    text: "I wish more reviews spent time on thermals at lap distance. A compact chassis can turn a fine chip into a noisy compromise."
                ),
                makeComment(
                    id: 48_354_083,
                    by: "janalsncm",
                    age: "1 hour ago",
                    text: "The hinge and keyboard matter more than the CPU here. If either one feels fragile the whole category stops making sense.",
                    level: 1
                ),
                makeComment(
                    id: 48_354_119,
                    by: "summerlight",
                    age: "1 hour ago",
                    text: "I keep an older MiniBook around as a travel terminal. It is not pleasant for eight hours, but it is fantastic for twenty minutes in an airport."
                ),
                makeComment(
                    id: 48_354_166,
                    by: "pavel_lishin",
                    age: "58 minutes ago",
                    text: "These machines also make good emergency computers. Leave one charged in a drawer and it is ready for routers, serial consoles, and odd jobs.",
                    level: 1
                ),
                makeComment(
                    id: 48_354_204,
                    by: "cipherpunks",
                    age: "49 minutes ago",
                    text: "The weird part is that phones have the performance, but the clamshell form factor still wins when you need to type accurately."
                ),
                makeComment(
                    id: 48_354_233,
                    by: "rsyncer",
                    age: "45 minutes ago",
                    text: "A pocketable laptop with Linux support is a surprisingly good fit for homelab maintenance. The screen only has to be good enough.",
                    level: 1
                ),
                makeComment(
                    id: 48_354_281,
                    by: "kspace",
                    age: "38 minutes ago",
                    text: "Battery life is the deciding detail for me. If the small machine needs its own charger every day, the portability story gets weaker."
                ),
                makeComment(
                    id: 48_354_312,
                    by: "subpixel",
                    age: "34 minutes ago",
                    text: "The high-DPI display is more important than it sounds. Small screens are only tolerable when text rendering is crisp.",
                    level: 1
                ),
                makeComment(
                    id: 48_354_337,
                    by: "nfriedly",
                    age: "30 minutes ago",
                    text: "I like that this category still exists. Not every portable computer needs to converge into a tablet plus keyboard cover."
                ),
                makeComment(
                    id: 48_354_371,
                    by: "softfalcon",
                    age: "27 minutes ago",
                    text: "The market seems tiny, but the people who want one really want one. That is exactly the sort of hardware niche worth preserving.",
                    level: 1
                ),
                makeComment(
                    id: 48_354_415,
                    by: "kerneltoast",
                    age: "21 minutes ago",
                    text: "Driver support would make or break it for me. Suspend, Wi-Fi, brightness keys, and audio have to work without a weekend project."
                ),
                makeComment(
                    id: 48_354_441,
                    by: "annoyingnoises",
                    age: "18 minutes ago",
                    text: "Fans on tiny laptops have a way of sounding much worse than their actual decibel number. Pitch matters.",
                    level: 1
                ),
                makeComment(
                    id: 48_354_486,
                    by: "travelrouter",
                    age: "12 minutes ago",
                    text: "For me the comparison is not with a MacBook Air. It is with carrying no laptop at all and regretting it once per trip."
                ),
                makeComment(
                    id: 48_354_520,
                    by: "noisefloor",
                    age: "8 minutes ago",
                    text: "I would love to see this with a matte screen and repairable storage. Small does not have to mean disposable.",
                    level: 1
                ),
                makeComment(
                    id: 48_354_553,
                    by: "xterm256",
                    age: "4 minutes ago",
                    text: "The keyboard layout is always the catch. If slash, escape, and arrows are in strange places, terminal work becomes comedy."
                )
            ],
            48_349_527: [
                makeComment(
                    id: 48_350_562,
                    by: "cheschire",
                    age: "10 hours ago",
                    text: "Cost comparisons are hard to judge without also looking at access, wait times, and the rationing every system does somewhere."
                ),
                makeComment(
                    id: 48_350_623,
                    by: "rawgabbit",
                    age: "10 hours ago",
                    text: "Training capacity and residency slots seem like practical levers if the goal is more doctors rather than just more spending."
                )
            ]
        ]
    }

    private static func makeComment(id: Int, by: String, age: String, text: String, level: Int = 0) -> Comment {
        Comment(
            id: id,
            age: age,
            text: text,
            by: by,
            level: level,
            upvoted: false,
            voteLinks: VoteLinks(
                upvote: URL(string: "https://news.ycombinator.com/vote?id=\(id)&how=up&goto=item%3Fid%3D\(UITestingBootstrap.postID)"),
                unvote: nil
            )
        )
    }

    private static func makeLargeCommentThread(count: Int) -> [Comment] {
        (0 ..< count).map { index in
            let level: Int
            switch index % 10 {
            case 0, 1, 2, 3:
                level = 0
            case 4, 5, 6:
                level = 1
            case 7, 8:
                level = 2
            default:
                level = 3
            }

            return makeComment(
                id: 49_000_000 + index,
                by: "large_thread_\(index % 37)",
                age: "\(max(1, index % 23)) hours ago",
                text: largeCommentText(index: index),
                level: level
            )
        }
    }

    private static func largeCommentText(index: Int) -> String {
        """
        This deterministic comment row \(index) is part of a large UI-test discussion. It includes enough text to exercise wrapping, attributed text rendering, row measurement, lazy layout, and scrolling without relying on live Hacker News data. The point is to make performance problems visible when the comments panel is expanded inside the custom browser sheet.
        """
    }
}

final class UITestSettingsUseCase: SettingsUseCase, @unchecked Sendable {
    var safariReaderMode = false
    var linkBrowserMode: LinkBrowserMode
    var showThumbnails = UITestingBootstrap.isScreenshotMode
    var rememberFeedCategory = false
    var lastFeedCategory: PostType?
    var textSize: TextSize = .medium
    var compactFeedDesign = false
    var dimReadPosts: Bool

    init() {
        let mode = ProcessInfo.processInfo.environment["HACKERS_UI_LINK_BROWSER_MODE"]
        linkBrowserMode = mode == "inApp" ? .inAppBrowser : .customBrowser
        let dimReadSetting = ProcessInfo.processInfo.environment["HACKERS_UI_DIM_READ_POSTS"]
        dimReadPosts = dimReadSetting == "1" || (!UITestingBootstrap.isScreenshotMode && dimReadSetting != "0")
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
        let ids = ProcessInfo.processInfo.environment["HACKERS_UI_READ_POST_IDS"]?
            .split(separator: ",")
            .compactMap { Int($0.trimmingCharacters(in: .whitespacesAndNewlines)) } ?? []
        readIDs = Set(ids)
    }

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
        guard UITestingBootstrap.isEnabled else { return nil }
        guard ProcessInfo.processInfo.environment["HACKERS_UI_ARTICLE_FIXTURES"] != "0" else {
            return nil
        }

        if url.host?.contains("hacktivis.me") == true {
            return UITestArticleContent(
                title: "Cloudflare Turnstile requiring fingerprintable WebGL",
                body: "Fixture article loaded from the UI-test Hacker News Active snapshot."
            )
        }

        if url.host?.contains("swift.org") == true {
            return UITestArticleContent(
                title: "Swift 6.2 Released",
                body: "Fixture article loaded from the UI-test Hacker News Active snapshot."
            )
        }

        if url.host?.contains("simpleflying.com") == true {
            return UITestArticleContent(
                title: "United Airlines 767 returns to Newark",
                body: "Fixture article for a current Active thread with a lively comment discussion."
            )
        }

        return nil
    }
}
#endif
