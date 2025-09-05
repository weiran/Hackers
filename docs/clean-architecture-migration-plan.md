
# Clean Architecture Migration Plan

This document provides a detailed, step-by-step plan for migrating the Hackers iOS app to the new Clean Architecture, as defined in `docs/clean-arch-strategy.md`.

## Phase 1: Foundation and Core Module Setup

This phase establishes the foundational packages (SPM modules) that all features will depend on.

### 1.1. Create Core SPM Packages

Create the following directories and `Package.swift` files for the core modules:

- `Domain`: For business logic, entities, and use case protocols.
- `Data`: For repository implementations.
- `Networking`: For the raw network client.
- `Shared`: For common extensions and utilities.
- `DesignSystem`: For reusable SwiftUI components.

### 1.2. Establish Core Protocols

In the `Domain` package, define the core protocols for the application's use cases and repositories.

**`Domain/Sources/Domain/PostUseCase.swift`**
```swift
public protocol PostUseCase {
    func getPosts(type: PostType, page: Int, nextId: Int?) async throws -> [Post]
    func getPost(id: Int) async throws -> Post
}
```

**`Domain/Sources/Domain/VoteUseCase.swift`**
```swift
public protocol VoteUseCase {
    func upvote(post: Post) async throws
    func unvote(post: Post) async throws
    func upvote(comment: Comment, for post: Post) async throws
    func unvote(comment: Comment, for post: Post) async throws
}
```

**`Domain/Sources/Domain/Models.swift`**
Refactor `Post` and `Comment` from `HackersKit` into the `Domain` module. They should be `struct`s conforming to `Sendable` and `Identifiable`.

### 1.3. Set Up Data Layer

In the `Data` package, create the repository implementation that conforms to the `Domain` protocols.

**`Data/Sources/Data/PostRepository.swift`**
```swift
import Domain
import Networking

public class PostRepository: PostUseCase, VoteUseCase {
    private let networkManager: NetworkManager // From the new Networking module

    public init(networkManager: NetworkManager) {
        self.networkManager = networkManager
    }

    // Implement all methods from PostUseCase and VoteUseCase
    // This is where the logic from the old HackersKit will be moved.
}
```

### 1.4. Dependency Injection

Set up a basic dependency injection container to manage the creation and provision of services like repositories and use cases.

## Phase 2: Feature Migration

Migrate features one by one, starting with the simplest.

### Feature 1: Settings

The Settings feature is the most straightforward, as it has minimal business logic and dependencies.

**Step 1: Create Feature Package**
- Create a new SPM package at `Features/Settings`.

**Step 2: Define Settings Use Cases (Domain)**
- In the `Domain` package, define a protocol for managing settings.
  **`Domain/Sources/Domain/SettingsUseCase.swift`**
  ```swift
  public protocol SettingsUseCase {
      var safariReaderMode: Bool { get set }
      var showThumbnails: Bool { get set }
      // ... other settings
  }
  ```

**Step 3: Implement Settings Repository (Data)**
- In the `Data` package, create `SettingsRepository` that implements `SettingsUseCase` and uses `UserDefaults`.

**Step 4: Refactor `SettingsView`**
- Create a new `SettingsViewModel` inside the `Features/Settings` package.
- The `SettingsViewModel` will take a `SettingsUseCase` as a dependency.
- `SettingsView` will be updated to use this new `ViewModel`. It will no longer directly use `SettingsStore` or `UserDefaults`.
- The old `App/Settings/SettingsStore.swift` can be removed.

### Feature 2: Feed

The Feed is a core feature with network requests and state management.

**Step 1: Create Feature Package**
- Create a new SPM package at `Features/Feed`.

**Step 2: Create `FeedViewModel`**
- Inside `Features/Feed`, create a new `FeedViewModel`.
- This ViewModel will depend on `PostUseCase` and `VoteUseCase` from the `Domain` layer.
- It will replicate the logic from the existing `SwiftUIFeedViewModel` and `FeedViewModel`, but without any direct reference to `HackersKit`.

**Step 3: Refactor `FeedView`**
- Update `FeedView` to use the new `FeedViewModel` from the `Features/Feed` package.
- All actions (loading feed, voting) will be dispatched to the new ViewModel.
- The old `App/Feed/FeedViewModel.swift` and the `SwiftUIFeedViewModel` wrapper can be removed.

**Step 4: Update Data Flow**
- The dependency injection container will provide the `FeedViewModel` with a `PostRepository` instance, which conforms to the required use case protocols.

### Feature 3: Comments

The Comments feature is the most complex, with hierarchical data and complex UI interactions.

**Step 1: Create Feature Package**
- Create a new SPM package at `Features/Comments`.

**Step 2: Define Comment Use Cases (Domain)**
- Enhance the `Domain` protocols if necessary to support comment-specific actions.
  **`Domain/Sources/Domain/CommentUseCase.swift`**
  ```swift
  public protocol CommentUseCase {
      func getComments(for post: Post) async throws -> [Comment]
  }
  ```

**Step 3: Implement Comment Repository (Data)**
- Add the comment-fetching logic to `PostRepository` (or a new `CommentRepository`), implementing the `CommentUseCase`.

**Step 4: Create `CommentsViewModel`**
- Inside `Features/Comments`, create a `CommentsViewModel`.
- This ViewModel will depend on `CommentUseCase` and `VoteUseCase`.
- It will encapsulate the logic currently found in `CommentsView` (for data loading and voting) and `CommentsController` (for managing the comment hierarchy).

**Step 5: Refactor `CommentsView`**
- Update `CommentsView` to use the new `CommentsViewModel`.
- The view will become a simpler representation of the state published by the ViewModel.
- The old `App/Comments/CommentsController.swift` can be removed.

## Phase 3: Cleanup and Verification

- Once all features are migrated, remove the old `App/Feed`, `App/Comments`, and `App/Settings` directories.
- Remove the `Shared Frameworks/HackersKit` directory, as its functionality will be fully replaced by the `Data` and `Networking` modules.
- Run all unit and UI tests to ensure no regressions have been introduced.
