//
//  CommentModel.swift
//  Hackers2
//
//  Created by Weiran Zhang on 08/06/2014.
//  Copyright (c) 2014 Glass Umbrella. All rights reserved.
//

import Foundation
import HNScraper

enum CommentVisibilityType: Int {
    case visible = 3
    case compact = 2
    case hidden = 1
}

class CommentModel {
    var type: HNComment.HNCommentType
    var text: String
    var authorUsername: String
    var commentID: String
    var parentCommentID: String
    var dateCreatedString: String
    var replyURL: URL?
    var level: Int
    var upvoted: Bool

    var visibility: CommentVisibilityType = .visible
    var source: HNComment

    init(source: HNComment) {
        self.type = source.type
        self.authorUsername = source.username
        self.commentID = source.id
        //parentCommentID = source.ParentID
        self.parentCommentID = ""
        self.dateCreatedString = source.created
        if let _ = source.replyUrl {
            self.replyURL = URL(string: source.replyUrl)
        }
        self.level = Int(source.level)
        self.text = source.text
        self.upvoted = source.upvoted
        self.source = source
    }
}
