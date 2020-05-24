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
import HNScraper
import SwipeCellKit
import PromiseKit
import Loaf

class CommentsViewController: UITableViewController {
    public var hackerNewsService: HackerNewsService?
    public var authenticationUIService: AuthenticationUIService?
    public var swipeCellKitActions: SwipeCellKitActions?

    private enum ActivityType {
        case comments
        case link(url: URL)
    }

    public var post: HackerNewsPost?
    private let commentsController = CommentsController()

    private var comments: [HackerNewsComment]? {
        didSet { commentsController.comments = comments! }
    }

    @IBOutlet var loadingView: UIView!
    private var notificationToken: NotificationToken?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTheming()
        loadComments()
        tableView.backgroundView = TableViewBackgroundView.loadingBackgroundView()
        notificationToken = NotificationCenter.default
            .observe(name: AuthenticationUIService.Notifications.AuthenticationDidChangeNotification,
                     object: nil, queue: .main) { _ in self.loadComments() }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupHandoff(with: post, activityType: .comments)
    }

    deinit {
        userActivity?.invalidate()
    }

    private func loadComments() {
//        firstly {
//            hackerNewsService!.getComments(of: post!)
//        }.done { comments in
//            switch comments?.count {
//            case 0: self.tableView.backgroundView = TableViewBackgroundView.emptyBackgroundView(message: "No comments")
//            default:
//                self.tableView.backgroundView = nil
//                self.comments = comments
//                self.tableView.reloadData()
//            }
//        }.catch { error in
//            Loaf("Error connecting to Hacker News", state: .error, sender: self).show()
//            self.tableView.backgroundView = nil
//        }

        firstly {
            HackerNewsData.shared.getComments(postId: post!.id)
        }.done { result in
            print(result)
        }.catch { error in
            print(error)
        }

//        firstly {
//            HackerNewsData.shared.getPost(postId: post!.id)
//        }.done { post in
//            if let children = post.children {
//                let comments = children.compactMap { child in
//                    return HackerNewsComment(child)
//                }
//                func traverse(_ comments: [HackerNewsComment]?) -> [HackerNewsComment] {
//                    let comments = comments ?? []
//                    return comments + comments.flatMap { traverse($0.children) }
//                }
//                let flatComments = traverse(comments)
//                self.comments = flatComments
//                self.tableView.reloadData()
//            }
//        }.catch { error in
//
//        }
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
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return 1
        default: return commentsController.visibleComments.count
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            // swiftlint:disable force_cast
            let cell = tableView.dequeueReusableCell(withIdentifier: "PostCell", for: indexPath) as! PostCell

            cell.delegate = self
            cell.postTitleView.post = post
            cell.setImageWithPlaceholder(url: post?.url)
            cell.thumbnailImageView.isUserInteractionEnabled = false

            return cell
        default:
            let comment = commentsController.visibleComments[indexPath.row]
            assert(comment.visibility != .hidden, "Cell cannot be hidden and in the array of visible cells")
            let cellIdentifier = comment.visibility == CommentVisibilityType.visible ?
                "OpenCommentCell" : "ClosedCommentCell"

            // swiftlint:disable force_cast
            let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier,
                                                     for: indexPath) as! CommentTableViewCell

            cell.updateCommentContent(with: comment, theme: themeProvider.currentTheme)
            cell.commentDelegate = self
            cell.delegate = self

            return cell
        }
    }
}

extension CommentsViewController: SwipeTableViewCellDelegate {
    func tableView(_ tableView: UITableView,
                   editActionsForRowAt indexPath: IndexPath,
                   for orientation: SwipeActionsOrientation) -> [SwipeAction]? {
        switch (orientation, indexPath.section) {
        case (.left, 0):
            return swipeCellKitActions?.voteAction(post: post!, tableView: tableView,
                                                   indexPath: indexPath, viewController: self)

        case (.right, 1):
            return collapseAction()

        case (.left, 1):
            let comment = commentsController.visibleComments[indexPath.row]
            return swipeCellKitActions?.voteAction(comment: comment, tableView: tableView,
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

        let iconImage = UIImage(named: "UpIcon")!.withTint(color: .white)
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
    private func setupHandoff(with post: HackerNewsPost?, activityType: ActivityType) {
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
}

protocol AnyArray { }
extension Array: AnyArray {
    func recursiveFlatMap<T>(_ array: [AnyObject]) -> [T] {
        var result: [T] = []
        array.forEach {
            if $0 is AnyArray {
                let flatArray: [AnyObject] = $0 as! [AnyObject]
                result += recursiveFlatMap(flatArray)
            } else {
                result.append($0 as! T)
            }
        }
        return result
    }
}
