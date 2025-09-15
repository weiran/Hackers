---
title: Coding Standards
version: 1.0.0
lastUpdated: 2025-01-15
audience: [developers]
tags: [standards, conventions, swift, best-practices]
---

# Coding Standards

This document defines the coding standards, conventions, and best practices for the Hackers iOS app codebase.

## 📋 Table of Contents

- [Swift Language Guidelines](#swift-language-guidelines)
- [Architecture Patterns](#architecture-patterns)
- [Naming Conventions](#naming-conventions)
- [File Organization](#file-organization)
- [SwiftUI Patterns](#swiftui-patterns)
- [Concurrency & Threading](#concurrency--threading)
- [Error Handling](#error-handling)
- [Testing Standards](#testing-standards)
- [Documentation Standards](#documentation-standards)

## Swift Language Guidelines

### Swift Version

- **Target**: Swift 6.2
- **iOS Deployment**: iOS 26.0+
- **Xcode**: Latest stable version
- **Strict Concurrency**: Enabled

### Language Features

#### Use Modern Swift Features

```swift
// ✅ Good: Use async/await
func loadPosts() async throws -> [Post] {
    return try await postRepository.getPosts()
}

// ❌ Avoid: Completion handlers for new code
func loadPosts(completion: @escaping (Result<[Post], Error>) -> Void) {
    // Avoid for new implementations
}
```

#### Leverage Type Safety

```swift
// ✅ Good: Strong typing
enum PostType: String, CaseIterable {
    case top = ""
    case new = "newest"
    case best = "best"
}

// ❌ Avoid: String literals
let postType = "newest" // Use enum instead
```

#### Use Sendable and Concurrency

```swift
// ✅ Good: Sendable conformance
public struct Post: Sendable, Identifiable {
    public let id: Int
    public let title: String
}

// ✅ Good: MainActor for UI
@MainActor
class FeedViewModel: ObservableObject {
    @Published var posts: [Post] = []
}
```

## Architecture Patterns

### Clean Architecture Layers

#### Domain Layer (Pure Swift)

```swift
// ✅ Domain models - no framework dependencies
public struct Comment: Sendable {
    public let id: Int
    public let text: AttributedString
    public let author: String
}

// ✅ Use case protocols
public protocol PostUseCase: Sendable {
    func getPosts(type: PostType) async throws -> [Post]
}
```

#### Data Layer (Repository Pattern)

```swift
// ✅ Repository implementation
public final class PostRepository: PostUseCase {
    private let networkManager: NetworkManagerProtocol

    public init(networkManager: NetworkManagerProtocol) {
        self.networkManager = networkManager
    }

    public func getPosts(type: PostType) async throws -> [Post] {
        // Implementation
    }
}
```

#### Presentation Layer (MVVM)

```swift
// ✅ Observable ViewModels
@Observable
class FeedViewModel {
    var posts: [Post] = []
    var isLoading = false

    private let postUseCase: PostUseCase

    init(postUseCase: PostUseCase) {
        self.postUseCase = postUseCase
    }

    @MainActor
    func loadPosts() async {
        isLoading = true
        defer { isLoading = false }

        do {
            posts = try await postUseCase.getPosts(type: .top)
        } catch {
            // Handle error
        }
    }
}
```

### Dependency Injection

#### Use Protocol-Based Injection

```swift
// ✅ Good: Protocol dependency
class FeedViewModel {
    private let postUseCase: PostUseCase // Protocol

    init(postUseCase: PostUseCase) {
        self.postUseCase = postUseCase
    }
}

// ❌ Avoid: Concrete dependency
class FeedViewModel {
    private let postRepository = PostRepository() // Concrete class
}
```

#### Centralized DI Container

```swift
// ✅ Use DependencyContainer
class DependencyContainer {
    static let shared = DependencyContainer()

    lazy var postUseCase: PostUseCase = {
        PostRepository(networkManager: networkManager)
    }()
}
```

## Naming Conventions

### General Rules

- Use **descriptive names** that clearly indicate purpose
- Prefer **clarity over brevity**
- Use **American English** spelling
- Follow Swift API Design Guidelines

### Types

```swift
// ✅ Good: Clear, descriptive type names
struct Post { }
class FeedViewModel { }
protocol PostUseCase { }
enum LoadingState<T> { }

// ❌ Avoid: Abbreviated or unclear names
struct P { }
class FVM { }
protocol PUC { }
```

### Variables and Functions

```swift
// ✅ Good: Descriptive function names
func loadPosts() async { }
func upvote(post: Post) async throws { }
var isLoading: Bool = false
let selectedPost: Post?

// ❌ Avoid: Unclear or abbreviated names
func load() { }
func vote(p: Post) { }
var loading = false
let sel: Post?
```

### Constants

```swift
// ✅ Good: Clear constant names
private let urlBase = "https://news.ycombinator.com"
private let maxRetryAttempts = 3
static let defaultTextSize: TextSize = .medium

// ❌ Avoid: Magic numbers or unclear names
private let url = "https://news.ycombinator.com"
private let max = 3
```

### Protocols

```swift
// ✅ Good: Capability-based naming
protocol PostUseCase { }
protocol VotingService { }
protocol NetworkManagerProtocol { }

// ❌ Avoid: Generic or unclear protocol names
protocol PostStuff { }
protocol Manager { }
```

## File Organization

### Project Structure

```
Hackers/
├── App/                          # Main app target
│   ├── HackersApp.swift         # App entry point
│   ├── ContentView.swift        # Root view
│   └── NavigationStore.swift    # Navigation state
├── Features/                     # Feature modules
│   ├── Feed/
│   ├── Comments/
│   ├── Settings/
│   └── Onboarding/
├── DesignSystem/                 # UI components
├── Shared/                       # Cross-cutting concerns
├── Domain/                       # Business logic
├── Data/                         # Data access
└── Networking/                   # HTTP client
```

### File Naming

```swift
// ✅ Good: Clear file names matching primary type
FeedView.swift           // Contains FeedView
FeedViewModel.swift      // Contains FeedViewModel
PostRepository.swift     // Contains PostRepository
Post.swift              // Contains Post model

// ❌ Avoid: Generic or unclear file names
Utils.swift
Helpers.swift
Models.swift (if containing multiple unrelated models)
```

### File Organization Within Files

```swift
// ✅ Good: Organized with MARK comments
import Foundation
import SwiftUI

// MARK: - Main Type
struct FeedView: View {
    @StateObject private var viewModel: FeedViewModel

    var body: some View {
        // Implementation
    }
}

// MARK: - Private Extensions
private extension FeedView {
    func makePostRow(post: Post) -> some View {
        // Helper view
    }
}

// MARK: - Preview
#Preview {
    FeedView(viewModel: FeedViewModel.preview)
}
```

## SwiftUI Patterns

### View Structure

```swift
// ✅ Good: Clean view structure
struct PostRowView: View {
    let post: Post
    let onUpvote: (Post) -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(post.title)
                    .font(.headline)
                Text(post.author)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            upvoteButton
        }
        .padding()
    }
}

// MARK: - Private Views
private extension PostRowView {
    var upvoteButton: some View {
        Button(action: { onUpvote(post) }) {
            Image(systemName: "arrow.up")
        }
    }
}
```

### State Management

```swift
// ✅ Good: Use @Observable for ViewModels
@Observable
class FeedViewModel {
    var posts: [Post] = []
    var isLoading = false

    // Methods...
}

// ✅ Good: Use @State for local UI state
struct FeedView: View {
    @State private var viewModel: FeedViewModel
    @State private var searchText = ""

    // Implementation...
}
```

### Environment Objects

```swift
// ✅ Good: Use for app-wide state
struct ContentView: View {
    @StateObject private var navigationStore = NavigationStore()

    var body: some View {
        NavigationStack {
            FeedView()
        }
        .environmentObject(navigationStore)
    }
}
```

## Concurrency & Threading

### Swift Concurrency

#### Use async/await

```swift
// ✅ Good: Async/await pattern
@MainActor
func loadPosts() async {
    isLoading = true
    defer { isLoading = false }

    do {
        let posts = try await postUseCase.getPosts(type: .top)
        self.posts = posts
    } catch {
        handleError(error)
    }
}
```

#### MainActor for UI Updates

```swift
// ✅ Good: MainActor isolation
@MainActor
class FeedViewModel: ObservableObject {
    @Published var posts: [Post] = []

    func updateUI() {
        // Safe to update UI directly
        posts = newPosts
    }
}
```

#### Sendable Conformance

```swift
// ✅ Good: Sendable for thread-safe types
public struct Post: Sendable {
    public let id: Int
    public let title: String
}

// ✅ Good: @unchecked Sendable for carefully managed types
public final class ThreadSafeDict<Key: Hashable, Value>: @unchecked Sendable {
    private var dict: [Key: Value] = [:]
    private let lock = NSLock()

    // Thread-safe implementation
}
```

### Task Management

```swift
// ✅ Good: Structured concurrency
func loadDataConcurrently() async {
    async let posts = postUseCase.getPosts()
    async let comments = commentUseCase.getComments()

    do {
        let (loadedPosts, loadedComments) = try await (posts, comments)
        // Use loaded data
    } catch {
        handleError(error)
    }
}
```

## Error Handling

### Error Types

```swift
// ✅ Good: Specific error types
public enum HackersKitError: Error, Sendable, Equatable {
    case networkError(String)
    case parsingError(String)
    case unauthenticated
    case scraperError
}
```

### Error Handling Patterns

```swift
// ✅ Good: Comprehensive error handling
func loadPosts() async {
    do {
        let posts = try await postUseCase.getPosts()
        self.posts = posts
    } catch let error as HackersKitError {
        switch error {
        case .networkError(let message):
            showError("Network Error: \(message)")
        case .unauthenticated:
            promptLogin()
        default:
            showError("An error occurred")
        }
    } catch {
        showError("Unexpected error: \(error.localizedDescription)")
    }
}
```

### Result Types

```swift
// ✅ Good: Use Result for complex error scenarios
func loadWithResult() async -> Result<[Post], HackersKitError> {
    do {
        let posts = try await postUseCase.getPosts()
        return .success(posts)
    } catch let error as HackersKitError {
        return .failure(error)
    } catch {
        return .failure(.networkError(error.localizedDescription))
    }
}
```

## Testing Standards

### Test Structure

```swift
// ✅ Good: Swift Testing framework
import Testing
@testable import Feed

@Suite("Feed ViewModel Tests")
struct FeedViewModelTests {

    @Test("Initial state returns empty posts")
    func initialState() {
        let viewModel = FeedViewModel(
            postUseCase: MockPostUseCase(),
            votingService: MockVotingService()
        )

        #expect(viewModel.posts.isEmpty)
        #expect(viewModel.isLoading == false)
    }

    @Test("Load posts updates state correctly")
    func loadPosts() async {
        let mockUseCase = MockPostUseCase()
        mockUseCase.mockPosts = [Post.preview]

        let viewModel = FeedViewModel(
            postUseCase: mockUseCase,
            votingService: MockVotingService()
        )

        await viewModel.loadPosts()

        #expect(viewModel.posts.count == 1)
        #expect(viewModel.posts.first?.title == "Test Post")
    }
}
```

### Mock Objects

```swift
// ✅ Good: Protocol-based mocks
final class MockPostUseCase: PostUseCase {
    var mockPosts: [Post] = []
    var shouldThrowError = false

    func getPosts(type: PostType, page: Int, nextId: Int?) async throws -> [Post] {
        if shouldThrowError {
            throw HackersKitError.networkError("Mock error")
        }
        return mockPosts
    }
}
```

## Documentation Standards

### Code Documentation

```swift
/// Loads posts from the API for the specified type and page.
///
/// - Parameters:
///   - type: The type of posts to load (top, new, best, etc.)
///   - page: The page number for pagination (0-based)
///   - nextId: Optional ID for continuation-based pagination
/// - Returns: An array of Post objects
/// - Throws: HackersKitError if the request fails
func getPosts(
    type: PostType,
    page: Int,
    nextId: Int? = nil
) async throws -> [Post] {
    // Implementation
}
```

### Inline Comments

```swift
// ✅ Good: Explain why, not what
// Prevent infinite redirect loops that could crash the app
guard response.url == request.url else {
    throw HackersKitError.scraperError
}

// ❌ Avoid: Obvious comments
// Create a new Post object
let post = Post(id: id, title: title)
```

### MARK Comments

```swift
// ✅ Good: Organize code sections
// MARK: - Public API
func loadPosts() async { }

// MARK: - Private Helpers
private func handleError(_ error: Error) { }

// MARK: - PostUseCase
extension PostRepository: PostUseCase {
    // Protocol implementation
}
```

---

## Code Review Checklist

Before submitting code, ensure:

- [ ] Follows naming conventions
- [ ] Proper error handling
- [ ] Thread safety with @MainActor and Sendable
- [ ] Comprehensive test coverage
- [ ] Documentation for public APIs
- [ ] No force unwrapping unless justified
- [ ] Clean architecture layer separation
- [ ] Protocol-based dependency injection

---

*These standards should be enforced through code review and automated tooling (SwiftLint, etc.)*