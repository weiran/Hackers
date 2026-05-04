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

## Hacker News Integration

The app primarily works against Hacker News HTML endpoints and parses them into domain models. This makes parser tests important: small HN markup changes can break behavior without compiler errors.

Common integration areas:

* Feed/category loading
* Comment tree parsing
* Voting links and optimistic voting state
* Authentication/session handling
* Bookmarks and search
* External link and in-app browser handling

## What Not To Reintroduce

The previous docs included historical migration plans, generated API listings, and broad status reports. Those are intentionally removed. Keep future documentation focused on current behavior and durable operational knowledge.
