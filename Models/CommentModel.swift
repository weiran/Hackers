//
//  CommentModel.swift
//  Hackers2
//
//  Created by Weiran Zhang on 08/06/2014.
//  Copyright (c) 2014 Glass Umbrella. All rights reserved.
//

import Foundation
import libHN

enum CommentVisibilityType: Int {
    case Visible = 3
    case Compact = 2
    case Hidden = 1
}

class CommentModel {
    
    var type: HNCommentType
    var text: String
    var authorUsername: String
    var commentID: String
    var parentCommentID: String
    var dateCreatedString: String
    var replyURL: NSURL?
    var level: Int
    
    var visibility: CommentVisibilityType = .Visible
    
    init(source: HNComment) {
        type = HNCommentType.Default
        authorUsername = source.Username
        commentID = source.CommentId
        //parentCommentID = source.ParentID
        parentCommentID = ""
        dateCreatedString = source.TimeCreatedString
        if let _ = source.ReplyURLString {
            replyURL = NSURL(string: source.ReplyURLString!)
        }
        level = Int(source.Level)
        text = source.Text
    }
    
}