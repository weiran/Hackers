//
//  CommentsViewController.swift
//  Hackers2
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
        setupTheming()

        load()
    }

    deinit {
        tearDownHandoff()
    }

    private func load(showSpinner: Bool = true) {
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
            .observe(name: AuthenticationUIService.Notifications.AuthenticationDidChangeNotification,
                     object: nil, queue: .main) { _ in self.load(showSpinner: false) }
    }

    override func updateUserActivityState(_ activity: NSUserActivity) {
        activity.addUserInfoEntries(from: [:])
        super.updateUserActivityState(activity)
    }

    @IBAction private func shareTapped(_ sender: AnyObject) {
        guard let post = post else {
            return
        }

        let activityViewController = UIActivityViewController(activityItems: [post.url],
                                                              applicationActivities: nil)
        activityViewController.popoverPresentationController?.barButtonItem = sender as? UIBarButtonItem
        present(activityViewController, animated: true, completion: nil)
    }
}

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

        cell.updateCommentContent(with: comment, theme: themeProvider.currentTheme)
        cell.commentDelegate = self
        cell.delegate = self

        return cell
    }
    // swiftlint:enable force_cast
}

extension CommentsViewController: SwipeTableViewCellDelegate {
    func tableView(_ tableView: UITableView,
                   editActionsForRowAt indexPath: IndexPath,
                   for orientation: SwipeActionsOrientation) -> [SwipeAction]? {
        guard let post = self.post else { return nil }
        switch (orientation, indexPath.section) {
        case (.left, 0):
            return swipeCellKitActions?.voteAction(post: post, tableView: tableView,
                                                   indexPath: indexPath, viewController: self)

        case (.right, 1):
            return collapseAction()

        case (.left, 1):
            let comment = commentsController.visibleComments[indexPath.row]
            return swipeCellKitActions?.voteAction(comment: comment, post: post, tableView: tableView,
                                                   indexPath: indexPath, viewController: self)

        default: return nil
        }
    }

    private func collapseAction() -> [SwipeAction] {
        let collapseAction = SwipeAction(style: .default, title: "Collapse") { _, indexPath in
            let comment = self.commentsController.visibleComments[indexPath.row]
            guard let index = self.commentsController.indexOfVisibleRootComment(of: comment) else { return }
            self.toggleCellVisibilityForCell(IndexPath(row: index, section: 1))
        }
        collapseAction.backgroundColor = themeProvider.currentTheme.appTintColor
        collapseAction.textColor = .white

        let iconImage = UIImage(named: "UpIcon")!.withTintColor(.white)
        collapseAction.image = iconImage

        return [collapseAction]
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
            guard let url = post?.url,
                UIApplication.shared.canOpenURL(url),
                let safariViewController = SFSafariViewController.instance(for: url) else {
                    return
            }
            setupHandoff(with: post, activityType: .link(url: url))
            present(safariViewController, animated: true, completion: nil)
        }
    }
}

extension CommentsViewController: Themed {
    func applyTheme(_ theme: AppTheme) {
        view.backgroundColor = theme.backgroundColor
        tableView.separatorColor = theme.separatorColor
        overrideUserInterfaceStyle = theme.userInterfaceStyle
    }
}

extension CommentsViewController: CommentDelegate {
    func commentTapped(_ sender: UITableViewCell) {
        if let indexPath = tableView.indexPath(for: sender) {
            toggleCellVisibilityForCell(indexPath)
        }
    }

    func linkTapped(_ url: URL, sender: UITextView) {
        if let safariViewController = SFSafariViewController.instance(for: url) {
            setupHandoff(with: post, activityType: .link(url: url))
            present(safariViewController, animated: true)
        }
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
    private func setupHandoff(with post: Post?, activityType: ActivityType) {
        guard let post = post else {
            return
        }

        var activity: NSUserActivity?

        if case ActivityType.comments = activityType {
            activity = NSUserActivity(activityType: "com.weiranzhang.Hackers.comments")
            activity?.webpageURL = post.hackerNewsURL
        } else if case ActivityType.link(let webpageURL) = activityType {
            activity = NSUserActivity(activityType: "com.weiranzhang.Hackers.link")
            activity?.webpageURL = webpageURL
        }

        activity?.title = post.title + " | Hacker News"
        userActivity = activity
        userActivity?.becomeCurrent()
    }

    private func tearDownHandoff() {
        userActivity?.invalidate()
    }
}
