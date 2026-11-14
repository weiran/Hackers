# Contributing to Hackers

Thank you for your interest in Hackers. Contributions are welcome, including bug
reports, documentation improvements, tests, design feedback, and code.

## Before you start

1. Check the issue tracker and open pull requests for existing work.
2. For a substantial change, open an issue first so the scope and approach can be
   discussed.
3. Do not include credentials, private data, signing assets, or generated build
   artifacts in a commit.

Please keep contributions focused. Small pull requests are easier to review, test,
and safely release.

## Development setup

See the [development guide](docs/development.md) for supported tools, project layout,
build commands, tests, UI fixtures, linting, and CI details. The short version is:

```bash
xcodebuild -project Hackers.xcodeproj -scheme Hackers \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
./run_tests.sh
```

Use Xcode and an iOS Simulator. `swift test` is not the supported validation path for
this repository because the packages use iOS APIs.

## Making changes

* Match the existing Swift 6.4, SwiftUI, Swift Testing, and Swift Package Manager
  patterns.
* Prefer initializer or protocol-based dependency injection.
* Keep reusable UI in `DesignSystem` and feature-specific behavior in its feature
  module.
* Keep domain contracts independent of UI concerns.
* Add regression coverage for parser, networking, persistence, or view-model changes.
* Use the deterministic UI fixture layer for UI tests; do not make tests depend on
  live Hacker News or Algolia responses.
* Update documentation when behavior, setup, supported platforms, or release steps
  change.

## Pull requests

Use a descriptive title and include:

* What changed and why.
* How the change was tested, including the simulator/device when relevant.
* Screenshots or a short recording for visual changes.
* Any follow-up work or known limitations.

Before requesting review, confirm that:

* The diff contains only task-related changes.
* New and changed behavior has appropriate tests.
* `swiftlint lint --config .swiftlint.yml` has been run when practical.
* `./run_tests.sh` passes, or failures are explained.
* `./run_ui_tests.sh smoke` passes for navigation or UI changes.
* Documentation and release notes are updated when needed.

Maintainers may ask for a focused follow-up rather than expanding a pull request
with unrelated cleanup.

## Reporting bugs and requesting features

Use the issue templates when available. Include the app version, iOS version, device
model, reproduction steps, expected behavior, actual behavior, and diagnostics that
do not contain private information. For visual bugs, include a screenshot or recording
when possible.

Do not report security vulnerabilities in a public issue; see [SECURITY.md](SECURITY.md).

## License

By contributing, you agree that your contribution will be licensed under the
repository's [MIT License](LICENSE).
