# Bash Commands
* To build: bundle exec fastlane build
* To test: bundle exec fastlane test
* To lint: bundle exec fastlane lint

# Coding Guidelines
* Aim to build all functionality using SwiftUI unless there is a feature that is only supported in UIKit.
* Design UI in a way that is idiomatic for the iOS platform and follows Apple Human Interface Guidelines.
* Use SF Symbols for iconography.
* Use the most modern iOS APIs. This app can target the latest iOS version with the newest APIs.
* Use the most modern Swift language features and conventions. Target Swift 6 and use Swift concurrency (async/await, actors) and Swift macros where applicable.

# Testing Procedure
* After making code changes, always test that the app still builds.
* If the app builds, run it on the simulator with MCP.
<!-- * If the change is to any part of the UI, take a screeshot of the simulator on that part of the app and verify the change has indeed been implemented correctly. -->