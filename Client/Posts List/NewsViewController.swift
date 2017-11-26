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
import libHN
import DZNEmptyDataSet
import PromiseKit
import SkeletonView
import SVProgressHUD

class NewsViewController : UIViewController {
    @IBOutlet weak var tableView: UITableView!
    
    var posts: [HNPost] = [HNPost]()
    var postType: PostFilterType! = .top
    
    private var collapseDetailViewController = true
    private var peekedIndexPath: IndexPath?
    private var thumbnailProcessedUrls = [String]()
    private var nextPageIdentifier: String?
    private var isProcessing: Bool = false
    
    private var cancelFetch: (() -> Void)?
    private var cancelThumbnailFetchTasks = [() -> Void]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        registerForPreviewing(with: self, sourceView: tableView)

        let refreshControl = UIRefreshControl()
        refreshControl.tintColor = Theme.purpleColour
        refreshControl.addTarget(self, action: #selector(NewsViewController.loadPosts), for: UIControlEvents.valueChanged)
        tableView.refreshControl = refreshControl
        
        splitViewController!.delegate = self
        
        view.showAnimatedSkeleton()
        loadPosts()
    }
    
    override func awakeFromNib() {
        /*
         TODO: workaround for an iOS 11 bug: if prefersLargeTitles is set in storyboard,
         it never shrinks with scroll. When fixed, remove from code and set in storyboard.
        */
        navigationController?.navigationBar.prefersLargeTitles = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        navigationItem.largeTitleDisplayMode = .always
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        rz_smoothlyDeselectRows(tableView: tableView)
    }

    func getSafariViewController(_ url: URL) -> SFSafariViewController {
        let safariViewController = SFSafariViewController(url: url)
        safariViewController.previewActionItemsDelegate = self
        return safariViewController
    }
}

extension NewsViewController { // post fetching
    @objc func loadPosts() {
        isProcessing = true
        
        // cancel existing fetches
        if let cancelFetch = cancelFetch {
            cancelFetch()
            self.cancelFetch = nil
        }
        
        // cancel existing thumbnail fetches
        cancelThumbnailFetchTasks.forEach { cancel in
            cancel()
        }
        cancelThumbnailFetchTasks = [() -> Void]()
        
        // fetch new posts
        let (fetchPromise, cancel) = fetch()
        fetchPromise
            .then { (posts, nextPageIdentifier) -> Void in
                self.posts = posts ?? [HNPost]()
                self.nextPageIdentifier = nextPageIdentifier
                self.view.hideSkeleton()
                self.tableView.rowHeight = UITableViewAutomaticDimension
                self.tableView.estimatedRowHeight = UITableViewAutomaticDimension
                self.tableView.reloadData()
            }
            .catch { error in
                self.view.hideSkeleton()
                SVProgressHUD.showError(withStatus: "Failed")
                SVProgressHUD.dismiss(withDelay: 1.0)
            }
            .always {
                self.isProcessing = false
                self.tableView.refreshControl?.endRefreshing()
        }
        
        cancelFetch = cancel
    }
    
    func fetch() -> (Promise<([HNPost]?, String?)>, cancel: () -> Void) {
        var cancelMe = false
        var cancel: () -> Void = { }
        
        let promise = Promise<([HNPost]?, String?)> { fulfill, reject in
            cancel = {
                cancelMe = true
                reject(NSError.cancelledError())
            }
            HNManager.shared().loadPosts(with: postType) { posts, nextPageIdentifier in
                guard !cancelMe else {
                    reject(NSError.cancelledError())
                    return
                }
                if let posts = posts as? [HNPost] {
                    fulfill((posts, nextPageIdentifier))
                }
            }
        }
        
        return (promise, cancel)
    }
    
    func loadMorePosts() {
        guard let nextPageIdentifier = nextPageIdentifier else { return }
        self.nextPageIdentifier = nil
        HNManager.shared().loadPosts(withUrlAddition: nextPageIdentifier) { posts, nextPageIdentifier in
            if let downcastedArray = posts as? [HNPost] {
                self.nextPageIdentifier = nextPageIdentifier
                self.posts.append(contentsOf: downcastedArray)
                self.tableView.reloadData()
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
        
        if let url = URL(string: post.urlString) {
            if let image = ThumbnailFetcher.getThumbnailFromCache(url: url) {
                cell.setImage(image: image)
            } else if !thumbnailProcessedUrls.contains(url.absoluteString) {
                let (promise, cancel) = ThumbnailFetcher.getThumbnail(url: url)
                cell.cancelThumbnailTask = cancel
                _ = promise.then(on: DispatchQueue.main) { image -> Void in
                    guard let _ = image else { return }
                    self.thumbnailProcessedUrls.append(url.absoluteString)
                    DispatchQueue.main.async {
                        self.tableView.beginUpdates()
                        self.tableView.reloadRows(at: [indexPath], with: .fade)
                        self.tableView.endUpdates()
                    }
                }
                cancelThumbnailFetchTasks.append(cancel)
            }
        }
        
        return cell
    }
}

extension NewsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        collapseDetailViewController = false
        
        guard let navController = storyboard?.instantiateViewController(withIdentifier: "PostViewNavigationController") as? UINavigationController else { return }
        guard let commentsViewController = navController.viewControllers.first as? CommentsViewController else { return }
        commentsViewController.post = posts[indexPath.row]
        
        if UIDevice.current.userInterfaceIdiom == .phone {
            // for iPhone we want to push the view controller instead of presenting it as the detail
            self.navigationController?.pushViewController(commentsViewController, animated: true)
        } else {
            showDetailViewController(navController, sender: self)
        }
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.row == posts.count - 5 {
            loadMorePosts()
        }
    }
    
    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let cell = cell as? PostCell {
            cell.cancelThumbnailTask?()
        }
    }
}

extension NewsViewController: SkeletonTableViewDataSource {
    func collectionSkeletonView(_ skeletonView: UITableView, cellIdenfierForRowAt indexPath: IndexPath) -> ReusableCellIdentifier {
        return "SkeletonCell"
    }
}

extension NewsViewController: UIViewControllerPreviewingDelegate, SFSafariViewControllerPreviewActionItemsDelegate {
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        guard let indexPath = tableView.indexPathForRow(at: location) else { return nil }
        let post = posts[indexPath.row]
        if let url = URL(string: post.urlString), verifyLink(post.urlString) {
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
            self.tableView(self.tableView, didSelectRowAt: indexPath)
        }
        return [viewCommentsPreviewAction]
    }
}

extension NewsViewController: UISplitViewControllerDelegate {
    func splitViewController(_ splitViewController: UISplitViewController, collapseSecondary secondaryViewController: UIViewController, onto primaryViewController: UIViewController) -> Bool {
        return collapseDetailViewController
    }
}

extension NewsViewController: PostTitleViewDelegate {
    func didPressLinkButton(_ post: HNPost) {
        guard verifyLink(post.urlString) else { return }
        if let url = URL(string: post.urlString) {
            self.navigationController?.present(getSafariViewController(url), animated: true, completion: nil)
        }
    }
    
    func verifyLink(_ urlString: String?) -> Bool {
        guard let urlString = urlString, let url = URL(string: urlString) else { return false }
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
