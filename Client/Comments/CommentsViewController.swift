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
import SkeletonView
import HNScraper
import SwipeCellKit
import PromiseKit
import Loaf

class CommentsViewController : UIViewController {
    public var hackerNewsService: HackerNewsService?
    
    private enum ActivityType {
        case comments
        case link(url: URL)
    }

    var post: HNPost?
    
    var comments: [CommentModel]? {
        didSet { commentsController.comments = comments! }
    }
    
    let commentsController = CommentsController()
    
    @IBOutlet var tableView: UITableView!
    
    @IBOutlet weak var postTitleContainerView: UIView!
    @IBOutlet weak var postTitleView: PostTitleView!
    @IBOutlet weak var thumbnailImageView: UIImageView!
    
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
    
    override func awakeFromNib() {
        super.awakeFromNib()
        navigationItem.largeTitleDisplayMode = .never
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
    
    func loadComments() {
        self.view.showAnimatedGradientSkeleton(usingGradient: SkeletonGradient(baseColor: AppThemeProvider.shared.currentTheme.skeletonColor))
        firstly {
            self.hackerNewsService!.getComments(of: self.post!)
        }.done { comments in
            self.comments = comments?.map { CommentModel(source: $0) }
            self.tableView.reloadData()
        }.ensure {
            self.view.hideSkeleton()
        }.catch { error in
            Loaf("Error connecting to Hacker News", state: .error, sender: self).show()
        }
    }

    override func updateUserActivityState(_ activity: NSUserActivity) {
        activity.addUserInfoEntries(from: [:])
        super.updateUserActivityState(activity)
    }
    
    func setupPostTitleView() {
        guard let post = post else { return }
        
        postTitleView.post = post
        postTitleView.delegate = self
        postTitleView.isTitleTapEnabled = true
        thumbnailImageView.setImageWithPlaceholder(url: post.url, resizeToSize: 60)
    }
    
    @IBAction func didTapThumbnail(_ sender: Any) {
        didPressLinkButton(post!)
    }
    
    @IBAction func shareTapped(_ sender: AnyObject) {
        guard let post = post, let url = post.url else { return }
        let activityViewController = UIActivityViewController(activityItems: [post.title, url], applicationActivities: nil)
        activityViewController.popoverPresentationController?.barButtonItem = sender as? UIBarButtonItem
        present(activityViewController, animated: true, completion: nil)
    }
}

extension CommentsViewController: PostTitleViewDelegate {
    func didPressLinkButton(_ post: HNPost) {
        if verifyLink(post.url), let url = post.url {
            // animate background colour for tap
            self.tableView.tableHeaderView?.backgroundColor = AppThemeProvider.shared.currentTheme.cellHighlightColor
            UIView.animate(withDuration: 0.3, animations: {
                self.tableView.tableHeaderView?.backgroundColor = AppThemeProvider.shared.currentTheme.backgroundColor
            })
            
            // show link
            let safariViewController = ThemedSafariViewController(url: url)
            setupHandoff(with: post, activityType: .link(url: url))
            self.present(safariViewController, animated: true, completion: nil)
        }
    }
    
    func verifyLink(_ url: URL?) -> Bool {
        guard let url = url else { return false }
        return UIApplication.shared.canOpenURL(url)
    }
}

extension CommentsViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return commentsController.visibleComments.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let comment = commentsController.visibleComments[indexPath.row]
        assert(comment.visibility != .hidden, "Cell cannot be hidden and in the array of visible cells")
        let cellIdentifier = comment.visibility == CommentVisibilityType.visible ? "OpenCommentCell" : "ClosedCommentCell"
        
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as! CommentTableViewCell
        
        cell.updateCommentContent(with: comment)
        cell.commentDelegate = self
        cell.delegate = self
        
        return cell
    }
}

extension CommentsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = Bundle.main.loadNibNamed("CommentsHeader", owner: nil, options: nil)?.first as? UIView
        return view
    }
}

extension CommentsViewController: SwipeTableViewCellDelegate {
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> [SwipeAction]? {
        guard orientation == .right else { return nil }
        
        let collapseAction = SwipeAction(style: .default, title: "Collapse") { action, indexPath in
            let comment = self.commentsController.visibleComments[indexPath.row]
            guard let index = self.commentsController.indexOfVisibleRootComment(of: comment) else { return }
            self.toggleCellVisibilityForCell(IndexPath(row: index, section: 0))
        }
        collapseAction.backgroundColor = themeProvider.currentTheme.appTintColor
        collapseAction.textColor = .white
        
        let iconImage = UIImage(named: "UpIcon")!.imageWithColor(color: .white)
        collapseAction.image = iconImage
        
        return [collapseAction]
    }
    
    func tableView(_ tableView: UITableView, editActionsOptionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> SwipeOptions {
        let expansionStyle = SwipeExpansionStyle(target: .percentage(0.2),
                                                 elasticOverscroll: true,
                                                 completionAnimation: .bounce)
        
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
        postTitleContainerView.backgroundColor = theme.backgroundColor
    }
}

extension CommentsViewController: CommentDelegate {
    func commentTapped(_ sender: UITableViewCell) {
        if let indexPath = tableView.indexPath(for: sender) {
            toggleCellVisibilityForCell(indexPath)
        }
    }
    
    func linkTapped(_ URL: Foundation.URL, sender: UITextView) {
        let safariViewController = ThemedSafariViewController(url: URL)
        setupHandoff(with: post, activityType: .link(url: URL))
        self.present(safariViewController, animated: true, completion: nil)
    }
    
    func toggleCellVisibilityForCell(_ indexPath: IndexPath!, scrollIfCellCovered: Bool = true) {
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
}

extension CommentsViewController: SkeletonTableViewDataSource {
    func collectionSkeletonView(_ skeletonView: UITableView, cellIdentifierForRowAt indexPath: IndexPath) -> ReusableCellIdentifier {
        return "SkeletonCell"
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
