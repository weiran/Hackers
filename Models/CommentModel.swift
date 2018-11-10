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
    
    var visibility: CommentVisibilityType = .visible
    
    init(source: HNComment) {
        type = source.type
        authorUsername = source.username
        commentID = source.id
        //parentCommentID = source.ParentID
        parentCommentID = ""
        dateCreatedString = source.created
        if let _ = source.replyUrl {
            replyURL = URL(string: source.replyUrl)
        }
        level = Int(source.level)
        text = source.text
    }
    
}
