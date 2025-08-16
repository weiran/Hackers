//
//  Models.swift
//  Hackers
//
//  Created by Weiran Zhang on 25/05/2020.
//  Copyright © 2020 Weiran Zhang. All rights reserved.
//

import Foundation
import Combine

class Post: ObservableObject, Hashable, Identifiable {
    let id: Int
    let url: URL
    let title: String
    let age: String
    var commentsCount: Int
    let by: String
    @Published var score: Int
    let postType: PostType
    @Published var upvoted = false
    var voteLinks: (upvote: URL?, unvote: URL?)?
    var text: String?

    var comments: [Comment]?

    init(
        id: Int,
        url: URL,
        title: String,
        age: String,
        commentsCount: Int,
        by: String,
        score: Int,
        postType: PostType,
        upvoted: Bool
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
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: Post, rhs: Post) -> Bool {
        return lhs.id == rhs.id
    }
}

enum PostType: String, CaseIterable {
    case news
    case ask
    case show
    case jobs
    case newest
    case best
    case active
}

class Comment: Hashable {
    let id: Int
    let age: String
    let text: String
    let by: String
    var level: Int
    var upvoteLink: String?
    var upvoted = false
    var voteLinks: (upvote: URL?, unvote: URL?)?

    // UI properties
    var visibility = CommentVisibilityType.visible
    
    // Parsed HTML content for performance
    var parsedText: AttributedString?

    init(
        id: Int,
        age: String,
        text: String,
        by: String,
        level: Int,
        upvoted: Bool
    ) {
        self.id = id
        self.age = age
        self.text = text
        self.by = by
        self.level = level
        self.upvoted = upvoted
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: Comment, rhs: Comment) -> Bool {
        lhs.id == rhs.id
    }
}

enum CommentVisibilityType: Int {
    case visible = 3
    case compact = 2
    case hidden = 1
}

class User {
    let username: String
    let karma: Int
    let joined: Date

    init(username: String, karma: Int, joined: Date) {
        self.username = username
        self.karma = karma
        self.joined = joined
    }
}

enum HackersKitError: Error {
    case requestFailure
    case scraperError
    case unauthenticated // tried an request that requires authentication when unauthenticated
    case authenticationError(error: HackersKitAuthenticationError)
}

enum HackersKitAuthenticationError: Error {
    case badCredentials
    case serverUnreachable
    case noInternet
    case unknown
}
