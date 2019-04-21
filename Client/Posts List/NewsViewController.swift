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
import SkeletonView
import Kingfisher
import HNScraper
import Loaf

class NewsViewController : UIViewController {
    public var hackerNewsService: HackerNewsService?
    
    @IBOutlet weak var tableView: UITableView!
    private var refreshControl: UIRefreshControl!
    
    var posts: [HNPost] = [HNPost]()
    var postType: HNScraper.PostListPageName! = .news
    
    private var peekedIndexPath: IndexPath?
    private var nextPageIdentifier: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        registerForPreviewing(with: self, sourceView: tableView)

        refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(NewsViewController.loadPosts), for: UIControl.Event.valueChanged)
        tableView.refreshControl = refreshControl
        
        setupTheming()
        
        view.showAnimatedGradientSkeleton(usingGradient: SkeletonGradient(baseColor: AppThemeProvider.shared.currentTheme.skeletonColor))
        loadPosts()
        
//        HNLogin.shared.login(username: "weiran", psw: "bardev") { (user, cookie, error) in
//            print(user)
//            print(cookie)
//        }
    }
    
    @IBAction func changeTheme(_ sender: Any) {
        AppThemeProvider.shared.nextTheme()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // when the cell is still visible, no need to deselect it
        if UIScreen.main.traitCollection.horizontalSizeClass == .compact {
            rz_smoothlyDeselectRows(tableView: tableView)
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        DispatchQueue.global().async(execute: {
            DispatchQueue.main.sync {
                self.viewDidRotate()
            }
        })
    }

    func getSafariViewController(_ url: URL) -> SFSafariViewController {
        let safariViewController = ThemedSafariViewController(url: url)
        safariViewController.previewActionItemsDelegate = self
        return safariViewController
    }
    
    public func viewDidRotate() {
        guard let tableView = self.tableView, let indexPaths = tableView.indexPathsForVisibleRows else { return }
        self.tableView.beginUpdates()
        self.tableView.reloadRows(at: indexPaths, with: .automatic)
        self.tableView.endUpdates()
    }
}

extension NewsViewController { // post fetching
    @objc func loadPosts() {
        hackerNewsService?.getPosts(of: self.postType).map { (posts, nextPageIdentifier) in
            self.posts = posts ?? [HNPost]()
            self.nextPageIdentifier = nextPageIdentifier
            
            self.tableView.rowHeight = UITableView.automaticDimension
            self.tableView.estimatedRowHeight = UITableView.automaticDimension
            self.tableView.reloadData()
        }.ensure {
            self.view.hideSkeleton()
            self.tableView.refreshControl?.endRefreshing()
        }.catch { _ in
            Loaf("Error connecting to Hacker News", state: .error, sender: self).show()
        }
    }
    
    func loadMorePosts() {
        guard let nextPageIdentifier = nextPageIdentifier else { return }
        self.nextPageIdentifier = nil
        
        firstly {
            hackerNewsService!.getPosts(of: self.postType, nextPageIdentifier: nextPageIdentifier)
        }.done { (posts, nextPageIdentifier) in
            if let posts = posts {
                self.posts.append(contentsOf: posts)
            }
            self.nextPageIdentifier = nextPageIdentifier
            self.tableView.reloadData()
        }.catch { error in
            Loaf("Error connecting to Hacker News", state: .error, sender: self).show()
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowComments" {
            if let indexPath = tableView.indexPathForSelectedRow,
                let segueNavigationController = segue.destination as? UINavigationController,
                let commentsViewController = segueNavigationController.topViewController as? CommentsViewController {
        
                let post = posts[indexPath.row]
                commentsViewController.post = post
            }
        }
    }
}

extension NewsViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return posts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PostCell", for: indexPath) as! PostCell
        cell.delegate = self
        cell.clearImage()
        
        let post = posts[indexPath.row]
        cell.postTitleView.post = post
        cell.postTitleView.delegate = self
        cell.thumbnailImageView.setImageWithPlaceholder(url: post.url, resizeToSize: 60)
        
        return cell
    }
}

extension NewsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.row == posts.count - 5 {
            loadMorePosts()
        }
    }
}

extension NewsViewController: Themed {
    func applyTheme(_ theme: AppTheme) {
        view.backgroundColor = theme.backgroundColor
        tableView.backgroundColor = theme.backgroundColor
        tableView.separatorColor = theme.separatorColor
        refreshControl.tintColor = theme.appTintColor
    }
}

extension NewsViewController: SkeletonTableViewDataSource {
    func collectionSkeletonView(_ skeletonView: UITableView, cellIdentifierForRowAt indexPath: IndexPath) -> ReusableCellIdentifier {
        return "SkeletonCell"
    }
}

extension NewsViewController: UIViewControllerPreviewingDelegate, SFSafariViewControllerPreviewActionItemsDelegate {
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        guard let indexPath = tableView.indexPathForRow(at: location), posts.count > indexPath.row else { return nil }
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
        let indexPath = self.peekedIndexPath!
        let post = posts[indexPath.row]
        let commentsPreviewActionTitle = post.commentCount > 0 ? "View \(post.commentCount) comments" : "View comments"
        
        let viewCommentsPreviewAction = UIPreviewAction(title: commentsPreviewActionTitle, style: .default) {
            [unowned self, indexPath = indexPath] (action, viewController) -> Void in
            self.tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
            self.performSegue(withIdentifier: "ShowComments", sender: nil)
        }
        return [viewCommentsPreviewAction]
    }
}

extension NewsViewController: PostTitleViewDelegate {
    func didPressLinkButton(_ post: HNPost) {
        guard verifyLink(post.url), let url = post.url else { return }
        self.navigationController?.present(getSafariViewController(url), animated: true, completion: nil)
    }
    
    func verifyLink(_ url: URL?) -> Bool {
        guard let url = url else { return false }
        return UIApplication.shared.canOpenURL(url)
    }
}

extension NewsViewController: PostCellDelegate {
    func didTapThumbnail(_ sender: Any) {
        guard let tapGestureRecognizer = sender as? UITapGestureRecognizer else { return }
        let point = tapGestureRecognizer.location(in: tableView)
        if let indexPath = tableView.indexPathForRow(at: point) {
            let post = posts[indexPath.row]
            didPressLinkButton(post)
        }
    }
}
