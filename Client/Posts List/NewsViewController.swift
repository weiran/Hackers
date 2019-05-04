//
//  NewsViewController.swift
//  Hackers2
//
//  Created by Weiran Zhang on 07/06/2014.
//  Copyright (c) 2014 Glass Umbrella. All rights reserved.
//

import Foundation
import UIKit
import SafariServices
import PromiseKit
import Kingfisher
import HNScraper
import Loaf
import SwipeCellKit

class NewsViewController : UITableViewController {
    public var hackerNewsService: HackerNewsService?
    
    private var posts: [HNPost]?
    public var postType: HNScraper.PostListPageName! = .news
    
    private var peekedIndexPath: IndexPath?
    private var nextPageIdentifier: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        registerForPreviewing(with: self, sourceView: tableView)
        self.tableView.refreshControl?.addTarget(self, action: #selector(loadPosts), for: UIControl.Event.valueChanged)
        self.tableView.tableFooterView = UIView(frame: .zero) // remove cell separators on empty table
        setupTheming()
        loadPosts()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // when the cell is still visible, no need to deselect it
        if UIScreen.main.traitCollection.horizontalSizeClass == .compact {
            self.smoothlyDeselectRows()
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowComments" {
            if let indexPath = tableView.indexPathForSelectedRow,
                let segueNavigationController = segue.destination as? UINavigationController,
                let commentsViewController = segueNavigationController.topViewController as? CommentsViewController {
                let post = posts?[indexPath.row]
                commentsViewController.post = post
            }
        }
    }
}

extension NewsViewController { // post fetching
    @objc private func loadPosts() {
        hackerNewsService?.getPosts(of: self.postType).map { (posts, nextPageIdentifier) in
            self.posts = posts
            self.nextPageIdentifier = nextPageIdentifier
            self.tableView.reloadData()
        }.ensure {
            self.tableView.refreshControl?.endRefreshing()
        }.catch { _ in
            Loaf("Error connecting to Hacker News", state: .error, sender: self).show()
            // show empty data state by having an empty array rather than nil
            if self.posts == nil {
                self.posts = []
            }
            self.tableView.reloadData()
        }
    }
    
    private func loadMorePosts() {
        guard let nextPageIdentifier = nextPageIdentifier else { return }
        self.nextPageIdentifier = nil
        
        firstly {
            hackerNewsService!.getPosts(of: self.postType, nextPageIdentifier: nextPageIdentifier)
        }.done { (posts, nextPageIdentifier) in
            self.posts?.append(contentsOf: posts)
            self.nextPageIdentifier = nextPageIdentifier
            self.tableView.reloadData()
        }.catch { error in
            Loaf("Error connecting to Hacker News", state: .error, sender: self).show()
        }
    }
}

extension NewsViewController {
    override open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return posts?.count ?? 0
    }
    
    override open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PostCell", for: indexPath) as! PostCell
        cell.postDelegate = self
        cell.delegate = self
        cell.clearImage()
        
        let post = posts?[indexPath.row]
        cell.postTitleView.post = post
        cell.postTitleView.delegate = self
        cell.thumbnailImageView.setImageWithPlaceholder(url: post?.url, resizeToSize: 60)
        
        return cell
    }
    
    override open func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let posts = posts, indexPath.row == posts.count - 5 {
            loadMorePosts()
        }
    }
}

extension NewsViewController: SwipeTableViewCellDelegate {
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> [SwipeAction]? {
        guard orientation == .left else { return nil }
        
        let upvoteAction = SwipeAction(style: .default, title: "Up") { action, indexPath in
            guard let post = self.posts?[indexPath.row] else { return }
            if post.upvoted {
                _ = self.hackerNewsService?.unvote(post: post)
                post.upvoted = false
                post.points -= 1
            } else {
                _ = self.hackerNewsService?.upvote(post: post)
                post.upvoted = true
                post.points += 1
            }
            guard let cell = tableView.cellForRow(at: indexPath) as? PostCell else { return }
            cell.postTitleView.post = post
        }
        upvoteAction.backgroundColor = themeProvider.currentTheme.upvotedColor
        upvoteAction.textColor = .white
        
        let iconImage = UIImage(named: "PointsIcon")!.withTint(color: .white)
        upvoteAction.image = iconImage
        
        return [upvoteAction]
    }
    
    func tableView(_ tableView: UITableView, editActionsOptionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> SwipeOptions {
        let expansionStyle = SwipeExpansionStyle(target: .percentage(0.2), elasticOverscroll: true, completionAnimation: .bounce)
        var options = SwipeOptions()
        options.expansionStyle = expansionStyle
        options.transitionStyle = .drag
        return options
    }
}

extension NewsViewController: Themed {
    func applyTheme(_ theme: AppTheme) {
        self.view.backgroundColor = theme.backgroundColor
        self.tableView.backgroundColor = theme.backgroundColor
        self.tableView.separatorColor = theme.separatorColor
        self.tableView.refreshControl?.tintColor = theme.appTintColor
    }
}

extension NewsViewController: UIViewControllerPreviewingDelegate, SFSafariViewControllerPreviewActionItemsDelegate {
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        guard let posts = posts,
            let indexPath = tableView.indexPathForRow(at: location),
            posts.count > indexPath.row else {
                return nil
        }
        let post = posts[indexPath.row]
        if let url = post.url, verifyLink(post.url) {
            peekedIndexPath = indexPath
            previewingContext.sourceRect = tableView.rectForRow(at: indexPath)
            return getSafariViewController(url)
        }
        return nil
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        present(viewControllerToCommit, animated: true, completion: nil)
    }
    
    func safariViewControllerPreviewActionItems(_ controller: SFSafariViewController) -> [UIPreviewActionItem] {
        guard let indexPath = self.peekedIndexPath, let post = posts?[indexPath.row] else {
            return [UIPreviewActionItem]()
        }
        
        let commentsPreviewActionTitle = post.commentCount > 0 ? "View \(post.commentCount) comments" : "View comments"
        
        let viewCommentsPreviewAction = UIPreviewAction(title: commentsPreviewActionTitle, style: .default) {
            [unowned self, indexPath = indexPath] (action, viewController) -> Void in
            self.tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
            self.performSegue(withIdentifier: "ShowComments", sender: nil)
        }
        return [viewCommentsPreviewAction]
    }
    
    private func getSafariViewController(_ url: URL) -> SFSafariViewController {
        let safariViewController = SFSafariViewController(url: url)
        safariViewController.previewActionItemsDelegate = self
        return safariViewController
    }
}

extension NewsViewController: PostTitleViewDelegate, PostCellDelegate {
    func didPressLinkButton(_ post: HNPost) {
        guard verifyLink(post.url), let url = post.url else { return }
        self.navigationController?.present(getSafariViewController(url), animated: true, completion: nil)
    }
    
    private func verifyLink(_ url: URL?) -> Bool {
        guard let url = url else { return false }
        return UIApplication.shared.canOpenURL(url)
    }
    
    func didTapThumbnail(_ sender: Any) {
        guard let tapGestureRecognizer = sender as? UITapGestureRecognizer else { return }
        let point = tapGestureRecognizer.location(in: tableView)
        if let indexPath = tableView.indexPathForRow(at: point), let post = posts?[indexPath.row] {
            didPressLinkButton(post)
        }
    }
}

extension NewsViewController: DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {
    func title(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        let attributes = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 15.0)]
        return posts == nil ? NSAttributedString(string: "Loading", attributes: attributes) : NSAttributedString(string: "No posts", attributes: attributes)
    }
    
    func customView(forEmptyDataSet scrollView: UIScrollView!) -> UIView? {
        guard posts == nil else { return nil }
        let activityIndicatorView = UIActivityIndicatorView(style: self.themeProvider.currentTheme.activityIndicatorStyle)
        activityIndicatorView.startAnimating()
        return activityIndicatorView
    }
    
    func emptyDataSetShouldAllowScroll(_ scrollView: UIScrollView!) -> Bool {
        return posts != nil // only when empty data
    }
}
