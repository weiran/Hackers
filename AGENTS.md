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

Reuse stable DerivedData and build incrementally by default. Clean only when diagnosing build-cache problems; use fresh DerivedData only if cleaning fails or a clean release/CI build is required.

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

## Visual Regression Verification

For user-reported visual bugs, screenshots are the source of truth.

* Reproduce the same screen, state, device class, and presentation path before changing code when feasible.
* For a visual fix, verify with a post-fix screenshot of the same flow. UI tests and accessibility frame checks are supplemental; they do not prove a visual bug is fixed by themselves.
* Match verification scope to the claim: one matching viewport is enough for a narrow visual fix; check orientations, iPad, or multiple sizes only when requested or when the change touches adaptive layout.
* If the visual state cannot be reproduced, say so clearly and do not claim the issue is fixed.
* If new visual evidence contradicts the working hypothesis, stop changing code and reassess before stacking more commits.

## Release Process

Follow `docs/release-process.md` as the source of truth.

Key release invariants: use the documented TestFlight tag/version relationship,
update both app targets and user-facing release content, and keep App Store copy
separate from GitHub/TestFlight material. Preserve failure artifacts before
changing secrets or signing assets; treat a successful release tag as immutable.

## Critical Guidelines

* Keep changes task-scoped; prefer existing files and create only necessary
  task-owned files.
* Stage only relevant files or hunks, leave unrelated worktree changes intact,
  and use concise descriptive commits rather than amending existing ones.
