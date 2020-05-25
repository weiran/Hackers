//
//  HackerNewsModels.swift
//  Hackers
//
//  Created by Weiran Zhang on 25/05/2020.
//  Copyright © 2020 Glass Umbrella. All rights reserved.
//

import Foundation

class HackerNewsPost {
    let id: Int
    let url: URL
    let title: String
    let age: String
    let commentsCount: Int
    let by: String
    var score: Int
    let postType: HackerNewsPostType

    // UI properties
    var upvoted = false

    init(
        id: Int,
        url: URL,
        title: String,
        age: String,
        commentsCount: Int,
        by: String,
        score: Int,
        postType: HackerNewsPostType
    ) {
        self.id = id
        self.url = url
        self.title = title
        self.age = age
        self.commentsCount = commentsCount
        self.by = by
        self.score = score
        self.postType = postType
    }
}

class HackerNewsComment {
    let id: Int
    let age: String
    let text: String
    let by: String
    var level: Int
    var upvoteLink: String?

    // UI properties
    var visibility = CommentVisibilityType.visible
    var upvoted = false

    init(
        id: Int,
        age: String,
        text: String,
        by: String,
        level: Int
    ) {
        self.id = id
        self.age = age
        self.text = text
        self.by = by
        self.level = level
    }
}

enum HackerNewsPostType: String {
    case news
    case ask
    case jobs
    case new
}
