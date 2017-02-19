//
//  CommentsController.swift
//  Hackers2
//
//  Created by Weiran Zhang on 08/06/2014.
//  Copyright (c) 2014 Glass Umbrella. All rights reserved.
//

import Foundation
import UIKit

class CommentsController {
    var comments: [CommentModel]
    
    var visibleComments: [CommentModel] {
        get {
            return comments.filter { $0.visibility != CommentVisibilityType.hidden }
        }
    }
    
    convenience init() {
        self.init(source: [CommentModel]())
    }
    
    init(source: [CommentModel]) {
        comments = source
    }
    
    func toggleCommentChildrenVisibility(_ comment: CommentModel) -> ([IndexPath], CommentVisibilityType) {
        let visible = comment.visibility == .visible
        let visibleIndex = indexOfComment(comment, source: visibleComments)!
        let commentIndex = indexOfComment(comment, source: comments)!

        let childrenCount = countChildren(comment)
        
        var modifiedIndexPaths = [IndexPath]()
        
        comment.visibility = visible ? .compact : .visible
        
        var currentIndex = visibleIndex + 1;
        
        if childrenCount > 0 {
            for i in 1...childrenCount {
                let currentComment = comments[commentIndex + i]
                
                if visible && currentComment.visibility == .hidden { continue }
                
                currentComment.visibility = visible ? .hidden : .visible
                modifiedIndexPaths.append(IndexPath(row: currentIndex, section: 0))
                currentIndex += 1
            }
        }
        
        return (modifiedIndexPaths, visible ? .hidden : .visible)
    }
    
    func indexOfComment(_ comment: CommentModel, source: [CommentModel]) -> Int? {
        for (index, value) in source.enumerated() {
            if comment.commentID == value.commentID { return index }
        }
        return nil
    }
    
    func countChildren(_ comment: CommentModel) -> Int {
        let startIndex = indexOfComment(comment, source: comments)! + 1
        var count = 0
        
        for i in startIndex...comments.count {
            let currentComment = comments[i]
            if (currentComment.level > comment.level) { count += 1 }
            else { break }
        }
        
        return count
    }
}
