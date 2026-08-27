//
//  Models.swift
//  Domain
//
//  Copyright © 2025 Weiran Zhang. All rights reserved.
//

import Foundation

// MARK: - Voting System

public struct VotingState: Sendable {
    public let isUpvoted: Bool
    public let score: Int?
    public let canVote: Bool
    public let canUnvote: Bool
    public let isVoting: Bool
    public let error: Error?

    public init(
        isUpvoted: Bool,
        score: Int? = nil,
        canVote: Bool,
        canUnvote: Bool = false,
        isVoting: Bool = false,
        error: Error? = nil,
    ) {
        self.isUpvoted = isUpvoted
        self.score = score
        self.canVote = canVote
        self.canUnvote = canUnvote
        self.isVoting = isVoting
        self.error = error
    }
}

public protocol Votable: Identifiable, Sendable {
    var id: Int { get }
    var upvoted: Bool { get }
    var voteLinks: VoteLinks? { get }
}

public protocol ScoredVotable: Votable {
    var score: Int { get set }
}

public struct VoteLinks: Sendable, Hashable {
    public let upvote: URL?
    public let unvote: URL?

    public init(upvote: URL?, unvote: URL?) {
        self.upvote = upvote
        self.unvote = unvote
    }
}

extension VoteLinks: CustomStringConvertible {
    public var description: String {
        "VoteLinks(upvote: \(upvote?.absoluteString ?? "nil"), unvote: \(unvote?.absoluteString ?? "nil"))"
    }
}

public struct Post: Sendable, Identifiable, Hashable {
    public let id: Int
    public let url: URL
    public let title: String
    public let age: String
    public var commentsCount: Int
    public let by: String
    public var score: Int
    public let postType: PostType
    public var upvoted: Bool
    public var isBookmarked: Bool
    public var isRead: Bool
    public var voteLinks: VoteLinks?
    public var text: String?
    public var comments: [Comment]?

    public init(
        id: Int,
        url: URL,
        title: String,
        age: String,
        commentsCount: Int,
        by: String,
        score: Int,
        postType: PostType,
        upvoted: Bool,
        isBookmarked: Bool = false,
        isRead: Bool = false,
        voteLinks: VoteLinks? = nil,
        text: String? = nil,
        comments: [Comment]? = nil,
    ) {
        self.id = id
        self.url = url
        self.title = title
        self.age = age
        self.commentsCount = commentsCount
        self.by = by
        self.score = score
        self.postType = postType
        self.upvoted = upvoted
        self.isBookmarked = isBookmarked
        self.isRead = isRead
        self.voteLinks = voteLinks
        self.text = text
        self.comments = comments
    }
}

public enum PostType: String, CaseIterable, Sendable {
    case news
    case ask
    case show
    case jobs
    case newest
    case best
    case active
    case bookmarks
}

/// An immutable, parsed Hacker News comment.
///
/// Deliberately a value type so it can be produced off the main actor by the parser and
/// observed on the main actor without unsynchronized sharing. UI-facing mutable state
/// (upvoted, visibility) is owned and mutated by the `@MainActor` view models that hold a
/// `[Comment]`, never by mutating a shared instance.
public struct Comment: Sendable, Identifiable {
    public let id: Int
    public let age: String
    public let text: String
    public let by: String
    public let isFlagged: Bool
    public let level: Int
    public let upvoted: Bool
    public let voteLinks: VoteLinks?
    public let visibility: CommentVisibilityType

    public init(
        id: Int,
        age: String,
        text: String,
        by: String,
        isFlagged: Bool = false,
        level: Int,
        upvoted: Bool,
        voteLinks: VoteLinks? = nil,
        visibility: CommentVisibilityType = .visible,
    ) {
        self.id = id
        self.age = age
        self.text = text
        self.by = by
        self.isFlagged = isFlagged
        self.level = level
        self.upvoted = upvoted
        self.voteLinks = voteLinks
        self.visibility = visibility
    }
}

extension Comment: Hashable {
    /// Content equality: comments are equal only when every rendered field matches.
    /// SwiftUI's ForEach/LazyVStack row diffing uses `==` to decide whether a row's
    /// content closure needs re-invoking, so identity-only equality (same id) hid
    /// content-only updates such as an optimistic upvote and the row kept rendering
    /// stale state. Hashing stays keyed by id: content-equal comments always share
    /// an id, so equal values still hash equally.
    public static func == (lhs: Comment, rhs: Comment) -> Bool {
        lhs.id == rhs.id
            && lhs.age == rhs.age
            && lhs.text == rhs.text
            && lhs.by == rhs.by
            && lhs.isFlagged == rhs.isFlagged
            && lhs.level == rhs.level
            && lhs.upvoted == rhs.upvoted
            && lhs.voteLinks == rhs.voteLinks
            && lhs.visibility == rhs.visibility
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

public extension Comment {
    /// Returns a copy with a different `upvoted` flag. For value-type optimistic updates.
    func with(upvoted: Bool) -> Comment {
        Comment(
            id: id, age: age, text: text, by: by, isFlagged: isFlagged, level: level,
            upvoted: upvoted, voteLinks: voteLinks, visibility: visibility
        )
    }

    /// Returns a copy with different `voteLinks`. For value-type optimistic updates.
    func with(voteLinks: VoteLinks?) -> Comment {
        Comment(
            id: id, age: age, text: text, by: by, isFlagged: isFlagged, level: level,
            upvoted: upvoted, voteLinks: voteLinks, visibility: visibility
        )
    }

    /// Returns a copy with different `visibility`. For value-type collapse/expand updates.
    func withVisibility(_ visibility: CommentVisibilityType) -> Comment {
        Comment(
            id: id, age: age, text: text, by: by, isFlagged: isFlagged, level: level,
            upvoted: upvoted, voteLinks: voteLinks, visibility: visibility
        )
    }
}

public enum CommentVisibilityType: Int, Sendable {
    case visible = 3
    case compact = 2
    case hidden = 1
}

public struct User: Sendable {
    public let username: String
    public let karma: Int
    public let joined: Date

    public init(username: String, karma: Int, joined: Date) {
        self.username = username
        self.karma = karma
        self.joined = joined
    }
}

public enum HackersKitError: Error, Sendable {
    case requestFailure
    case scraperError
    case unauthenticated
    /// Hacker News refused the vote itself (e.g. an unvote outside the short window
    /// it allows), served as a bare error page rather than the usual whence redirect.
    case voteRejected
    case authenticationError(error: HackersKitAuthenticationError)
}

extension HackersKitError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .voteRejected:
            "Hacker News didn’t accept this vote. Votes can only be undone shortly after they’re cast."
        default:
            nil
        }
    }
}

public enum HackersKitAuthenticationError: Error, Sendable {
    case badCredentials
    case sessionNotEstablished
    case serverUnreachable
    case noInternet
    case unknown
}

// MARK: - Extensions

public extension PostType {
    var title: String {
        switch self {
        case .news: "Top"
        case .ask: "Ask"
        case .show: "Show"
        case .jobs: "Jobs"
        case .newest: "New"
        case .best: "Best"
        case .active: "Active"
        case .bookmarks: "Bookmarks"
        }
    }
}

// MARK: - Votable Conformance

extension Post: ScoredVotable {}
extension Comment: Votable {}
