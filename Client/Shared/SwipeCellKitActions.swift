//
//  CellSwipeActions.swift
//  Hackers
//
//  Created by Weiran Zhang on 01/06/2019.
//  Copyright © 2019 Weiran Zhang. All rights reserved.
//

import UIKit
import SwipeCellKit
import Loaf

class SwipeCellKitActions: Themed {
    private let authenticationUIService: AuthenticationUIService

    init(authenticationUIService: AuthenticationUIService) {
        self.authenticationUIService = authenticationUIService
    }

    func voteAction(post: HackerNewsPost, tableView: UITableView,
                           indexPath: IndexPath, viewController: UIViewController) -> [SwipeAction] {
        let voteOnPost: (HackerNewsPost, Bool) -> Void = { post, isUpvote in
            guard let cell = tableView.cellForRow(at: indexPath) as? PostCell else { return }
            post.upvoted = isUpvote
            post.score += isUpvote ? 1 : -1
            cell.postTitleView.post = post
        }

        let errorHandler: (Error) -> Void = { error in
            guard let error = error as? HackerNewsError else { return }
            switch error {
            case .unauthenticated:
                viewController.present(self.authenticationUIService.unauthenticatedAlertController(), animated: true)
            default:
                Loaf("Error connecting to Hacker News", state: .error, sender: viewController).show()
            }

            // revert to the previous post state
            voteOnPost(post, !post.upvoted)
        }

        let upvoteAction = SwipeAction(style: .default, title: "Up") { _, _ in
            let upvoted = post.upvoted
            voteOnPost(post, !post.upvoted)
            if upvoted {
                HackerNewsData.shared
                    .unvote(post: post)
                    .catch(errorHandler)
            } else {
                HackerNewsData.shared
                    .upvote(post: post)
                    .catch(errorHandler)
            }
        }
        upvoteAction.backgroundColor = themeProvider.currentTheme.upvotedColor
        upvoteAction.textColor = .white

        let iconImage = UIImage(named: "PointsIcon")!.withTint(color: .white)
        upvoteAction.image = iconImage

        return [upvoteAction]
    }

    func voteAction(
        comment: HackerNewsComment,
        post: HackerNewsPost,
        tableView: UITableView,
        indexPath: IndexPath,
        viewController: UIViewController
    ) -> [SwipeAction] {
        let voteOnComment: (HackerNewsComment, Bool) -> Void = { comment, isUpvote in
            guard let cell = tableView.cellForRow(at: indexPath) as? CommentTableViewCell else { return }
            comment.upvoted = isUpvote
            cell.updateCommentContent(with: comment, theme: self.themeProvider.currentTheme)
        }

        let errorHandler: (Error) -> Void = { error in
            guard let error = error as? HackerNewsError else { return }
            switch error {
            case .unauthenticated:
                viewController.present(self.authenticationUIService.unauthenticatedAlertController(), animated: true)
            default:
                Loaf("Error connecting to Hacker News", state: .error, sender: viewController).show()
            }

            // revert to the previous post state
            voteOnComment(comment, !comment.upvoted)
        }

        let voteAction = SwipeAction(style: .default, title: "Up") { _, _ in
            let upvoted = comment.upvoted
            voteOnComment(comment, !comment.upvoted)
            if upvoted {
                HackerNewsData.shared
                    .unvote(comment: comment, for: post)
                    .catch(errorHandler)
            } else {
                HackerNewsData.shared
                    .upvote(comment: comment, for: post)
                    .catch(errorHandler)
            }
        }
        voteAction.backgroundColor = themeProvider.currentTheme.upvotedColor
        voteAction.textColor = .white

        let iconImage = UIImage(named: "PointsIcon")!.withTint(color: .white)
        voteAction.image = iconImage

        return [voteAction]
    }
}

extension SwipeCellKitActions {
    func applyTheme(_ theme: AppTheme) {}
}
