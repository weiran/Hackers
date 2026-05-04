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
  * Required jobs: `lint`, `build`, `test`.
* `.github/workflows/nightly.yml`
  * Scheduled clean validation to catch Xcode/simulator/runtime drift.
* `.github/workflows/release-testflight.yml`
  * Protected TestFlight release workflow.
* `.github/workflows/release-appstore.yml`
  * Protected placeholder only; App Store submission remains manual.

Actions are pinned by commit SHA and the repository requires SHA pinning for Actions.

## Dependabot

Dependabot is configured for:

* GitHub Actions
* Bundler/fastlane
* Swift packages

Review dependency updates normally through PR checks. Be careful with release tooling updates because fastlane, Bundler, Xcode, and App Store Connect behavior are tightly coupled.

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
