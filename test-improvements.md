# Test Improvements

- **Domain Use Cases (`Domain/Tests/DomainTests/UseCaseTests.swift:91`)**
  - Current assertions only verify counters on bespoke mocks, so the real use case wiring is never exercised. Replace the mocks with integration-style tests that drive `PostRepository`, `SettingsRepository`, and other concrete implementations through their Domain protocols to catch regressions in the actual logic.

- **Post Repository (`Data/Tests/DataTests/PostRepositoryTests.swift:94`)**
  - Several tests merely check URL strings, and the network error case never forces a failure. Expand coverage with HTML fixtures that assert the parsed `Post`/`Comment` contents, pagination tokens, and explicit error propagation to harden the HTML parsing surface.

- **LinkOpener Utility (`Shared/Tests/SharedTests/LinkOpenerTests.swift:27`)**
  - Many expectations end in `#expect(true)`, so behaviour changes will not fail the suite. Refactor the tests to stub URL-opening side effects (e.g. inject a custom opener) and assert concrete outcomes such as which URL is forwarded.

- **Design System Colours (`DesignSystem/Tests/DesignSystemTests/AppColorsTests.swift:28`)**
  - Equality checks compare values retrieved from the same static accessor, again resulting in tautologies. Assert real colour components or verify bundle asset lookups using known fixtures so regressions surface.

- **Feature ViewModels (`Features/Feed/Tests/FeedViewModelTests.swift:14`, `Features/Settings/Tests/SettingsViewModelTests.swift:72`, `Features/Comments/Tests/CommentsViewModelTests.swift:76`)**
  - Coverage focuses on happy paths; loading-state transitions, error handling, dependency injection defaults, pagination, and vote rollbacks are untested. Add scenarios that simulate failing use cases, verify spinner flags, and ensure optimistic updates roll back on errors.

- **Dependency Container (`Shared/Tests/SharedTests/DependencyContainerTests.swift:83`)**
  - Tests boot the singleton with live `NetworkManager` and `UserDefaults`, expecting thrown errors or no-ops. Introduce injection points or factory overrides so the container graph can be validated deterministically without relying on real networking.
