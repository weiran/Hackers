# Hackers App

## Canonical Docs

Use the maintained docs before making repo-specific assumptions:

* Project shape and architecture: `docs/project-overview.md`
* Local development, tests, CI, and troubleshooting: `docs/development.md`
* TestFlight and App Store release process: `docs/release-process.md`

Keep this file focused on agent operating rules. Prefer updating the canonical docs over duplicating long architecture or release details here.

## Current Project Shape

* iOS 26+ target, Swift 6.2, SwiftUI, Swift Package modules.
* Packages: `Domain`, `Data`, `Networking`, `Shared`, `DesignSystem`, and feature modules under `Features`.
* Current feature modules: `Authentication`, `Feed`, `Comments`, `Settings`, and `WhatsNew`.
* UI state generally uses Swift Observation (`@Observable`, `@Environment`, `@State`) with Combine still present where existing code requires it.
* ViewModels and services should receive dependencies through protocols, initializers, or composition factories.
* Keep `DependencyContainer.shared` usage near app and feature composition boundaries.

## Build And Test

Always run `xcodebuild` commands from the project directory.

```bash
xcodebuild -project Hackers.xcodeproj -scheme Hackers -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

Use the project test runner:

```bash
./run_tests.sh
./run_tests.sh Domain
./run_tests.sh Feed Comments Settings
```

Do not use `swift test` for project validation. Packages target iOS APIs and must run through Xcode with an iOS Simulator destination.

For UI smoke coverage, use:

```bash
./run_ui_tests.sh smoke
```

## Release Process

Follow `docs/release-process.md` as the source of truth.

Key guardrails:

* TestFlight release tags must be `vX.Y.Z+N`, where `X.Y.Z` matches `MARKETING_VERSION` and `N` matches `CURRENT_PROJECT_VERSION`.
* Update both `Hackers` and `HackersActionExtension` when changing release version or build settings.
* Update app-facing "What's New" content when the release has user-visible changes.
* Create or update the GitHub Release notes used for TestFlight "What to Test."
* App Store release notes are separate public customer copy. Never copy GitHub Release notes, TestFlight "What to Test" text, generated changelogs, pull request links, or `Full Changelog` links into App Store release notes.
* The `testflight` GitHub Environment is protected and must be approved before upload or App Store submission.
* Preserve and inspect release artifacts on failure before changing secrets or signing assets.
* Only force-move a `vX.Y.Z+N` tag during failed release recovery before a usable TestFlight build has completed; after success, treat the tag as immutable.

## Critical Guidelines

* Do what has been asked; nothing more, nothing less.
* Never create files unless absolutely necessary.
* Always prefer editing existing files.
* Never proactively create documentation files.
* Never use `git add .`; add specific relevant changes only.
* After making a requested change, commit it promptly and surgically by staging only the relevant files or hunks; leave unrelated worktree changes untouched.
* Commit messages should be concise and descriptive.
* Never amend existing commits; always create a new commit for additional changes.
