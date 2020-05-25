//
//  HackerNewsModels.swift
//  Hackers
//
//  Created by Weiran Zhang on 25/05/2020.
//  Copyright © 2020 Weiran Zhang. All rights reserved.
//

import Foundation

class HackerNewsPost: Hashable {
    let id: Int
    let url: URL
    let title: String
    let age: String
    let commentsCount: Int
    let by: String
    var score: Int
    let postType: HackerNewsPostType
    var upvoted = false

    init(
        id: Int,
        url: URL,
        title: String,
        age: String,
        commentsCount: Int,
        by: String,
        score: Int,
        postType: HackerNewsPostType,
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

    static func == (lhs: HackerNewsPost, rhs: HackerNewsPost) -> Bool {
        return lhs.id == rhs.id
    }
}

class HackerNewsComment: Hashable {
    let id: Int
    let age: String
    let text: String
    let by: String
    var level: Int
    var upvoteLink: String?
    var upvoted = false

    // UI properties
    var visibility = CommentVisibilityType.visible

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

    static func == (lhs: HackerNewsComment, rhs: HackerNewsComment) -> Bool {
        lhs.id == rhs.id
    }
}

enum HackerNewsPostType: String {
    case news
    case ask
    case jobs
    case new
}

enum HackerNewsError: Error {
    case typeError
    case hnScraperError
}

enum CommentVisibilityType: Int {
    case visible = 3
    case compact = 2
    case hidden = 1
}
