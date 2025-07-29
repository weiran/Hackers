//
//  CellSwipeActions.swift
//  Hackers
//
//  Created by Weiran Zhang on 01/06/2019.
//  Copyright © 2019 Weiran Zhang. All rights reserved.
//

import UIKit
import SwipeCellKit

class SwipeCellKitActions {
    func voteAction(
        post: Post,
        tableView: UITableView,
        indexPath: IndexPath,
        viewController: UIViewController
    ) -> [SwipeAction] {
        let voteOnPost: (Post, Bool) -> Void = { post, isUpvote in
            guard let cell = tableView.cellForRow(at: indexPath) as? PostCell else { return }
            post.upvoted = isUpvote
            post.score += isUpvote ? 1 : -1
            cell.postTitleView.post = post
        }

        let errorHandler: (Error) -> Void = { error in
            guard let error = error as? HackersKitError else { return }
            switch error {
            case .unauthenticated:
                viewController.present(
                    AuthenticationHelper.unauthenticatedAlertController(viewController),
                    animated: true
                )
            default:
                UINotifications.showError()
            }

            // revert to the previous post state
            voteOnPost(post, !post.upvoted)
        }

        let upvoteAction = SwipeAction(style: .default, title: "Up") { _, _ in
            let upvoted = post.upvoted
            voteOnPost(post, !post.upvoted)
            
            Task {
                do {
                    if upvoted {
                        try await HackersKit.shared.unvote(post: post)
                    } else {
                        try await HackersKit.shared.upvote(post: post)
                    }
                } catch {
                    await MainActor.run {
                        errorHandler(error)
                    }
                }
            }
        }
        upvoteAction.backgroundColor = AppTheme.default.upvotedColor
        upvoteAction.textColor = .white

        let iconImage = UIImage(named: "PointsIcon")!.withTintColor(.white)
        upvoteAction.image = iconImage

        return [upvoteAction]
    }

    func voteAction(
        comment: Comment,
        post: Post,
        tableView: UITableView,
        indexPath: IndexPath,
        viewController: UIViewController
    ) -> [SwipeAction] {
        let voteOnComment: (Comment, Bool) -> Void = { comment, isUpvote in
            guard let cell = tableView.cellForRow(at: indexPath) as? CommentTableViewCell else { return }
            comment.upvoted = isUpvote
            cell.updateCommentContent(with: comment)
        }

        let errorHandler: (Error) -> Void = { error in
            guard let error = error as? HackersKitError else { return }
            switch error {
            case .unauthenticated:
                viewController.present(
                    AuthenticationHelper.unauthenticatedAlertController(viewController),
                    animated: true
                )
            default:
                UINotifications.showError()
            }

            // revert to the previous post state
            voteOnComment(comment, !comment.upvoted)
        }

        let voteAction = SwipeAction(style: .default, title: "Up") { _, _ in
            let upvoted = comment.upvoted
            voteOnComment(comment, !comment.upvoted)
            
            Task {
                do {
                    if upvoted {
                        try await HackersKit.shared.unvote(comment: comment, for: post)
                    } else {
                        try await HackersKit.shared.upvote(comment: comment, for: post)
                    }
                } catch {
                    await MainActor.run {
                        errorHandler(error)
                    }
                }
            }
        }
        voteAction.backgroundColor = AppTheme.default.upvotedColor
        voteAction.textColor = .white

        let iconImage = UIImage(named: "PointsIcon")!.withTintColor(.white)
        voteAction.image = iconImage

        return [voteAction]
    }
}
