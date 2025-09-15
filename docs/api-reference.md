---
title: API Reference
version: 1.0.0
lastUpdated: 2025-01-15
audience: [developers]
tags: [api, protocols, models, reference]
---

# API Reference

Complete reference documentation for the Hackers iOS app's internal APIs, protocols, and models.

## 📋 Table of Contents

- [Domain Models](#domain-models)
- [Use Case Protocols](#use-case-protocols)
- [Service Protocols](#service-protocols)
- [Repository Interfaces](#repository-interfaces)
- [View Model APIs](#view-model-apis)
- [Networking Types](#networking-types)
- [Error Types](#error-types)

## Domain Models

### Post

Core model representing a Hacker News post.

```swift
public struct Post: Sendable, Identifiable, Equatable, Hashable {
    public let id: Int
    public let title: String
    public let url: URL?
    public let score: Int
    public let author: String
    public let timeAgo: String
    public let commentCount: Int
    public var upvoted: Bool
    public var voteLinks: VoteLinks?
    public var comments: [Comment]?
    public var commentUrl: URL?
    public var commentsLink: URL?
    public var thumbnailUrl: URL?
}
```

**Properties**:
- `id`: Unique identifier for the post
- `title`: Post title text
- `url`: External link (nil for Ask HN posts)
- `score`: Current upvote count
- `author`: Username of poster
- `timeAgo`: Human-readable time since posting
- `commentCount`: Number of comments
- `upvoted`: Whether current user has upvoted
- `voteLinks`: Voting URLs for authenticated users
- `comments`: Loaded comment tree (lazy loaded)
- `commentUrl`: URL to view comments
- `commentsLink`: Alternative comments URL
- `thumbnailUrl`: Preview image URL

### Comment

Represents a comment in a thread hierarchy.

```swift
public final class Comment: Sendable, Identifiable, ObservableObject {
    public let id: Int
    public let author: String
    public let timeAgo: String
    public let text: AttributedString
    public let level: Int
    public let voteLinks: VoteLinks?
    public var upvoted: Bool
    public var isVisible: Bool = true
    public var children: [Comment]
}
```

**Properties**:
- `id`: Unique comment identifier
- `author`: Username of commenter
- `timeAgo`: Human-readable timestamp
- `text`: Parsed HTML content as AttributedString
- `level`: Nesting depth in thread
- `voteLinks`: Voting URLs for authenticated users
- `upvoted`: Whether current user has upvoted
- `isVisible`: Whether comment is collapsed/visible
- `children`: Nested reply comments

### User

User account information.

```swift
public struct User: Sendable, Equatable {
    public let username: String
    public let karma: Int?
    public let about: String?
    public let created: String?
}
```

### VoteLinks

Voting action URLs for authenticated users.

```swift
public struct VoteLinks: Sendable, Equatable {
    public let upvote: URL?
    public let unvote: URL?  // Note: Unvote functionality removed
}
```

### PostType

Enumeration of available post feed types.

```swift
public enum PostType: String, CaseIterable, Sendable {
    case top = ""
    case new = "newest"
    case best = "best"
    case ask = "ask"
    case show = "show"
    case jobs = "jobs"
}
```

### TextSize

App text size preferences.

```swift
public enum TextSize: String, CaseIterable, Sendable {
    case small = "Small"
    case medium = "Medium"
    case large = "Large"
    case extraLarge = "Extra Large"
}
```

### VotingState

State tracking for voting operations.

```swift
public enum VotingState: Sendable, Equatable {
    case idle
    case voting
    case upvoted
    case error(String)
}
```

## Use Case Protocols

### PostUseCase

```swift
public protocol PostUseCase: Sendable {
    func getPosts(type: PostType, page: Int, nextId: Int?) async throws -> [Post]
    func getPost(id: Int) async throws -> Post
}
```

**Methods**:
- `getPosts(type:page:nextId:)`: Fetch paginated posts for given type
- `getPost(id:)`: Fetch single post with comments

### CommentUseCase

```swift
public protocol CommentUseCase: Sendable {
    func getComments(for post: Post) async throws -> [Comment]
}
```

### VoteUseCase

```swift
public protocol VoteUseCase: Sendable {
    func upvote(post: Post) async throws
    func upvote(comment: Comment, for post: Post) async throws
}
```

**Note**: Unvote functionality has been removed from the voting system.

### SettingsUseCase

```swift
public protocol SettingsUseCase: Sendable {
    var safariReaderMode: Bool { get set }
    var openInDefaultBrowser: Bool { get set }
    var textSize: TextSize { get set }
}
```

### AuthenticationUseCase

```swift
public protocol AuthenticationUseCase: Sendable {
    func login(username: String, password: String) async throws
    func logout() async throws
    var isLoggedIn: Bool { get async }
}
```

## Service Protocols

### VotingService

```swift
public protocol VotingService: Sendable {
    func upvote(post: Post) async throws
    func upvote(comment: Comment, for post: Post) async throws
    func votingState(for post: Post) -> VotingState
    func votingState(for comment: Comment) -> VotingState
}
```

**Implementation**:
```swift
public final class DefaultVotingService: VotingService, @unchecked Sendable {
    private let voteUseCase: VoteUseCase
    private let votingStates = ThreadSafeDict<Int, VotingState>()

    public init(voteUseCase: VoteUseCase) {
        self.voteUseCase = voteUseCase
    }
}
```

### NetworkManagerProtocol

```swift
public protocol NetworkManagerProtocol: Sendable {
    func get(url: URL) async throws -> String
    func post(url: URL, data: Data) async throws -> String
}
```

## Repository Interfaces

### PostRepository

```swift
public final class PostRepository: PostUseCase, VoteUseCase, CommentUseCase, Sendable {
    let networkManager: NetworkManagerProtocol
    let urlBase = "https://news.ycombinator.com"

    public init(networkManager: NetworkManagerProtocol)

    // PostUseCase implementation
    public func getPosts(type: PostType, page: Int, nextId: Int?) async throws -> [Post]
    public func getPost(id: Int) async throws -> Post

    // VoteUseCase implementation
    public func upvote(post: Post) async throws
    public func upvote(comment: Comment, for post: Post) async throws

    // CommentUseCase implementation
    public func getComments(for post: Post) async throws -> [Comment]
}
```

### SettingsRepository

```swift
public final class SettingsRepository: SettingsUseCase, Sendable {
    private let userDefaults: UserDefaultsProtocol

    public init(userDefaults: UserDefaultsProtocol = UserDefaults.standard)

    public var safariReaderMode: Bool { get set }
    public var openInDefaultBrowser: Bool { get set }
    public var textSize: TextSize { get set }
}
```

## View Model APIs

### FeedViewModel

```swift
@Observable
public class FeedViewModel {
    public var posts: [Post] = []
    public var selectedPostType: PostType = .top
    public var loadingState: LoadingState<[Post]> = .idle
    public var page = 0
    public private(set) var nextId: Int?

    public init(
        postUseCase: PostUseCase,
        votingService: VotingService
    )

    @MainActor
    public func loadPosts() async

    @MainActor
    public func loadMorePosts() async

    @MainActor
    public func selectPostType(_ type: PostType) async

    @MainActor
    public func upvote(post: Post) async
}
```

### CommentsViewModel

```swift
@Observable
public class CommentsViewModel {
    public var comments: [Comment] = []
    public var loadingState: LoadingState<[Comment]> = .idle
    public let post: Post

    public init(
        post: Post,
        commentUseCase: CommentUseCase,
        votingService: VotingService
    )

    @MainActor
    public func loadComments() async

    @MainActor
    public func upvote(comment: Comment) async

    @MainActor
    public func toggleVisibility(for comment: Comment)
}
```

### SettingsViewModel

```swift
@Observable
public class SettingsViewModel {
    public var safariReaderMode: Bool
    public var openInDefaultBrowser: Bool
    public var textSize: TextSize

    public init(settingsUseCase: SettingsUseCase)
}
```

## Networking Types

### NetworkManager

```swift
public final class NetworkManager: NetworkManagerProtocol, @unchecked Sendable {
    private let session: URLSession

    public init(session: URLSession = .shared)

    public func get(url: URL) async throws -> String
    public func post(url: URL, data: Data) async throws -> String
}
```

### URLRequest Extensions

```swift
extension URLRequest {
    static func hackersRequest(url: URL) -> URLRequest
}
```

## Error Types

### HackersKitError

```swift
public enum HackersKitError: Error, Sendable, Equatable {
    case networkError(String)
    case parsingError(String)
    case unauthenticated
    case scraperError
    case invalidUrl
    case noData
}
```

**Cases**:
- `networkError`: Network request failures
- `parsingError`: HTML parsing failures
- `unauthenticated`: Authentication required
- `scraperError`: Web scraping issues
- `invalidUrl`: Malformed URL
- `noData`: Empty response

### LoadingState

```swift
public enum LoadingState<T>: Sendable where T: Sendable {
    case idle
    case loading
    case loaded(T)
    case error(Error)
}
```

## Utility Types

### LoadingStateManager

```swift
@Observable
public class LoadingStateManager<T: Sendable>: Sendable {
    public var state: LoadingState<T> = .idle

    @MainActor
    public func load(operation: @escaping @Sendable () async throws -> T) async

    @MainActor
    public func reset()
}
```

### ThreadSafeDict

```swift
public final class ThreadSafeDict<Key: Hashable & Sendable, Value: Sendable>: @unchecked Sendable {
    private var dict: [Key: Value] = [:]
    private let lock = NSLock()

    public subscript(key: Key) -> Value? { get set }
    public func removeValue(forKey key: Key) -> Value?
    public func removeAll()
}
```

## HTML Parsing API

### CommentHTMLParser

```swift
public enum CommentHTMLParser {
    public static func parseHTMLText(_ htmlString: String) -> AttributedString
    static func decodeHTMLEntities(_ text: String) -> String
    static func processFormattingTags(_ text: String) -> AttributedString
    static func stripHTMLTags(_ text: String) -> String
}
```

**Features**:
- Converts HTML to AttributedString with formatting
- Supports bold, italic, and code formatting
- Handles nested HTML structures
- Preserves whitespace when appropriate
- Decodes HTML entities

---

## Usage Examples

### Loading Posts

```swift
let viewModel = FeedViewModel(
    postUseCase: DependencyContainer.shared.postUseCase,
    votingService: DependencyContainer.shared.votingService
)

await viewModel.loadPosts()
```

### Parsing Comments

```swift
let commentUseCase = DependencyContainer.shared.commentUseCase
let comments = try await commentUseCase.getComments(for: post)
```

### Voting on Content

```swift
let votingService = DependencyContainer.shared.votingService
try await votingService.upvote(post: selectedPost)
```

---

*For implementation details, see the source code in the respective modules.*