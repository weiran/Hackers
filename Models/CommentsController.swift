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
    var comments: CommentModel[] = CommentModel[]()
    var commentsSource: CommentModel[] {
        didSet { comments = commentsSource.copy() }
    }
    
    init() {
        commentsSource = CommentModel[]()
        comments = commentsSource
    }
    
    init(source: CommentModel[]) {
        comments = CommentModel[]()
        commentsSource = source
    }

    func toggleCommentChildrenVisibility(commentIndexPath: NSIndexPath) -> (NSIndexPath[], CommentVisibilityType) {
        let comment = comments[commentIndexPath.row]
        switch comment.visibility {
            case .Visible:
                return (hideCommentChildren(commentIndexPath), .Hidden)
            case .Compact:
                return (showCommentChildren(commentIndexPath), .Visible)
            default:
                return (NSIndexPath[](), .Visible)
        }
    }

    func showCommentChildren(commentIndexPath: NSIndexPath) -> NSIndexPath[] {
        let comment = comments[commentIndexPath.row]
        let (children, childrenIndexes) = childrenOfComment(comment)
        comment.visibility = .Visible
        
        var indexPaths = NSIndexPath[]()
        
        for (index, currentComment) in enumerate(children) {
            currentComment.visibility = .Visible
            if let sourceCommentIndex = indexOfComment(currentComment, source: commentsSource) {
                let viewIndex = index + commentIndexPath.row + 1
                comments.insert(currentComment, atIndex: viewIndex)
                indexPaths.append(NSIndexPath(forRow: viewIndex, inSection: 0))
            }
        }
        
        return indexPaths
    }

    func hideCommentChildren(commentIndexPath: NSIndexPath) -> NSIndexPath[] {
        let comment = comments[commentIndexPath.row]
        let (children, childrenIndexes) = childrenOfComment(comment)
        comment.visibility = .Compact
        
        var indexPaths = NSIndexPath[]()
        
        for (index, currentComment) in enumerate(children) {
            currentComment.visibility = .Hidden
            if let displayedCommentIndex = indexOfComment(currentComment, source: comments) {
                comments.removeAtIndex(displayedCommentIndex)
                indexPaths.append(NSIndexPath(forRow: displayedCommentIndex, inSection: 0))
            }
        }
        
        return indexPaths
    }
    
    func indexOfComment(comment: CommentModel, source: CommentModel[]) -> Int? {
        var indexPathInSource: Int?
        for (index, value) in enumerate(source) {
            if comment.commentID == value.commentID {
                indexPathInSource = index
                break
            }
        }
        return indexPathInSource
    }
    
    func childrenOfComment(comment: CommentModel) -> (CommentModel[], Int[]) {
        var indexes = Int[]()
        var commentModels = CommentModel[]()
        
        if var i = indexOfComment(comment, source: commentsSource) {
            for i = i + 1; i < commentsSource.count; i++ {
                let currentComment = commentsSource[i]
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