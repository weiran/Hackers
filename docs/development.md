# Development

This guide covers local setup, build/test commands, coding standards, CI expectations, and common troubleshooting.

## Requirements

* macOS with current Xcode support for the repo's configured Xcode version.
* Xcode version from `.github/xcode-version` (`26.4` at the time of writing).
* iOS Simulator runtime for iOS 26.
* Swift 6.2 toolchain.
* Homebrew for optional tools such as SwiftLint and actionlint.

The CI simulator device is `iPhone 17 Pro`.

## Setup

From the repository root:

```bash
xcodebuild -version
xcodebuild -project Hackers.xcodeproj -scheme Hackers -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

If the simulator is missing or stale, compare your environment with the CI setup script:

```bash
scripts/ci/setup-xcode-simulator.sh
```

That script selects/prints Xcode, runs first launch setup, verifies the iOS simulator platform, and creates/boots the expected simulator when needed.

## Build

Run all `xcodebuild` commands from the repository root.

```bash
xcodebuild -project Hackers.xcodeproj -scheme Hackers -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

Clean build:

```bash
xcodebuild clean build -project Hackers.xcodeproj -scheme Hackers -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

Quick build status check:

```bash
xcodebuild build -project Hackers.xcodeproj -scheme Hackers -destination 'platform=iOS Simulator,name=iPhone 17 Pro' 2>&1 | grep "BUILD"
```

## Test

Use the project test runner:

```bash
./run_tests.sh
```

Verbose:

```bash
./run_tests.sh -v
```

Specific modules:

```bash
./run_tests.sh Domain
./run_tests.sh Feed Comments Settings
```

Do not use `swift test` as the project validation command. Packages target iOS and use iOS-only APIs, so tests must run through Xcode with an iOS Simulator destination.

## UI Tests And Screenshots

PR validation includes a small UI smoke suite:

```bash
./run_ui_tests.sh smoke
```

Nightly validation runs the full UI test suite:

```bash
./run_ui_tests.sh full
```

UI tests write result bundles under `artifacts/xcresults` by default. Use UI tests when validating app launch, top-level navigation, browser presentation, screenshot fixtures, or behavior that cannot be covered reliably through package tests.

UI tests should use the deterministic fixture layer in `App/UITesting/UITestingBootstrap.swift`, not live Hacker News or Algolia. Launch with `--ui-testing` or `HACKERS_UI_TESTING=1` so the app installs dependency overrides for posts, comments, search, settings, authentication, bookmarks, read state, voting, and article content.

Common UI-test launch controls:

* `HACKERS_UI_LINK_BROWSER_MODE`: `custom`, `inApp`, or `system`.
* `HACKERS_UI_ARTICLE_FIXTURES`: set to `0` to allow real article loading in screenshot flows.
* `HACKERS_UI_DIM_READ_POSTS`: set to `1` or `0` for read-state visual coverage.
* `HACKERS_UI_READ_POST_IDS`: comma-separated post IDs to pre-mark as read.
* `HACKERS_UI_INITIAL_POST_ID`: open comments for a fixture post at launch.
* `HACKERS_UI_INITIAL_LINK_POST_ID`: open a fixture story link at launch.
* `HACKERS_UI_BROWSER_ONLY`: launch directly into browser-focused fixture state.

When adding UI tests, prefer existing accessibility identifiers such as `feed.list`, `feed.post.<id>`, `comments.list`, `settings.form`, `settings.showThumbnails`, `settings.compactFeed`, `search.sort.menu`, `search.date.menu`, `browser.view`, and `login.*`. Add new identifiers with the same stable, domain-specific naming style.

App Store screenshots are generated through fastlane:

```bash
bundle exec fastlane ios screenshots
```

The screenshot lane uses deterministic UI-test fixtures, generates light and dark screenshots, frames them, and writes a browsable summary under `artifacts/screenshots`. Screenshot tests should keep fixture content stable, use descriptive snapshot names with numeric ordering, and avoid depending on live network content unless the test explicitly disables article fixtures for that shot.

## Test Layout

Tests live beside their package:

* `Domain/Tests/`
* `Data/Tests/`
* `Networking/Tests/`
* `Shared/Tests/`
* `DesignSystem/Tests/`
* `Features/*/Tests/`

Use Swift Testing (`import Testing`, `@Suite`, `@Test`) for new tests unless an existing target clearly uses a different local pattern.

Focus tests on:

* Domain models and parser behavior
* Repository parsing and persistence behavior
* ViewModel state transitions
* Shared services
* Regression cases for Hacker News markup changes

Avoid view snapshot or full UI tests unless the behavior cannot be covered at a lower level.

## Coding Standards

Keep changes consistent with the existing Swift 6.2 codebase:

* Prefer small, focused types over broad utility objects.
* Use `async`/`await` for new asynchronous code.
* Keep UI-facing types and mutations on the main actor.
* Prefer initializer injection for ViewModels and services.
* Keep `DependencyContainer.shared` use near app/feature composition.
* Keep Domain models and protocols free of unnecessary UI dependencies.
* Use existing DesignSystem components before adding new visual primitives.
* Do not introduce new package dependencies unless the benefit is clear and the scope is narrow.
* Keep comments sparse and useful; explain non-obvious decisions, not mechanics.

## SwiftLint

CI runs SwiftLint. Locally:

```bash
swiftlint lint --config .swiftlint.yml
```

Install when needed:

```bash
brew install swiftlint
```

Some existing warnings are non-blocking; do not expand unrelated lint cleanup into feature work unless asked.

## CI

Primary workflows:

* `.github/workflows/pr.yml`
  * Runs on PRs and pushes to `master`.
  * Required jobs: `lint`, `build`, `test`, and `ui smoke`.
* `.github/workflows/nightly.yml`
  * Scheduled clean validation to catch Xcode/simulator/runtime drift, including full UI tests.
* `.github/workflows/release-testflight.yml`
  * Protected TestFlight release workflow.
* `.github/workflows/release-appstore.yml`
  * Protected App Store submission workflow. Human review and environment approval remain required.

Actions are pinned by commit SHA and the repository requires SHA pinning for Actions.

## Dependabot

Dependabot is configured for:

* GitHub Actions
* Bundler/fastlane
* Swift packages in each package directory

Review dependency updates through PR checks. GitHub Actions updates must preserve SHA pinning. Bundler and fastlane updates deserve release-flow scrutiny because fastlane, Xcode, signing, and App Store Connect behavior are tightly coupled. Swift package updates should run the affected package tests, and parser/networking dependency updates should run the full test runner because Hacker News markup and HTTP behavior are high-risk integration points.

## Troubleshooting

If builds fail due to missing simulators:

```bash
scripts/ci/setup-xcode-simulator.sh
xcrun simctl list devices available
xcrun simctl list runtimes
```

If package tests fail only through `swift test`, rerun with `./run_tests.sh`; `swift test` is not the supported validation path.

If CI fails but local builds pass, inspect uploaded diagnostics:

* xcodebuild logs
* `.xcresult` bundles
* simulator diagnostics

If release signing or upload fails, use [Release Process](./release-process.md) and inspect `testflight-artifacts` before changing secrets or signing assets.
