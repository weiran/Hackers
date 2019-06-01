//
//  CommentsViewController.swift
//  Hackers2
//
//  Created by Weiran Zhang on 07/06/2014.
//  Copyright (c) 2014 Glass Umbrella. All rights reserved.
//

import Foundation
import UIKit
import SafariServices
import DZNEmptyDataSet
import HNScraper
import SwipeCellKit
import PromiseKit
import Loaf

class CommentsViewController: UITableViewController {
    public var hackerNewsService: HackerNewsService?
    public var authenticationUIService: AuthenticationUIService?

    private enum ActivityType {
        case comments
        case link(url: URL)
    }

    public var post: HNPost?

    private var comments: [CommentModel]? {
        didSet { commentsController.comments = comments! }
    }

    private let commentsController = CommentsController()

    @IBOutlet weak private var postTitleContainerView: UIView!
    @IBOutlet weak private var postTitleView: PostTitleView!
    @IBOutlet weak private var thumbnailImageView: UIImageView!
    @IBOutlet weak private var postTitleSeparatorView: UIView!

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTheming()
        setupPostTitleView()
        loadComments()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupHandoff(with: post, activityType: .comments)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        userActivity?.invalidate()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        if let headerView = tableView.tableHeaderView {
            let height = headerView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height
            var headerFrame = headerView.frame

            // If we don't have this check, viewDidLayoutSubviews() will get called infinitely
            if height != headerFrame.size.height {
                headerFrame.size.height = height
                headerView.frame = headerFrame
                tableView.tableHeaderView = headerView
            }
        }
    }

    private func loadComments() {
        firstly {
            self.hackerNewsService!.getComments(of: self.post!)
        }.done { comments in
            self.comments = comments?.map { CommentModel(source: $0) }
            self.tableView.reloadData()
        }.catch { error in
            Loaf("Error connecting to Hacker News", state: .error, sender: self).show()
            self.comments = []
            self.tableView.reloadData()
        }
    }

    override func updateUserActivityState(_ activity: NSUserActivity) {
        activity.addUserInfoEntries(from: [:])
        super.updateUserActivityState(activity)
    }

    private func setupPostTitleView() {
        guard let post = post else { return }

        postTitleView.post = post
        postTitleView.delegate = self
        postTitleView.isTitleTapEnabled = true
        thumbnailImageView.setImageWithPlaceholder(url: post.url, resizeToSize: 60)
    }

    @IBAction private func didTapThumbnail(_ sender: Any) {
        didPressLinkButton(post!)
    }

    @IBAction private func shareTapped(_ sender: AnyObject) {
        guard let post = post, let url = post.url else { return }
        let activityViewController = UIActivityViewController(activityItems: [post.title, url], applicationActivities: nil)
        activityViewController.popoverPresentationController?.barButtonItem = sender as? UIBarButtonItem
        present(activityViewController, animated: true, completion: nil)
    }
}

extension CommentsViewController: PostTitleViewDelegate {
    func didPressLinkButton(_ post: HNPost) {
        if verifyLink(post.url), let url = post.url {
            // animate background color for tap
            self.tableView.tableHeaderView?.backgroundColor = AppThemeProvider.shared.currentTheme.cellHighlightColor
            UIView.animate(withDuration: 0.3, animations: {
                self.tableView.tableHeaderView?.backgroundColor = AppThemeProvider.shared.currentTheme.backgroundColor
            })

            // show link
            let safariViewController = SFSafariViewController.instance(for: url)
            setupHandoff(with: post, activityType: .link(url: url))
            self.present(safariViewController, animated: true, completion: nil)
        }
    }

    private func verifyLink(_ url: URL?) -> Bool {
        guard let url = url else { return false }
        return UIApplication.shared.canOpenURL(url)
    }
}

extension CommentsViewController {
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return commentsController.visibleComments.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let comment = commentsController.visibleComments[indexPath.row]
        assert(comment.visibility != .hidden, "Cell cannot be hidden and in the array of visible cells")
        let cellIdentifier = comment.visibility == CommentVisibilityType.visible ? "OpenCommentCell" : "ClosedCommentCell"

        // swiftlint:disable force_cast
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as! CommentTableViewCell

        cell.updateCommentContent(with: comment, theme: themeProvider.currentTheme)
        cell.commentDelegate = self
        cell.delegate = self

        return cell
    }
}

extension CommentsViewController: SwipeTableViewCellDelegate {
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> [SwipeAction]? {
        switch orientation {
        case .right:
            let collapseAction = SwipeAction(style: .default, title: "Collapse") { _, indexPath in
                let comment = self.commentsController.visibleComments[indexPath.row]
                guard let index = self.commentsController.indexOfVisibleRootComment(of: comment) else { return }
                self.toggleCellVisibilityForCell(IndexPath(row: index, section: 0))
            }
            collapseAction.backgroundColor = themeProvider.currentTheme.appTintColor
            collapseAction.textColor = .white

            let iconImage = UIImage(named: "UpIcon")!.withTint(color: .white)
            collapseAction.image = iconImage

            return [collapseAction]

        case .left:
            guard let hackerNewsService = self.hackerNewsService else { return nil }
            let comment = self.commentsController.visibleComments[indexPath.row]

            let voteOnComment: (CommentModel, Bool) -> Void = { comment, isUpvote in
                guard let cell = tableView.cellForRow(at: indexPath) as? CommentTableViewCell else { return }
                comment.upvoted = isUpvote
                cell.updateCommentContent(with: comment, theme: self.themeProvider.currentTheme)
            }

            let errorHandler: (Error) -> Void = { error in
                guard let hnError = error as? HNScraper.HNScraperError else { return }
                switch hnError {
                case .notLoggedIn:
                    if let authenticationAlert = self.authenticationUIService?.unauthenticatedAlertController() {
                        self.present(authenticationAlert, animated: true)
                    }
                default:
                    Loaf("Error connecting to Hacker News", state: .error, sender: self).show()
                }

                // revert to the previous post state
                voteOnComment(comment, !comment.upvoted)
            }

            let voteAction = SwipeAction(style: .default, title: "Up") { _, _ in
                let upvoted = comment.upvoted
                voteOnComment(comment, !comment.upvoted)
                if upvoted {
                    hackerNewsService
                        .unvote(comment: comment.source)
                        .catch(errorHandler)
                } else {
                    hackerNewsService
                        .upvote(comment: comment.source)
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

    func tableView(_ tableView: UITableView, editActionsOptionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> SwipeOptions {
        let expansionStyle = SwipeExpansionStyle(target: .percentage(0.2), elasticOverscroll: true, completionAnimation: .bounce)
        var options = SwipeOptions()
        options.expansionStyle = expansionStyle
        options.transitionStyle = .drag
        return options
    }

    func visibleRect(for tableView: UITableView) -> CGRect? {
        return tableView.safeAreaLayoutGuide.layoutFrame
    }
}

extension CommentsViewController: Themed {
    func applyTheme(_ theme: AppTheme) {
        view.backgroundColor = theme.backgroundColor
        tableView.backgroundColor = theme.backgroundColor
        tableView.separatorColor = theme.separatorColor
        postTitleSeparatorView.backgroundColor = theme.separatorColor
        postTitleContainerView.backgroundColor = theme.backgroundColor
    }
}

extension CommentsViewController: CommentDelegate {
    func commentTapped(_ sender: UITableViewCell) {
        if let indexPath = tableView.indexPath(for: sender) {
            toggleCellVisibilityForCell(indexPath)
        }
    }

    func linkTapped(_ url: URL, sender: UITextView) {
        let safariViewController = SFSafariViewController.instance(for: url)
        setupHandoff(with: post, activityType: .link(url: url))
        self.present(safariViewController, animated: true, completion: nil)
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
            self.tableView.scrollToRow(at: indexPath, at: .top, animated: true)
        }
    }
}

extension CommentsViewController: DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {
    func title(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        let attributes = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 15.0)]
        return comments == nil ? NSAttributedString(string: "Loading comments", attributes: attributes) : NSAttributedString(string: "No comments", attributes: attributes)
    }

    func customView(forEmptyDataSet scrollView: UIScrollView!) -> UIView? {
        guard comments == nil else { return nil }
        let activityIndicatorView = UIActivityIndicatorView(style: self.themeProvider.currentTheme.activityIndicatorStyle)
        activityIndicatorView.startAnimating()
        return activityIndicatorView
    }
}

// MARK: - Handoff
extension CommentsViewController {
    private func setupHandoff(with post: HNPost?, activityType: ActivityType) {
        guard let post = post else {
            return
        }
        var activity: NSUserActivity?

        if case ActivityType.comments = activityType {
            activity = NSUserActivity(activityType: "com.weiranzhang.Hackers.comments")
            guard let webpageURL = URL(string: "https://news.ycombinator.com/item?id=" + post.id) else {
                return
            }
            activity?.webpageURL = webpageURL
        } else if case ActivityType.link(let webpageURL) = activityType {
            activity = NSUserActivity(activityType: "com.weiranzhang.Hackers.link")
            activity?.webpageURL = webpageURL
        }

        activity?.title = post.title + " | Hacker News"
        userActivity = activity
        userActivity?.becomeCurrent()
    }
}
