//
//  Models.swift
//  Domain
//
//  Copyright © 2025 Weiran Zhang. All rights reserved.
//

import Foundation
import Observation

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
    var upvoted: Bool { get set }
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

@Observable
public final class Comment: @unchecked Sendable {
    nonisolated(unsafe) public let id: Int
    public let age: String
    public let text: String
    public let by: String
    public var level: Int
    public var upvoteLink: String?
    nonisolated(unsafe) public var upvoted: Bool
    nonisolated(unsafe) public var voteLinks: VoteLinks?
    public var visibility: CommentVisibilityType
    public var parsedText: AttributedString?

    public init(
        id: Int,
        age: String,
        text: String,
        by: String,
        level: Int,
        upvoted: Bool,
        upvoteLink: String? = nil,
        voteLinks: VoteLinks? = nil,
        visibility: CommentVisibilityType = .visible,
        parsedText: AttributedString? = nil,
    ) {
        self.id = id
        self.age = age
        self.text = text
        self.by = by
        self.level = level
        self.upvoted = upvoted
        self.upvoteLink = upvoteLink
        self.voteLinks = voteLinks
        self.visibility = visibility
        self.parsedText = parsedText
    }

}

extension Comment: Hashable {
    nonisolated(unsafe) public static func == (lhs: Comment, rhs: Comment) -> Bool {
        lhs.id == rhs.id
    }

    nonisolated(unsafe) public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
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
    case authenticationError(error: HackersKitAuthenticationError)
}

public enum HackersKitAuthenticationError: Error, Sendable {
    case badCredentials
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
