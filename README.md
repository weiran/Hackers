# Hackers

[![Swift 6.2](https://img.shields.io/badge/Swift-6.2-orange.svg?logo=swift&logoColor=white)](https://swift.org)
[![CI](https://github.com/weiran/Hackers/actions/workflows/pr.yml/badge.svg)](https://github.com/weiran/Hackers/actions/workflows/pr.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

Hackers is an open-source Hacker News client for iPhone and iPad.

It focuses on fast feed browsing, readable comment threads, voting, bookmarks, search, Dynamic Type, VoiceOver, dark mode, and a native iOS/iPadOS experience. Version 5 is a SwiftUI rebuild with a modular Swift Package layout.

[Download on the App Store](https://apps.apple.com/us/app/hackers-for-hacker-news/id603503901)  
[Join the TestFlight beta](https://testflight.apple.com/join/UDLeEQde)

![Hackers screenshot](https://github.com/user-attachments/assets/378e848f-6ef8-4238-972e-95e6c8f93869)

## Features

* Browse Top, New, Best, Ask, Show, Jobs, and Active stories.
* Read nested comments with collapse/expand controls.
* Open stories in the in-app browser with comments available alongside the page.
* Vote on posts and comments when signed in.
* Save bookmarks and search Hacker News content.
* Use the share extension to open Hacker News links in Hackers.
* Supports Dynamic Type, VoiceOver, dark mode, and high-contrast-friendly styling.
* No ads, no tracking, no analytics.

## Requirements

* iOS/iPadOS 26 or later
* Xcode 26.4 for development
* Swift 6.2

The app also runs on Apple Silicon Macs and visionOS through Apple's platform compatibility support.

## Build

Open `Hackers.xcodeproj` in Xcode and run the `Hackers` scheme.

Command-line build from the repository root:

```bash
xcodebuild -project Hackers.xcodeproj -scheme Hackers -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

## Test

Use the project test runner:

```bash
./run_tests.sh
```

Run a specific module:

```bash
./run_tests.sh Domain
./run_tests.sh Feed Comments Settings
```

Do not use `swift test` for project validation; the packages target iOS APIs and need an iOS Simulator destination.

## Documentation

The maintained docs are intentionally small:

* [Project overview](docs/project-overview.md)
* [Development guide](docs/development.md)
* [Release process](docs/release-process.md)

## Contributing

Issues and pull requests are welcome. Before opening a PR:

* Run `./run_tests.sh`.
* Keep changes scoped.
* Add or update tests for behavior changes.
* Follow the existing SwiftUI, Swift Testing, and package patterns.

## Privacy

Hackers collects no data. The App Store privacy label is `Data Not Collected`.

## License

Hackers is released under the [MIT License](LICENSE).
