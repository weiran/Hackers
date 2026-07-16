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

That script selects/prints Xcode, runs first launch setup, selects an iOS runtime matching the chosen Xcode simulator SDK, and creates/boots the expected simulator when needed. It uses `.github/xcode-version` unless `CI_XCODE_VERSION` overrides it for a workflow such as Nightly. CI build and test commands use that simulator's UDID so another installed runtime with the same device name cannot be selected accidentally.

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

Nightly validation runs every functional UI test, explicitly excluding screenshot generation:

```bash
./run_ui_tests.sh full
```

UI tests write result bundles under `artifacts/xcresults` by default, then verify that the bundle contains exactly the requested test manifest. Both modes use explicit `-only-testing` selectors, so screenshot generation and newly added test classes cannot enter a functional run accidentally. Keep the full manifest in `run_ui_tests.sh` in the same order as the test methods in `HackersUITests.swift`; the runner fails before building if they drift. It uses `DESTINATION` when set, otherwise a CI simulator selected by `CI_DEVICE_UDID` or `CI_DESTINATION`, and finally the local `iPhone 17 Pro` default. Use functional UI tests when validating app launch, top-level navigation, browser presentation, or behavior that cannot be covered reliably through package tests.

UI tests should use the deterministic fixture layer in `App/UITesting/UITestingBootstrap.swift`, not live Hacker News or Algolia. `HACKERS_UI_TESTING=1` is the sole opt-in and installs dependency overrides for posts, comments, search, settings, authentication, bookmarks, read state, voting, and article content. Invalid values and incompatible route options fail at launch rather than silently falling back.

The typed launch contract is:

* `HACKERS_UI_FIXTURE_PROFILE`: `functional`, `marketing`, or `stress`; defaults to `functional`.
* `HACKERS_UI_BROWSER_MODE`: `custom` or `inApp`; system-browser automation is unsupported.
* `HACKERS_UI_ROUTE`: `feed`, `comments`, or `story`.
* `HACKERS_UI_POST_ID`: required for `comments` and `story`; rejected for `feed`.
* `HACKERS_UI_STORY_PRESENTATION`: `collapsedBrowser` or `expandedComments`; accepted only for `story` and defaults to `collapsedBrowser`.
* `HACKERS_UI_ARTICLE_SOURCE`: `fixture` or `live`; defaults to `fixture`.
* `HACKERS_UI_DIM_READ_POSTS`: set to `1` or `0` for read-state visual coverage.
* `HACKERS_UI_READ_POST_IDS`: comma-separated post IDs to pre-mark as read.
* `HACKERS_UI_SHOW_THUMBNAILS`: set to `1` or `0`.

Only keys defined by the shared launch contract are accepted once UI testing is enabled. Functional tests use the `functional` profile, screenshot staging uses `marketing`, and oversized/scroll coverage opts into `stress`. Direct routes must refer to a post in the selected profile. A story route cannot use the in-app browser, and fixture article mode fails closed if the selected post has no local article.

When adding UI tests, prefer existing accessibility identifiers such as `feed.list`, `feed.post.<id>`, `comments.list`, `settings.form`, `settings.showThumbnails`, `settings.compactFeed`, `search.results`, `search.sort.menu`, `search.date.menu`, `browser.view`, and `login.*`. Add new identifiers with the same stable, domain-specific naming style. An element's presence in the accessibility hierarchy is not proof that it is visible: require hittability for interactive controls, resolve and retain the exact stable candidate when identifiers are duplicated, and verify stable containment or meaningful intersection with the relevant viewport for rendered content. Geometry alone does not detect arbitrary occlusion. For overlapping presentations, move the UI into a state where the content is unobscured and assert the state-specific chrome as well as the content. For a pixel-level visual claim, reproduce and inspect a screenshot of the same state.

App Store screenshots are generated through fastlane:

```bash
fastlane ios screenshots
```

The screenshot class is a manual generation workflow and is excluded from both `smoke` and `full`. Its assertions only stage each intended screen before capture; it is not a functional or visual-regression suite. The lane uses the deterministic `marketing` profile, including locally rendered article HTML in the same browser web view used by its controls, then generates iPhone and iPad captures in light and dark appearances. It accepts only the exact raw and framed files under each appearance's `en-US` directory, validates PNG dimensions and portrait orientation, rejects duplicate names and duplicate captures within an appearance, confirms light and dark output differ, and writes a browsable summary under `artifacts/screenshots`. Keep fixture content stable and use descriptive snapshot names with numeric ordering.

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
  * Scheduled nightly validation to catch Xcode/simulator/runtime drift, including full UI tests.
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
