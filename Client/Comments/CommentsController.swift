//
//  CommentsController.swift
//  Hackers2
//
//  Created by Weiran Zhang on 08/06/2014.
//  Copyright (c) 2014 Weiran Zhang. All rights reserved.
//

import Foundation

class CommentsController {
    var comments: [Comment]

    var visibleComments: [Comment] {
        return comments.filter { $0.visibility != CommentVisibilityType.hidden }
    }

    convenience init() {
        self.init(source: [Comment]())
    }

    init(source: [Comment]) {
        comments = source
    }

    func toggleChildrenVisibility(of comment: Comment) -> ([IndexPath], CommentVisibilityType) {
        let visible = comment.visibility == .visible
        let visibleIndex = indexOfComment(comment, source: visibleComments)!
        let commentIndex = indexOfComment(comment, source: comments)!
        let childrenCount = countChildren(comment)
        var modifiedIndexPaths = [IndexPath]()

        comment.visibility = visible ? .compact : .visible

        var currentIndex = visibleIndex + 1

        if childrenCount > 0 {
            for childIndex in 1...childrenCount {
                let currentComment = comments[commentIndex + childIndex]

                if visible && currentComment.visibility == .hidden { continue }

                currentComment.visibility = visible ? .hidden : .visible
                modifiedIndexPaths.append(IndexPath(row: currentIndex, section: 1))
                currentIndex += 1
            }
        }

        return (modifiedIndexPaths, visible ? .hidden : .visible)
    }

    func indexOfVisibleRootComment(of comment: Comment) -> Int? {
        guard let commentIndex = indexOfComment(comment, source: visibleComments) else { return nil }

        for index in (0...commentIndex).reversed() where visibleComments[index].level == 0 {
            return index
        }

        return nil
    }

    private func indexOfComment(_ comment: Comment, source: [Comment]) -> Int? {
        return source.firstIndex(where: { $0.id == comment.id })
    }

    private func countChildren(_ comment: Comment) -> Int {
        let startIndex = indexOfComment(comment, source: comments)! + 1
        var count = 0

        // if last comment, there are no children
        guard startIndex < comments.count else {
            return 0
        }

        for index in startIndex...comments.count - 1 {
            let currentComment = comments[index]
            if currentComment.level > comment.level {
                count += 1
            } else {
                break
            }
        }

        return count
    }
}
