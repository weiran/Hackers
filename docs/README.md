# Hackers Documentation

This folder contains the canonical project documentation. It is intentionally small: keep docs current, operational, and close to how the app is actually built today.

## Documents

| Document | Purpose |
| --- | --- |
| [Project Overview](./project-overview.md) | Architecture, module map, main features, and important implementation patterns. |
| [Development](./development.md) | Local setup, build/test commands, coding standards, CI, and troubleshooting. |
| [Release Process](./release-process.md) | TestFlight release workflow, signing, build numbers, artifacts, and failure recovery. |

## Quick Start

From the repository root:

```bash
xcodebuild -project Hackers.xcodeproj -scheme Hackers -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
./run_tests.sh
```

Use Xcode with the `Hackers` scheme for day-to-day app work. Use `./run_tests.sh` for test runs because the app and packages target iOS-only APIs; do not use `swift test` for project validation.

## Documentation Rules

* Prefer updating these canonical docs over adding one-off notes.
* Delete stale historical docs instead of keeping them as competing sources of truth.
* Keep examples short and executable from the repository root.
* Put release-specific operational details in [Release Process](./release-process.md).
