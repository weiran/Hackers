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
    case visible = 3
    case compact = 2
    case hidden = 1
}

class CommentModel {
    
    var type: HNCommentType
    var text: String
    var authorUsername: String
    var commentID: String
    var parentCommentID: String
    var dateCreatedString: String
    var replyURL: URL?
    var level: Int
    
    var visibility: CommentVisibilityType = .visible
    
    init(source: HNComment) {
        type = HNCommentType.default
        authorUsername = source.username
        commentID = source.commentId
        //parentCommentID = source.ParentID
        parentCommentID = ""
        dateCreatedString = source.timeCreatedString
        if let _ = source.replyURLString {
            replyURL = URL(string: source.replyURLString!)
        }
        level = Int(source.level)
        text = source.text
    }

    var Link: URL {
        return URL(string: "https://news.ycombinator.com/item?id=" + self.commentID)!
    }

    var PageTitle: String {
        return self.authorUsername + "'s comment on Hacker News"
    }

    var ActivityViewController: UIActivityViewController {
        return UIActivityViewController(activityItems: [self.PageTitle, self.Link], applicationActivities: nil)
    }
}
