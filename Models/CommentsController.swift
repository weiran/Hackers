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
            return comments.filter { $0.visibility != CommentVisibilityType.Hidden }
        }
    }
    
    convenience init() {
        self.init(source: [CommentModel]())
    }
    
    init(source: [CommentModel]) {
        comments = source
    }
    
    func toggleCommentChildrenVisibility(comment: CommentModel) -> ([NSIndexPath], CommentVisibilityType) {
        let visible = comment.visibility == .Visible
        let visibleIndex = indexOfComment(comment, source: visibleComments)!
        let commentIndex = indexOfComment(comment, source: comments)!

        let childrenCount = countChildren(comment)
        
        var modifiedIndexPaths = [NSIndexPath]()
        
        comment.visibility = visible ? .Compact : .Visible
        
        var currentIndex = visibleIndex + 1;
        
        if childrenCount > 0 {
            for i in 1...childrenCount {
                let currentComment = comments[commentIndex + i]
                
                if visible && currentComment.visibility == .Hidden { continue }
                
                currentComment.visibility = visible ? .Hidden : .Visible
                modifiedIndexPaths.append(NSIndexPath(forRow: currentIndex, inSection: 0))
                currentIndex += 1
            }
        }
        
        return (modifiedIndexPaths, visible ? .Hidden : .Visible)
    }
    
    func indexOfComment(comment: CommentModel, source: [CommentModel]) -> Int? {
        for (index, value) in source.enumerate() {
            if comment.commentID == value.commentID { return index }
        }
        return nil
    }
    
    func countChildren(comment: CommentModel) -> Int {
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