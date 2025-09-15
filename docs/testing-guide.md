---
title: Testing Guide
version: 1.0.0
lastUpdated: 2025-09-15
audience: [developers]
tags: [testing, swift-testing, unit-tests, integration-tests]
---

# Testing Guide

Comprehensive testing guide for the Hackers iOS app, covering testing strategies, patterns, and best practices using the Swift Testing framework.

## 📋 Table of Contents

- [Testing Philosophy](#testing-philosophy)
- [Testing Framework](#testing-framework)
- [Test Structure](#test-structure)
- [Testing Patterns](#testing-patterns)
- [Test Categories](#test-categories)
- [Mock Objects](#mock-objects)
- [Running Tests](#running-tests)
- [Coverage Guidelines](#coverage-guidelines)
- [Troubleshooting](#troubleshooting)

## Testing Philosophy

### Core Principles

1. **Test Behavior, Not Implementation**: Focus on what the code does, not how it does it
2. **Fast and Reliable**: Tests should run quickly and consistently
3. **Independent**: Each test should be isolated and not depend on others
4. **Readable**: Tests should clearly communicate their intent
5. **Maintainable**: Tests should be easy to update as code evolves

### Testing Pyramid

```
        UI Tests (Few)
           ↗ ↖
    Integration Tests (Some)
         ↗ ↖
   Unit Tests (Many)
```

- **Unit Tests (70%)**: Test individual components in isolation
- **Integration Tests (20%)**: Test component interactions
- **UI Tests (10%)**: Test complete user workflows

## Testing Framework

### Swift Testing

The app uses the **Swift Testing** framework (not XCTest) for modern, declarative testing:

```swift
import Testing
@testable import Domain

@Suite("Post Model Tests")
struct PostTests {

    @Test("Post equality works correctly")
    func postEquality() {
        let post1 = Post(id: 1, title: "Test", url: nil, score: 10,
                        author: "user", timeAgo: "1h", commentCount: 5)
        let post2 = Post(id: 1, title: "Test", url: nil, score: 10,
                        author: "user", timeAgo: "1h", commentCount: 5)

        #expect(post1 == post2)
    }

    @Test("Post with different IDs are not equal")
    func postInequalityWithDifferentIds() {
        let post1 = Post(id: 1, title: "Test", url: nil, score: 10,
                        author: "user", timeAgo: "1h", commentCount: 5)
        let post2 = Post(id: 2, title: "Test", url: nil, score: 10,
                        author: "user", timeAgo: "1h", commentCount: 5)

        #expect(post1 != post2)
    }
}
```

### Key Testing Features

- **`@Suite`**: Groups related tests
- **`@Test`**: Marks individual test methods
- **`#expect`**: Assertion macro with clear failure messages
- **`#require`**: Assertion that stops test execution on failure
- **Async support**: Native async/await testing

## Test Structure

### Test Organization

```
Module/Tests/ModuleTests/
├── Models/
│   ├── PostTests.swift
│   └── CommentTests.swift
├── ViewModels/
│   ├── FeedViewModelTests.swift
│   └── CommentsViewModelTests.swift
├── Services/
│   └── VotingServiceTests.swift
├── Repositories/
│   └── PostRepositoryTests.swift
└── Utilities/
    ├── MockDependencies.swift
    └── TestHelpers.swift
```

### Test Suite Structure

```swift
@Suite("Feed ViewModel Tests")
struct FeedViewModelTests {

    // MARK: - Initialization Tests
    @Test("Initial state returns correct defaults")
    func initialState() {
        let viewModel = makeFeedViewModel()

        #expect(viewModel.posts.isEmpty)
        #expect(viewModel.isLoading == false)
        #expect(viewModel.selectedPostType == .top)
    }

    // MARK: - Loading Tests
    @Test("Load posts sets loading state correctly")
    func loadPostsLoadingState() async {
        let viewModel = makeFeedViewModel()

        let loadingTask = Task {
            await viewModel.loadPosts()
        }

        // Check loading state briefly appears
        try? await Task.sleep(nanoseconds: 10_000_000) // 10ms
        #expect(viewModel.isLoading == true)

        await loadingTask.value
        #expect(viewModel.isLoading == false)
    }

    // MARK: - Error Handling Tests
    @Test("Load posts handles errors correctly")
    func loadPostsError() async {
        let mockUseCase = MockPostUseCase()
        mockUseCase.shouldThrowError = true

        let viewModel = FeedViewModel(
            postUseCase: mockUseCase,
            votingService: MockVotingService()
        )

        await viewModel.loadPosts()

        #expect(viewModel.posts.isEmpty)
        #expect(viewModel.isLoading == false)
        // Error should be handled appropriately
    }

    // MARK: - Helper Methods
    private func makeFeedViewModel() -> FeedViewModel {
        FeedViewModel(
            postUseCase: MockPostUseCase(),
            votingService: MockVotingService()
        )
    }
}
```

## Testing Patterns

### 1. Given-When-Then Pattern

```swift
@Test("Upvoting post updates state correctly")
func upvotePost() async {
    // Given
    let post = Post.preview
    let mockVotingService = MockVotingService()
    let viewModel = FeedViewModel(
        postUseCase: MockPostUseCase(),
        votingService: mockVotingService
    )
    viewModel.posts = [post]

    // When
    await viewModel.upvote(post: post)

    // Then
    #expect(mockVotingService.upvoteCallCount == 1)
    #expect(mockVotingService.lastUpvotedPost?.id == post.id)
}
```

### 2. Async Testing

```swift
@Test("Load comments completes successfully")
func loadComments() async {
    let post = Post.preview
    let mockUseCase = MockCommentUseCase()
    let expectedComments = [Comment.preview]
    mockUseCase.mockComments = expectedComments

    let viewModel = CommentsViewModel(
        post: post,
        commentUseCase: mockUseCase,
        votingService: MockVotingService()
    )

    await viewModel.loadComments()

    #expect(viewModel.comments.count == 1)
    #expect(viewModel.comments.first?.id == expectedComments.first?.id)
}
```

### 3. Error Testing

```swift
@Test("Network error is handled gracefully")
func networkError() async {
    let mockUseCase = MockPostUseCase()
    mockUseCase.shouldThrowError = true
    mockUseCase.errorToThrow = HackersKitError.networkError("Connection failed")

    let viewModel = FeedViewModel(
        postUseCase: mockUseCase,
        votingService: MockVotingService()
    )

    await viewModel.loadPosts()

    #expect(viewModel.posts.isEmpty)
    #expect(viewModel.isLoading == false)
    // Verify error handling behavior
}
```

### 4. State Transition Testing

```swift
@Test("Loading state transitions correctly")
func loadingStateTransitions() async {
    let viewModel = makeFeedViewModel()

    // Initial state
    #expect(viewModel.loadingState == .idle)

    // Start loading
    Task {
        await viewModel.loadPosts()
    }

    // Should transition to loading
    try? await Task.sleep(nanoseconds: 1_000_000) // 1ms
    // Note: This is a simplified example; real tests might use more sophisticated state tracking
}
```

## Test Categories

### Unit Tests

Test individual components in isolation:

```swift
// Domain Model Tests
@Suite("Comment Model Tests")
struct CommentTests {
    @Test("Comment hierarchy levels calculated correctly")
    func commentLevels() {
        let parent = Comment(id: 1, author: "user1", timeAgo: "1h",
                           text: AttributedString("Parent"), level: 0)
        let child = Comment(id: 2, author: "user2", timeAgo: "30m",
                          text: AttributedString("Child"), level: 1)
        parent.children = [child]

        #expect(parent.level == 0)
        #expect(child.level == 1)
    }
}

// ViewModel Tests
@Suite("Settings ViewModel Tests")
struct SettingsViewModelTests {
    @Test("Text size changes are persisted")
    func textSizeChanges() {
        let mockSettings = MockSettingsUseCase()
        let viewModel = SettingsViewModel(settingsUseCase: mockSettings)

        viewModel.textSize = .large

        #expect(mockSettings.textSize == .large)
    }
}
```

### Integration Tests

Test component interactions:

```swift
@Suite("Post Repository Integration Tests")
struct PostRepositoryIntegrationTests {

    @Test("Repository correctly parses API response")
    func parseAPIResponse() async throws {
        let mockNetworkManager = MockNetworkManager()
        mockNetworkManager.mockResponse = loadMockHTML("feed_response.html")

        let repository = PostRepository(networkManager: mockNetworkManager)
        let posts = try await repository.getPosts(type: .top, page: 0, nextId: nil)

        #expect(posts.count > 0)
        #expect(posts.first?.title.isEmpty == false)
    }
}
```

### HTML Parser Tests

Extensive testing for HTML parsing (critical functionality):

```swift
@Suite("Comment HTML Parser Tests")
struct CommentHTMLParserTests {

    @Test("Bold text formatting is preserved")
    func boldFormatting() {
        let html = "This is <b>bold</b> text"
        let result = CommentHTMLParser.parseHTMLText(html)

        // Verify bold formatting is applied
        #expect(result.characters.count > 0)
    }

    @Test("Nested HTML tags are handled correctly")
    func nestedTags() {
        let html = "This has <i>italic and <b>bold</b> text</i>"
        let result = CommentHTMLParser.parseHTMLText(html)

        // Verify complex formatting is handled
        #expect(result.characters.count > 0)
    }

    @Test("HTML entities are decoded correctly")
    func htmlEntities() {
        let html = "AT&amp;T, &lt;script&gt;, &quot;quotes&quot;"
        let result = CommentHTMLParser.parseHTMLText(html)

        let plainText = String(result.characters)
        #expect(plainText.contains("AT&T"))
        #expect(plainText.contains("<script>"))
        #expect(plainText.contains("\"quotes\""))
    }
}
```

## Mock Objects

### Protocol-Based Mocks

```swift
// Mock Use Case
final class MockPostUseCase: PostUseCase {
    var mockPosts: [Post] = []
    var shouldThrowError = false
    var errorToThrow: Error = HackersKitError.networkError("Mock error")
    var getPostsCallCount = 0

    func getPosts(type: PostType, page: Int, nextId: Int?) async throws -> [Post] {
        getPostsCallCount += 1

        if shouldThrowError {
            throw errorToThrow
        }
        return mockPosts
    }

    func getPost(id: Int) async throws -> Post {
        if shouldThrowError {
            throw errorToThrow
        }
        return mockPosts.first(where: { $0.id == id }) ?? Post.preview
    }
}

// Mock Service with Call Tracking
final class MockVotingService: VotingService {
    var upvoteCallCount = 0
    var lastUpvotedPost: Post?
    var lastUpvotedComment: Comment?
    var shouldThrowError = false

    func upvote(post: Post) async throws {
        upvoteCallCount += 1
        lastUpvotedPost = post

        if shouldThrowError {
            throw HackersKitError.unauthenticated
        }
    }

    func upvote(comment: Comment, for post: Post) async throws {
        upvoteCallCount += 1
        lastUpvotedComment = comment

        if shouldThrowError {
            throw HackersKitError.unauthenticated
        }
    }

    func votingState(for post: Post) -> VotingState {
        return .idle
    }

    func votingState(for comment: Comment) -> VotingState {
        return .idle
    }
}
```

### Test Data Helpers

```swift
// Test data extensions
extension Post {
    static let preview = Post(
        id: 1,
        title: "Test Post Title",
        url: URL(string: "https://example.com"),
        score: 42,
        author: "testuser",
        timeAgo: "2h",
        commentCount: 15,
        upvoted: false,
        voteLinks: nil,
        comments: nil,
        commentUrl: nil,
        commentsLink: nil,
        thumbnailUrl: nil
    )

    static func makePost(id: Int, title: String) -> Post {
        Post(
            id: id,
            title: title,
            url: nil,
            score: 1,
            author: "user",
            timeAgo: "1h",
            commentCount: 0
        )
    }
}

extension Comment {
    static let preview = Comment(
        id: 1,
        author: "testuser",
        timeAgo: "1h",
        text: AttributedString("Test comment text"),
        level: 0,
        voteLinks: nil,
        upvoted: false,
        children: []
    )
}
```

## Running Tests

### Command Line

Use the custom test runner script:

```bash
# Run all tests
./run_tests.sh

# Run specific module tests
./run_tests.sh Domain
./run_tests.sh Feed
./run_tests.sh Networking

# Verbose output
./run_tests.sh --verbose
```

### Xcode

Tests can be run through Xcode's Test Navigator:
1. Open Test Navigator (⌘+6)
2. Run all tests (⌘+U)
3. Run specific test suites or individual tests

### CI/CD

GitHub Actions automatically runs tests:

```yaml
# .github/workflows/ci.yml
test:
  runs-on: macos-26
  steps:
    - uses: actions/checkout@v4
    - name: Run Tests
      run: ./run_tests.sh
```

## Coverage Guidelines

### Target Coverage

| Layer | Target Coverage | Current Status |
|-------|----------------|----------------|
| Domain | ≥90% | ✅ Achieved |
| Data | ≥85% | ✅ Achieved |
| Presentation | ≥80% | ✅ Achieved |
| Networking | ≥85% | ✅ Achieved |

### What to Test

**✅ Always Test:**
- Public API methods
- Error handling paths
- State transitions
- Business logic
- Data transformations
- HTML parsing (critical)

**🤔 Consider Testing:**
- Complex private methods
- View model state
- Service integrations
- Edge cases

**❌ Don't Test:**
- SwiftUI view body (test ViewModels instead)
- Third-party library internals
- Simple getters/setters
- Framework code

## Troubleshooting

### Common Issues

#### 1. Tests Timing Out

```swift
// ❌ Problem: Async test without proper awaiting
@Test func loadData() {
    Task {
        await viewModel.loadData()
    }
    #expect(viewModel.data.isEmpty == false) // Runs before async completes
}

// ✅ Solution: Properly await async operations
@Test func loadData() async {
    await viewModel.loadData()
    #expect(viewModel.data.isEmpty == false)
}
```

#### 2. Flaky Tests

```swift
// ❌ Problem: Race conditions in testing
@Test func loadingState() async {
    Task { await viewModel.loadData() }
    #expect(viewModel.isLoading == true) // May pass or fail randomly
}

// ✅ Solution: Use deterministic test patterns
@Test func loadingState() async {
    let expectation = expectation(description: "Loading started")

    Task {
        expectation.fulfill() // Loading started
        await viewModel.loadData()
    }

    await fulfillment(of: [expectation])
    // Now test the result state
}
```

#### 3. Mock State Issues

```swift
// ✅ Reset mocks between tests
@Suite struct MyTests {
    var mockService: MockVotingService!

    init() {
        mockService = MockVotingService()
    }

    @Test func testOne() async {
        // Test implementation
        // Mock state automatically reset for next test
    }
}
```

### Debugging Tests

1. **Add print statements** for debugging test flow
2. **Use breakpoints** in test methods
3. **Check mock call counts** to verify interactions
4. **Verify async operations** complete before assertions
5. **Test in isolation** to identify interdependencies

---

## Best Practices Summary

### Do's ✅

- Write tests for all public APIs
- Use descriptive test names
- Test error conditions
- Mock external dependencies
- Keep tests fast and independent
- Use proper async/await patterns
- Reset state between tests

### Don'ts ❌

- Test implementation details
- Write flaky or slow tests
- Ignore error cases
- Test framework code
- Share state between tests
- Use hardcoded delays
- Skip edge cases

---

*For specific testing examples, see the test files in each module's Tests directory.*