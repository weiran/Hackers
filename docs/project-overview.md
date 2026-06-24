# Project Overview

Hackers is an iOS Hacker News client built with SwiftUI, Swift Package Manager modules, Swift 6.2, and an iOS 26+ deployment target.

The app is organized around feature modules, protocol-based use cases, repository implementations, and a small shared dependency container. UI state lives in SwiftUI views and feature ViewModels; networking, parsing, persistence, voting, settings, authentication, and release-note state are kept behind protocols where practical.

## Repository Map

| Path | Responsibility |
| --- | --- |
| `App/` | App entry point, root navigation, app delegates, in-app browser, release "What's New" coordination. |
| `Domain/` | Core models, use case protocols, parser helpers, and domain-level contracts. |
| `Data/` | Repository implementations, Hacker News parsing, persistence, authentication, bookmarks, search, support purchase state. |
| `Networking/` | `NetworkManagerProtocol` and HTTP implementation. |
| `Shared/` | Dependency container, shared services, navigation protocol, voting ViewModel, loading state, session/toast/share/link helpers. |
| `DesignSystem/` | Shared SwiftUI components, colors, text scaling, post display, thumbnail, vote UI, mail view. |
| `Features/Authentication/` | Login UI and authentication ViewModel. |
| `Features/Feed/` | Feed lists, post loading, pagination, voting, bookmarks, search entry points. |
| `Features/Comments/` | Comment tree UI, comment loading, collapse/expand, voting. |
| `Features/Settings/` | Settings UI, app preferences, support UI, authentication entry points, what's-new entry points. |
| `Features/WhatsNew/` | Release notes presentation and "seen version" state. |
| `Extensions/` | Share/action extension code for opening Hacker News item URLs in the main app. |
| `App/UITesting/` | Deterministic dependency overrides and fixtures used by UI tests and screenshot generation. |
| `HackersUITests/` | UI smoke tests and App Store screenshot flows. |

## Module Shape

Each package has its own `Package.swift` and test target. Packages use Swift tools 6.2 and `platforms: [.iOS(.v26)]`.

Current package set:

* `Domain`
* `Data`
* `Networking`
* `Shared`
* `DesignSystem`
* `Authentication`
* `Feed`
* `Comments`
* `Settings`
* `WhatsNew`

`Data` uses SwiftSoup for Hacker News HTML parsing. Keep external dependencies rare and justified.

## App Flow

1. `App/HackersApp.swift` starts the SwiftUI app.
2. `App/ContentView.swift` composes the main interface and environment.
3. `Shared.DependencyContainer` wires use cases, repositories, services, and feature dependencies.
4. Feature views own or receive ViewModels.
5. ViewModels call domain use case protocols.
6. Data repositories perform networking, parsing, persistence, and voting/authentication work.
7. Domain models flow back to feature UI and DesignSystem components.

## Key Patterns

* Use SwiftUI for UI and `@Observable` for current ViewModel state.
* Keep UI mutations on the main actor.
* Inject dependencies through initializers or factories where possible.
* Use `DependencyContainer.shared` at composition boundaries, not deep inside business logic.
* Keep Domain contracts small and testable.
* Use `async`/`await` for asynchronous work.
* Prefer `Sendable` value models and explicit actor/main-actor isolation over unchecked sharing.
* Test ViewModels, repositories, parsers, and services; avoid brittle view rendering tests.

## Feature Workflows

Feed is the main browsing surface. `FeedViewModel` loads `PostType` feeds, deduplicates posts by ID, annotates fetched posts with bookmark/read state, and handles pagination. Top, Ask, Show, Best, and Active use page-based loading; Newest and Jobs use Hacker News `next` cursor loading. The Bookmarks feed is local/iCloud state from `BookmarksController`, not a Hacker News endpoint.

Search is part of the Feed feature. Search queries use `SearchUseCase`, keep separate paginated result state, support popular/recent sorting, support date ranges, and annotate search results with bookmark/read state the same way feed results are annotated.

Comments are loaded through `CommentsViewModel`. If a post is already available from the feed, it is passed as the initial post; otherwise comments load by post ID. The repository resolves comment permalink pages back to their parent story, inserts story text as a synthetic top comment with a negative ID, builds comment-tree indexes, and keeps a `visibleComments` projection for collapse/expand behavior.

Voting is optimistic in the UI and link-driven in the data layer. Hacker News vote/unvote URLs are parsed from HTML into `VoteLinks`; upvoted state can come from explicit `unvote` links or hidden `nosee` upvote arrows. Post and comment voting should go through the shared voting use cases/providers so score, upvoted state, and authentication failure handling stay consistent.

Authentication is HN-cookie based. `AuthenticationRepository` posts credentials to `/login`, stores the username in `UserDefaults` under `hn_username`, and treats authentication as valid only when both an HN cookie and stored username exist. Logout clears cookies and the stored username.

Settings are immediate-write preferences backed by `SettingsUseCase`. They control browser mode, Safari reader mode, thumbnails, remembered feed category, text size, compact feed layout, dimming read posts, and cache clearing/usage display. Feed and comments observe defaults changes so visual settings update without recreating the app.

WhatsNew is version-gated by `WhatsNewUseCase`. First launch stores the current version without showing the sheet, minor/major version increases can show it, and `disableWhatsNew` suppresses it for automated runs unless force-show is requested.

Navigation differs by device class. iPhone uses a `NavigationStack`; iPad and iOS-on-Mac use `NavigationSplitView` with a sidebar feed and detail comments/browser area. `NavigationStore` owns selected posts, pending deep links, modal presentation, and embedded browser state.

## Action Extension

The action extension is "Open in Hackers." It accepts one shared web URL and only handles Hacker News item URLs from `news.ycombinator.com` with an `id` query item.

The extension flow is:

1. `OpenInViewController` reads the shared `public.url`.
2. If the URL is a Hacker News item URL, it opens `com.weiranzhang.Hackers://item?id=<id>`.
3. The main app handles that custom scheme in `NavigationStore` and navigates to the matching post/comments.
4. Unsupported URLs reveal the extension's error label instead of opening the app.

Keep the action extension's `MARKETING_VERSION` and `CURRENT_PROJECT_VERSION` aligned with the main app target during releases.

## Data And Persistence

Settings use `UserDefaults` through `UserDefaultsProtocol` for testability. Current keys include `safariReaderMode`, `linkBrowserMode`, `ShowThumbnails`, `RememberFeedCategory`, `LastFeedCategory`, `textSize`, `compactFeedDesign`, and `DimReadPosts`. `openInDefaultBrowser` is a legacy key migrated into `linkBrowserMode`.

Bookmarks use `NSUbiquitousKeyValueStore` under `Bookmarks.posts`. Stored bookmark entries include enough post metadata to render the Bookmarks feed offline from HN feed pages, plus optional vote links and the bookmark timestamp used for recency ordering.

Read state uses `NSUbiquitousKeyValueStore` under `ReadStatus.posts`. It stores recent read IDs with timestamps and trims to 5,000 entries. Feed and search rows are annotated from this state, and `dimReadPosts` controls whether read rows are visually dimmed.

Authentication stores only the HN username in `UserDefaults`; the authenticated session itself is held by shared HN cookies in `HTTPCookieStorage`. Networking deliberately preserves shared cookie behavior so login, voting, and page fetches see the same session.

WhatsNew stores the last shown version in a dedicated `com.weiran.hackers.whatsnew` defaults suite. Cache clearing removes `URLCache.shared` responses and best-effort temporary files; cache usage includes Library/Caches and the temporary directory.

## Design System

Shared UI belongs in `DesignSystem/Sources/DesignSystem`.

Use existing components before creating feature-local variants:

* `PostDisplayView`
* `ThumbnailView`
* `VoteButton`
* `VoteIndicator`
* `VotingContextMenuItems`
* `AppTextField`
* `AppStateViews`
* `AppColors`
* `TextScaling`

Feature-specific layout belongs in the feature package. Reusable visual primitives belong in `DesignSystem`.

Design-system conventions:

* Use `PostDisplayView` for post rows, post headers, metadata pills, thumbnail behavior, matched geometry IDs, bookmark controls, and read-state dimming.
* Use `PostPillView`/pill helpers for score, comments, and bookmark controls so active/inactive colors and numeric transitions stay consistent.
* Use `VoteButton` for standalone voting controls and preserve its accessibility labels, hints, disabled state, and loading behavior.
* Use `AppLoadingStateView`, `AppEmptyStateView`, and `ToastBanner` for shared loading, empty, and toast states.
* Use `AppColors` and asset-backed tint/upvoted colors instead of feature-local color constants.
* Use `.scaledFont(...)` and `.textScaling(for:)` for app text that should respect the in-app text-size setting. Plain `.font(...)` is fine only when the text should ignore that setting.
* Keep reusable view primitives free of feature-specific navigation, repository, or dependency-container access.

## Hacker News Integration

The app primarily works against Hacker News HTML endpoints and parses them into domain models. This makes parser tests important: small HN markup changes can break behavior without compiler errors.

Common integration areas:

* Feed/category loading
* Comment tree parsing
* Voting links and optimistic voting state
* Authentication/session handling
* Bookmarks and search
* External link and in-app browser handling

Endpoint patterns:

* Feed pages use `https://news.ycombinator.com/<postType>?p=<page>` for most categories.
* Newest and Jobs use `https://news.ycombinator.com/<postType>?next=<lastPostId>`.
* Active uses `https://news.ycombinator.com/active?p=<page>`.
* Story/comment pages use `https://news.ycombinator.com/item?id=<id>`.
* Login posts to `https://news.ycombinator.com/login`.
* Voting follows parsed `vote?id=...&how=up` and `vote?id=...&how=un` links.

`PostRepository` parses HN HTML with SwiftSoup. Keep parser changes covered by focused fixtures for title rows, subtext rows, Ask/Show/job variants, top text, comment indentation, parent/on-story links, hidden vote arrows, explicit unvote links, and pagination.

Search is the exception to HN HTML scraping. `SearchRepository` uses the Algolia HN API:

* popular search: `https://hn.algolia.com/api/v1/search`
* recent search: `https://hn.algolia.com/api/v1/search_by_date`

Search requests use `tags=story`, page/hits-per-page parameters, and optional `created_at_i` numeric filters for date ranges.

## UI Test Fixtures

UI tests do not hit live Hacker News by default. `App/UITesting/UITestingBootstrap.swift` installs dependency overrides when `--ui-testing` is present or `HACKERS_UI_TESTING=1` is set.

The fixture layer provides deterministic posts, comments, search results, settings, bookmarks, read-state, authentication, voting, article content, and WhatsNew behavior. UI tests depend on accessibility identifiers such as `feed.list`, `feed.post.<id>`, `comments.list`, `settings.form`, `settings.showThumbnails`, `search.sort.menu`, `search.date.menu`, `browser.view`, and `login.*`.

Screenshot mode adds `--screenshots` or `HACKERS_SCREENSHOTS=1`. Screenshot tests can seed browser mode, article fixtures, initially read post IDs, initial comments/story selection, and browser-only state through `HACKERS_UI_*` environment variables.

## What Not To Reintroduce

The previous docs included historical migration plans, generated API listings, and broad status reports. Those are intentionally removed. Keep future documentation focused on current behavior and durable operational knowledge.
