//
//  CommentsViewController.swift
//  Hackers
//
//  Created by Weiran Zhang on 07/06/2014.
//  Copyright (c) 2014 Weiran Zhang. All rights reserved.
//

import Foundation
import UIKit
import SafariServices
import SwipeCellKit
import PromiseKit
import Loaf

class CommentsViewController: UITableViewController {
    var authenticationUIService: AuthenticationUIService?
    var swipeCellKitActions: SwipeCellKitActions?
    var navigationService: NavigationService?

    private enum ActivityType {
        case comments
        case link(url: URL)
    }

    var postId: Int?
    var post: Post?

    private var comments: [Comment]? {
        didSet { commentsController.comments = comments! }
    }
    private let commentsController = CommentsController()

    @IBOutlet var loadingView: UIView!
    private var notificationToken: NotificationToken?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupCollectionView()
        load()
    }

    deinit {
        tearDownHandoff()
    }

    @objc private func load(showSpinner: Bool = true) {
        if showSpinner {
            tableView.backgroundView = TableViewBackgroundView.loadingBackgroundView()
        }

        firstly {
            loadPost()
        }.then { (post) -> Promise<[Comment]> in
            self.post = post
            self.setupHandoff(with: post, activityType: .comments)
            return self.loadComments(for: post)
        }.done { comments in
            self.comments = comments
            self.tableView.reloadData()
        }.catch { error in
            Loaf("Error connecting to Hacker News", state: .error, sender: self).show()
        }.finally {
            self.tableView.backgroundView = nil
            self.refreshControl?.endRefreshing()
        }
    }

    private func loadPost() -> Promise<Post> {
        if let post = self.post {
            return Promise.value(post)
        }
        return HackersKit.shared.getPost(id: postId!, includeAllComments: true)
    }

    private func loadComments(for post: Post) -> Promise<[Comment]> {
        // if it already has comments then use those
        if let comments = post.comments {
            return Promise.value(comments)
        }

        // otherwise always try to fetch comments
        return firstly {
            HackersKit.shared.getPost(id: post.id, includeAllComments: true)
        }.map { post in
            return post.comments ?? []
        }
    }

    private func observeNotifications() {
        notificationToken = NotificationCenter.default
            .observe(name: Notification.Name.refreshRequired,
                     object: nil, queue: .main) { _ in self.load(showSpinner: false) }
    }

    override func updateUserActivityState(_ activity: NSUserActivity) {
        activity.addUserInfoEntries(from: [:])
        super.updateUserActivityState(activity)
    }

    @IBAction private func shareTapped(_ sender: UIBarButtonItem) {
        guard let post = post else {
            return
        }

        guard post.url.host != nil else {
            // hostless url means its an internal Hacker News link
            // can also check postType but this is more future proof
            self.showShareSheet(url: post.hackerNewsURL, sender: sender)
            return
        }

        let alertController = UIAlertController(
            title: nil, message: nil, preferredStyle: .actionSheet)
        alertController.popoverPresentationController?.barButtonItem = sender

        let postLinkAction = UIAlertAction(
            title: "Article Link", style: .default) { _ in
                self.showShareSheet(url: post.url, sender: sender)
        }
        alertController.addAction(postLinkAction)

        let hackerNewsLinkAction = UIAlertAction(
            title: "Hacker News Link", style: .default) { _ in
                self.showShareSheet(url: post.hackerNewsURL, sender: sender)
        }
        alertController.addAction(hackerNewsLinkAction)

        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))

        present(alertController, animated: true)
    }

    private func showShareSheet(url: URL, sender: UIBarButtonItem) {
        let activityViewController = UIActivityViewController(
            activityItems: [url],
            applicationActivities: nil
        )
        activityViewController.popoverPresentationController?.barButtonItem = sender
        present(activityViewController, animated: true, completion: nil)
    }
}

// MARK: - Table data source
extension CommentsViewController {
    enum CommentsTableSections: Int, CaseIterable {
        case post = 0
        case comments = 1
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return CommentsTableSections.allCases.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return post == nil ? 0 : 1
        default: return commentsController.visibleComments.count
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case CommentsTableSections.post.rawValue:
            return postCell(for: post, in: tableView, with: indexPath)

        // we disable no_fallthrough_only here as it's a valid case to use it
        // swiftlint:disable no_fallthrough_only
        case CommentsTableSections.comments.rawValue: fallthrough
        // swiftlint:enable no_fallthrough_only

        default:
            let comment = commentsController.visibleComments[indexPath.row]
            return commentCell(for: comment, in: tableView, with: indexPath)
        }
    }

    // disabling force cast here as we want the app to crash if the table can't dequeue a cell
    // swiftlint:disable force_cast
    private func postCell(for post: Post?, in tableView: UITableView, with indexPath: IndexPath) -> PostCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PostCell", for: indexPath) as! PostCell

        cell.delegate = self
        cell.postTitleView.post = post
        cell.setImageWithPlaceholder(url: post?.url)
        cell.thumbnailImageView.isUserInteractionEnabled = false

        return cell
    }

    private func commentCell(
        for comment: Comment,
        in tableView: UITableView,
        with indexPath: IndexPath
    ) -> CommentTableViewCell {
        let cellIdentifier = comment.visibility == CommentVisibilityType.visible ?
            "OpenCommentCell" : "ClosedCommentCell"

        let cell = tableView.dequeueReusableCell(
            withIdentifier: cellIdentifier,
            for: indexPath
        ) as! CommentTableViewCell

        let isPostAuthor = comment.by == post?.by ?? ""
        cell.updateCommentContent(with: comment, isPostAuthor: isPostAuthor)
        cell.commentDelegate = self
        cell.delegate = self

        return cell
    }
    // swiftlint:enable force_cast
}

// long taps
extension CommentsViewController {
    override func tableView(
        _ tableView: UITableView,
        contextMenuConfigurationForRowAt indexPath: IndexPath,
        point: CGPoint
    ) -> UIContextMenuConfiguration? {
        guard let comment = comments?[indexPath.row], let post = post else { return nil }
        let actionOnPost = indexPath.section == 0
        let upvoted = actionOnPost ? post.upvoted : comment.upvoted

        return UIContextMenuConfiguration(
            identifier: nil,
            previewProvider: nil
        ) { _ in
            let voteAction: () -> Void = {
                if actionOnPost {
                    self.vote(on: post, at: indexPath)
                } else {
                    self.vote(on: comment, for: post, at: indexPath)
                }
            }

            let upvote = UIAction(
                title: "Upvote",
                image: UIImage(systemName: "arrow.up"),
                identifier: UIAction.Identifier(rawValue: "upvote")
            ) { _ in
                voteAction()
            }

            let unvote = UIAction(
                title: "Unvote",
                image: UIImage(systemName: "arrow.uturn.down"),
                identifier: UIAction.Identifier(rawValue: "unvote")
            ) { _ in
                voteAction()
            }

            let share = UIAction(
                title: "Share",
                image: UIImage(systemName: "square.and.arrow.up"),
                identifier: UIAction.Identifier(rawValue: "share.comment")
            ) { [weak self] _ in
                self?.shareComment(at: indexPath)
            }

            let voteMenu = upvoted ? unvote : upvote
            let shareMenu = UIMenu(title: "", options: .displayInline, children: [share])

            return UIMenu(title: "", image: nil, identifier: nil, children: [voteMenu, shareMenu])
        }
    }

    private func vote(on post: Post, at indexPath: IndexPath) {
        let voteOnPost: (Post, Bool) -> Void = { post, isUpvote in
            guard let cell = self.tableView.cellForRow(at: indexPath) as? PostCell else { return }
            post.upvoted = isUpvote
            post.score += isUpvote ? 1 : -1
            cell.postTitleView.post = post
        }

        let errorHandler: (Error) -> Void = { error in
            guard let error = error as? HackersKitError else { return }
            switch error {
            case .unauthenticated:
                self.present(
                    self.authenticationUIService!.unauthenticatedAlertController(),
                    animated: true
                )
            default:
                Loaf("Error connecting to Hacker News", state: .error, sender: self).show()
            }

            // revert to the previous post state
            voteOnPost(post, !post.upvoted)
        }

        let upvoted = post.upvoted
        voteOnPost(post, !post.upvoted)
        if upvoted {
            HackersKit.shared
                .unvote(post: post)
                .catch(errorHandler)
        } else {
            HackersKit.shared
                .upvote(post: post)
                .catch(errorHandler)
        }
    }

    private func vote(on comment: Comment, for post: Post, at indexPath: IndexPath) {
        let voteOnComment: (Comment, Bool) -> Void = { comment, isUpvote in
            guard let cell = self.tableView.cellForRow(at: indexPath) as? CommentTableViewCell else { return }
            comment.upvoted = isUpvote
            cell.updateCommentContent(with: comment)
        }

        let errorHandler: (Error) -> Void = { error in
            guard let error = error as? HackersKitError else { return }
            switch error {
            case .unauthenticated:
                self.present(
                    self.authenticationUIService!.unauthenticatedAlertController(),
                    animated: true
                )
            default:
                Loaf("Error connecting to Hacker News", state: .error, sender: self).show()
            }

            // revert to the previous post state
            voteOnComment(comment, !comment.upvoted)
        }

        let upvoted = comment.upvoted
        voteOnComment(comment, !comment.upvoted)
        if upvoted {
            HackersKit.shared
                .unvote(comment: comment, for: post)
                .catch(errorHandler)
        } else {
            HackersKit.shared
                .upvote(comment: comment, for: post)
                .catch(errorHandler)
        }
    }
}

// MARK: - SwipeTableViewCellDelegate
extension CommentsViewController: SwipeTableViewCellDelegate {
    func tableView(_ tableView: UITableView,
                   editActionsForRowAt indexPath: IndexPath,
                   for orientation: SwipeActionsOrientation) -> [SwipeAction]? {
        guard let post = self.post else { return nil }

        if !UserDefaults.standard.swipeActionsEnabled {
            return nil
        }

        switch (orientation, indexPath.section) {
        case (.left, 0):
            return swipeCellKitActions?.voteAction(
                post: post,
                tableView: tableView,
                indexPath: indexPath,
                viewController: self
            )

        case (.right, 1):
            return [collapseAction(), shareAction()]

        case (.left, 1):
            let comment = commentsController.visibleComments[indexPath.row]
            return swipeCellKitActions?.voteAction(
                comment: comment,
                post: post,
                tableView: tableView,
                indexPath: indexPath,
                viewController: self
            )

        default: return nil
        }
    }

    private func shareAction() -> SwipeAction {
        let shareAction = SwipeAction(style: .default, title: "Share") { [weak self] _, indexPath in
            self?.shareComment(at: indexPath)
        }
        shareAction.backgroundColor = .systemGreen
        shareAction.textColor = .white

        let iconImage = UIImage(systemName: "square.and.arrow.up")!.withTintColor(.white)
        shareAction.image = iconImage

        return shareAction
    }

    private func shareComment(at indexPath: IndexPath) {
        let comment = self.commentsController.visibleComments[indexPath.row]
        let url = comment.hackerNewsURL
        let activityViewController = UIActivityViewController(
            activityItems: [url],
            applicationActivities: nil
        )
        let cell = self.tableView.cellForRow(at: indexPath)
        activityViewController.popoverPresentationController?.sourceView = cell
        self.present(activityViewController, animated: true, completion: nil)
    }

    private func collapseAction() -> SwipeAction {
        let collapseAction = SwipeAction(style: .default, title: "Collapse") { _, indexPath in
            let comment = self.commentsController.visibleComments[indexPath.row]
            guard let index = self.commentsController.indexOfVisibleRootComment(of: comment) else { return }
            self.toggleCellVisibilityForCell(IndexPath(row: index, section: 1))
        }
        collapseAction.backgroundColor = AppTheme.default.appTintColor
        collapseAction.textColor = .white

        let iconImage = UIImage(named: "UpIcon")!.withTintColor(.white)
        collapseAction.image = iconImage

        return collapseAction
    }

    func tableView(_ tableView: UITableView,
                   editActionsOptionsForRowAt indexPath: IndexPath,
                   for orientation: SwipeActionsOrientation) -> SwipeOptions {
        let expansionStyle = SwipeExpansionStyle(target: .percentage(0.2),
                                                 elasticOverscroll: false,
                                                 completionAnimation: .bounce)
        var options = SwipeOptions()
        options.expansionStyle = expansionStyle
        options.expansionDelegate = BounceExpansion()
        options.transitionStyle = .drag
        return options
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == 0, indexPath.section == 0 {
            guard let url = post?.url else {
                return
            }
            openURL(url: url) {
                if let safariViewController = SFSafariViewController.instance(for: url) {
                    present(safariViewController, animated: true)
                }
            }
            setupHandoff(with: post, activityType: .link(url: url))
        }
    }
}

// MARK: - CommentDelegate
extension CommentsViewController: CommentDelegate {
    func commentTapped(_ sender: UITableViewCell) {
        if let indexPath = tableView.indexPath(for: sender) {
            toggleCellVisibilityForCell(indexPath)
        }
    }

    func linkTapped(_ url: URL, sender: UITextView) {
        openURL(url: url) {
            if let safariViewController = SFSafariViewController.instance(for: url) {
                present(safariViewController, animated: true)
            }
        }
        setupHandoff(with: post, activityType: .link(url: url))
    }

    func internalLinkTapped(postId: Int, url: URL, sender: UITextView) {
        navigationService?.showPost(id: postId)
    }

    private func toggleCellVisibilityForCell(_ indexPath: IndexPath!, scrollIfCellCovered: Bool = true) {
        guard commentsController.visibleComments.count > indexPath.row else { return }
        let comment = commentsController.visibleComments[indexPath.row]
        let (modifiedIndexPaths, visibility) = commentsController.toggleChildrenVisibility(of: comment)

        var scrollToCell = false
        let cellRectInTableView = tableView.rectForRow(at: indexPath)
        let cellRectInSuperview = tableView.convert(cellRectInTableView, to: tableView.superview)
        if cellRectInSuperview.origin.y < 0 {
            scrollToCell = true
        }

        tableView.beginUpdates()
        tableView.reloadRows(at: [indexPath], with: .fade)
        if visibility == CommentVisibilityType.hidden {
            tableView.deleteRows(at: modifiedIndexPaths, with: .fade)
        } else {
            tableView.insertRows(at: modifiedIndexPaths, with: .fade)
        }
        tableView.endUpdates()

        if scrollToCell && scrollIfCellCovered {
            tableView.scrollToRow(at: indexPath, at: .top, animated: true)
        }
    }
}

// MARK: - Handoff
extension CommentsViewController {

    private func setupCollectionView() {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(
            self,
            action: #selector(load),
            for: .valueChanged
        )
        self.refreshControl = refreshControl
    }

    private func setupHandoff(with post: Post?, activityType: ActivityType) {
        guard let post = post else {
            return
        }

        var activity: NSUserActivity?

        if case ActivityType.comments = activityType {
            activity = NSUserActivity(activityType: "com.weiranzhang.Hackers.comments")
            activity?.webpageURL = post.hackerNewsURL
        } else if case ActivityType.link(let webpageURL) = activityType {
            guard UIApplication.shared.canOpenURL(webpageURL) else {
                return
            }
            activity = NSUserActivity(activityType: "com.weiranzhang.Hackers.link")
            activity?.webpageURL = webpageURL
        }

        activity?.title = post.title
        userActivity = activity
        userActivity?.becomeCurrent()
    }

    private func tearDownHandoff() {
        userActivity?.invalidate()
    }
}
