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
    
    init() {
        comments = [CommentModel]()
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
        
        for var i = 1; i <= childrenCount; i++ {
            let currentComment = comments[commentIndex + i]
            
            if (visible && currentComment.visibility == .Hidden) { continue }
            
            currentComment.visibility = visible ? .Hidden : .Visible
            modifiedIndexPaths.append(NSIndexPath(forRow: currentIndex++, inSection: 0))
        }
        
        return (modifiedIndexPaths, visible ? .Hidden : .Visible)
    }
    
    func indexOfComment(comment: CommentModel, source: [CommentModel]) -> Int? {
        for (index, value) in enumerate(source) {
            if comment.commentID == value.commentID { return index }
        }
        return nil
    }
    
    func countChildren(comment: CommentModel) -> Int {
        var i = indexOfComment(comment, source: comments)!
        var count = 0
        
        for i++; i < comments.count; i++ {
            let currentComment = comments[i]
            if (currentComment.level > comment.level) { count++ }
            else { break }
        }
        
        return count
    }
}