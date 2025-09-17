# Hackers App — Code Quality Improvement Plan

This document consolidates prioritized, actionable improvements identified across the codebase. It focuses on reducing risk, tightening architecture, improving testability, and aligning with the project’s standards.

## Top Priorities

1) Unify Hacker News constants
- Problem: `HackerNewsConstants` is duplicated in `Domain/Models.swift` and `Shared/Constants/HackerNewsConstants.swift`.
- Action:
  - Remove the Domain copy and use `Shared.HackerNewsConstants` everywhere.
  - Update references in: `NavigationStore`, DesignSystem components, parsers, and any string matching logic.

2) Remove duplicated HTML stripping utilities
- Problem: `String.strippingHTML()` exists in both Domain and Shared with different behavior.
- Action:
  - Choose a single canonical implementation (prefer Domain’s parser-based correctness).
  - Deprecate/remove the other to avoid collisions.
  - If both are needed, distinguish names clearly and document scope.

3) Eliminate DI leaks in ViewModels
- Problem: `VotingViewModel` calls `DependencyContainer.shared.getAuthenticationUseCase()` inside methods, bypassing injection.
- Action:
  - Inject `AuthenticationUseCase` or an `AuthenticationServiceProtocol` (or a closure) into `VotingViewModel`.
  - Keep all container resolution at app composition boundaries.

4) Keep Domain UI‑agnostic
- Problem: Domain references SwiftUI types (`Color`, SwiftUI fonts) and has `ObservableObject`/`@Published` in `Comment`.
- Action:
  - Make Domain’s `CommentHTMLParser` return a neutral structure (tokens/spans/blocks) without UI attributes.
  - Convert tokens to `AttributedString` (with color/font/link styling) in DesignSystem/Presentation.
  - Make `Domain.Comment` a pure model (no `ObservableObject/@Published`); publish state in feature ViewModels.

5) Remove static mutable state from `VotingViewModel`
- Problem: `lastError` uses a static backing store and leaks across instances.
- Action:
  - Make `lastError` an instance property only.
  - If tests need persistence, inject a test-aware store or use delegate callbacks.

## Architecture & Dependency Injection

- Prefer constructor injection everywhere; use `DependencyContainer.shared` only in app composition (`App/*` or feature factory).
- Consolidate preferences access:
  - Replace direct `UserDefaults` reads in `Shared/Services/LinkOpener` with injected `SettingsUseCase` flags or a small configuration DTO passed from callers.
- Centralize preference keys:
  - Define keys in a single type (e.g., `SettingsRepository.Keys`) and reference them across modules; avoid raw string literals.

## Concurrency & Thread-Safety

- Replace `@unchecked Sendable` with safer patterns:
  - UI-bound classes should be `@MainActor` and not `Sendable`.
  - Candidates: `Shared/LoadingStateManager`, `Features/Feed/FeedViewModel`, `Features/Comments/CommentsViewModel`.
  - For `Data/SettingsRepository`, either remove `Sendable` or ensure thread-safe access if truly shared across executors.
- Domain model cleanup:
  - Avoid `ObservableObject` and `@Published` in Domain models (e.g. `Comment`). Keep them as value types or simple classes; state observation belongs to Features.
- NetworkManager hardening:
  - Validate HTTP status codes (throw on non-2xx).
  - Configure `timeoutIntervalForRequest/Resource` on `URLSessionConfiguration`.
  - Consider isolating session access if used from multiple executors (optional if usage is MainActor-only).

## Data Layer

- Base URL & constants:
  - Replace literal base URLs with `Shared.HackerNewsConstants` throughout `PostRepository` and helpers.
- Parsing robustness:
  - Extract magic numbers (e.g., `indentWidth / 40`) into named constants.
  - Add recursion safety to `fetchPostHtml(id:page:recursive:)` (max pages or guard against infinite loops).
  - Refine error mapping: replace generic `scraperError` with more specific cases where possible (invalid URL, missing node).
- AuthenticationRepository hygiene:
  - Replace `print` with a logging abstraction (wrapping `OSLog`).
  - Centralize username key (avoid repeating `"hn_username"`).
  - Future: support CSRF token extraction if HN requires it.

## Features

- FeedViewModel
  - Mark `@MainActor`; ensure all mutations to `feedLoader.data` and paging state happen on main.
  - Reset pagination state defensively when switching `postType`.
- CommentsViewModel
  - Mark `@MainActor`; keep visibility and voting mutations on main.
  - Align comment/post voting flows with a single abstraction (reuse `VotingViewModel` or standardize optimistic-update + unauthenticated handling with the same logic as Feed).
- Navigation & link handling
  - Replace `itemPrefix` string checks with `URLComponents` (host == `news.ycombinator.com` and path == `/item`).

## DesignSystem

- Move link styling from Domain to DesignSystem
  - Remove `Color("appTintColor")` assignments from Domain parsers; set color/underline when materializing tokens in UI.
- Consolidate vote display logic
  - Prefer `VoteIndicator`/`VotingContextMenuItems` in all call sites. Remove legacy inline UI branches once migrated.

## Shared Layer

- LoadingStateManager
  - Treat it as UI-state: mark `@MainActor` and remove `@unchecked Sendable`.
  - Optionally, require a load function before use to avoid nil checks.
- Extensions cleanup
  - Keep a single `String.strippingHTML()` or rename variants clearly; document intent (parser-accurate vs quick display cleanup).

## Testing

- Parser tests
  - Add tests for nested formatting, malformed anchors, mixed code blocks and paragraphs, entity decoding order, and whitespace preservation.
- Voting & auth tests
  - Test `VotingViewModel` unauthenticated path using injected dependencies (no static state). Verify logout notification and login prompt behaviors.
- LinkOpener tests
  - Abstract presentation (inject a presenter or protocol) to unit test decision logic without UIKit.
- Linting for tests
  - Consider enabling SwiftLint for tests (at least basic rules) to keep test code quality on par with production.

## Tooling & Style

- SwiftLint
  - Consider enabling additional rules that aid API clarity and safety (e.g., `explicit_acl`, `explicit_top_level_acl`, `attributes`, `redundant_type_annotation`).
- Logging
  - Replace `print` calls with a small logging utility. Control verbosity via build configs.
- Accessibility & strings
  - Centralize common accessibility labels and action titles (e.g., “Open Link”, “Upvote”, “Settings”) for consistency and future localization.

## Future Enhancements

- Presentation layer for attributed text
  - Make Domain return structured tokens; transform to `AttributedString` in Presentation/DesignSystem for style control and testability.
- Environment-driven DI for SwiftUI
  - Introduce environment keys for commonly used protocols to reduce constructor noise while keeping protocols fully testable.
- Network requests abstraction
  - A tiny `Endpoint` enum/request builder centralizing HN endpoints keeps future expansion consistent, even if scraping HTML.

## Actionable Checklist (Suggested Order)

1) Constants and utilities
- [x] Remove `Domain.HackerNewsConstants`; use `Shared.HackerNewsConstants` everywhere.
- [ ] Unify `String.strippingHTML()` into a single implementation (or rename and document two variants).

2) Concurrency and safety
- [ ] Mark `FeedViewModel`, `CommentsViewModel`, `LoadingStateManager` as `@MainActor`; remove `@unchecked Sendable`.
- [ ] Make `Domain.Comment` UI-agnostic (remove `ObservableObject/@Published`), or move it into a presentation-specific wrapper.

3) DI and boundaries
- [ ] Inject auth dependency into `VotingViewModel` and remove direct `DependencyContainer` access inside methods.
- [ ] Replace direct `UserDefaults` usage in `LinkOpener` with injected configuration flags.

4) Data layer hardening
- [ ] Replace magic numbers, centralize constants, and add recursion guard in `fetchPostHtml`.
- [ ] Improve error specificity in parsing.

5) Networking
- [ ] Add HTTP status validation and request/resource timeouts in `NetworkManager`.

6) Tests
- [ ] Add parser edge case tests.
- [ ] Add unauthenticated vote flow tests with dependency injection.
- [ ] Add tests for `LinkOpener` decision logic via an abstracted presenter.

7) DesignSystem and presentation
- [ ] Move link styling from Domain parser to DesignSystem when converting tokens to UI.
- [ ] Complete migration to `VoteIndicator`/`VotingContextMenuItems` across views.

---

Notes
- Keep changes incremental and focused; prefer small, verifiable PRs.
- Favor constructor injection and protocol abstractions for testability.
- Maintain UI-free Domain layer; centralize styling and presentation in DesignSystem/Features.
