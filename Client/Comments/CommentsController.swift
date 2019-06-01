//
//  CommentsController.swift
//  Hackers2
//
//  Created by Weiran Zhang on 08/06/2014.
//  Copyright (c) 2014 Glass Umbrella. All rights reserved.
//

import Foundation

class CommentsController {
    public var comments: [CommentModel]

    public var visibleComments: [CommentModel] {
        return comments.filter { $0.visibility != CommentVisibilityType.hidden }
    }

    convenience init() {
        self.init(source: [CommentModel]())
    }

    init(source: [CommentModel]) {
        comments = source
    }

    public func toggleChildrenVisibility(of comment: CommentModel) -> ([IndexPath], CommentVisibilityType) {
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

    public func indexOfVisibleRootComment(of comment: CommentModel) -> Int? {
        guard let commentIndex = indexOfComment(comment, source: visibleComments) else { return nil }

        for index in (0...commentIndex).reversed() {
            // swiftlint:disable for_where
            if visibleComments[index].level == 0 {
                return index
            }
        }

        return nil
    }

    private func indexOfComment(_ comment: CommentModel, source: [CommentModel]) -> Int? {
        return source.firstIndex(where: { $0.commentID == comment.commentID })
    }

    private func countChildren(_ comment: CommentModel) -> Int {
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
