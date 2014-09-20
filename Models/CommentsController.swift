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
        
        comment.visibility = visible ? .Compact : .Visible
        let (children, childrenIndexes) = childrenOfComment(comment)
        let originalIndex = indexOfComment(comment, source: comments)
        
        var modifiedIndexPaths = [NSIndexPath]()
        
        for (index, currentComment) in enumerate(children) {
            currentComment.visibility = visible ? .Hidden : .Visible
            if (visible) {
                modifiedIndexPaths.append(NSIndexPath(forRow: childrenIndexes[index], inSection: 0))
            } else {
                modifiedIndexPaths.append(NSIndexPath(forRow: originalIndex! + index, inSection: 0))
            }
        }
        
        return (modifiedIndexPaths, visible ? .Hidden : .Visible)
    }
    
    func indexOfComment(comment: CommentModel, source: [CommentModel]) -> Int? {
        for (index, value) in enumerate(source) {
            if comment.commentID == value.commentID {
                return index
            }
        }
        return nil
    }
    
    func childrenOfComment(comment: CommentModel) -> ([CommentModel], [Int]) {
        var indexes = [Int]()
        var commentModels = [CommentModel]()
        
        if var i = indexOfComment(comment, source: comments) {
            for i = i + 1; i < comments.count; i++ {
                let currentComment = comments[i]
                if currentComment.level > comment.level {
                    indexes.append(i)
                    commentModels.append(currentComment)
                } else {
                    break
                }
            }
        }
        
        return (commentModels, indexes)
    }
}