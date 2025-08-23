//
//  DomainBridge.swift
//  Hackers
//
//  Bridge between old HackersKit models and new Domain models
//

import Foundation
import Domain

// MARK: - Post Conversions

extension Post {
    /// Convert HackersKit Post to Domain Post
    func toDomain() -> Domain.Post {
        Domain.Post(
            id: id,
            url: url,
            title: title,
            age: age,
            commentsCount: commentsCount,
            by: by,
            score: score,
            postType: postType.toDomain(),
            upvoted: upvoted,
            voteLinks: voteLinks != nil ? Domain.VoteLinks(upvote: voteLinks!.upvote, unvote: voteLinks!.unvote) : nil,
            text: text,
            comments: comments?.map { $0.toDomain() }
        )
    }
}

extension Domain.Post {
    /// Convert Domain Post to HackersKit Post
    func toHackersKit() -> Post {
        let post = Post(
            id: id,
            url: url,
            title: title,
            age: age,
            commentsCount: commentsCount,
            by: by,
            score: score,
            postType: postType.toHackersKit(),
            upvoted: upvoted
        )
        post.voteLinks = voteLinks != nil ? (upvote: voteLinks!.upvote, unvote: voteLinks!.unvote) : nil
        post.text = text
        post.comments = comments?.map { $0.toHackersKit() }
        return post
    }
}

// MARK: - PostType Conversions

extension PostType {
    func toDomain() -> Domain.PostType {
        switch self {
        case .news: return .news
        case .ask: return .ask
        case .show: return .show
        case .jobs: return .jobs
        case .newest: return .newest
        case .best: return .best
        case .active: return .active
        }
    }
}

extension Domain.PostType {
    func toHackersKit() -> PostType {
        switch self {
        case .news: return .news
        case .ask: return .ask
        case .show: return .show
        case .jobs: return .jobs
        case .newest: return .newest
        case .best: return .best
        case .active: return .active
        }
    }
}

// MARK: - Comment Conversions

extension Comment {
    func toDomain() -> Domain.Comment {
        Domain.Comment(
            id: id,
            age: age,
            text: text,
            by: by,
            level: level,
            upvoted: upvoted,
            upvoteLink: nil,
            voteLinks: voteLinks != nil ? Domain.VoteLinks(upvote: voteLinks!.upvote, unvote: voteLinks!.unvote) : nil,
            visibility: visibility.toDomain()
        )
    }
}

extension Domain.Comment {
    func toHackersKit() -> Comment {
        let comment = Comment(
            id: id,
            age: age,
            text: text,
            by: by,
            level: level,
            upvoted: upvoted
        )
        comment.voteLinks = voteLinks != nil ? (upvote: voteLinks!.upvote, unvote: voteLinks!.unvote) : nil
        comment.visibility = visibility.toHackersKit()
        return comment
    }
}

// MARK: - CommentVisibilityType Conversions

extension CommentVisibilityType {
    func toDomain() -> Domain.CommentVisibilityType {
        switch self {
        case .visible: return .visible
        case .compact: return .compact
        case .hidden: return .hidden
        }
    }
}

extension Domain.CommentVisibilityType {
    func toHackersKit() -> CommentVisibilityType {
        switch self {
        case .visible: return .visible
        case .compact: return .compact
        case .hidden: return .hidden
        }
    }
}
