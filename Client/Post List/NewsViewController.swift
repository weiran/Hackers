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
import SVProgressHUD

class NewsViewController : UITableViewController, UISplitViewControllerDelegate, PostTitleViewDelegate, PostCellDelegate,  SFSafariViewControllerDelegate, SFSafariViewControllerPreviewActionItemsDelegate, UIViewControllerPreviewingDelegate, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {
    
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
        
        tableView.estimatedRowHeight = 150
        tableView.rowHeight = UITableViewAutomaticDimension // auto cell size magic
        tableView.emptyDataSetSource = self
        tableView.emptyDataSetDelegate = self

        refreshControl!.tintColor = Theme.purpleColour
        refreshControl!.addTarget(self, action: #selector(NewsViewController.loadPosts), for: UIControlEvents.valueChanged)
        
        splitViewController!.delegate = self
        
        loadPosts()
        SVProgressHUD.show()
    }
    
    override func awakeFromNib() {
        // TODO: workaround for iOS 11 bug, remove when fixed
        navigationController?.navigationBar.prefersLargeTitles = false
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
    
    @objc func loadPosts(_ clear: Bool = false) {
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
        
        if (clear) {
            // clear data and show loading state
            posts = [HNPost]()
            tableView.reloadData()
        }
        
        // fetch new posts
        let (fetchPromise, cancel) = fetch()
        fetchPromise
        .then { (posts, nextPageIdentifier) -> Void in
            self.posts = posts ?? [HNPost]()
            self.nextPageIdentifier = nextPageIdentifier
            self.tableView.reloadData()
            SVProgressHUD.dismiss()
        }
        .catch { error in
            SVProgressHUD.showError(withStatus: "Failed")
            SVProgressHUD.dismiss(withDelay: 1.0)
        }
        .always {
            self.isProcessing = false
            self.refreshControl?.endRefreshing()
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
    
    // MARK: - UITableViewDataSource
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return posts.count
    }
  
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
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
                        self.tableView.reloadRows(at: [indexPath], with: .automatic)
                        self.tableView.endUpdates()
                    }
                }
                cancelThumbnailFetchTasks.append(cancel)
            }
        }
        
        return cell
    }
    
    // MARK: - UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        collapseDetailViewController = false
        var viewController = storyboard!.instantiateViewController(withIdentifier: "PostViewNavigationController")
        let commentsViewController = (viewController as! UINavigationController).viewControllers.first as! CommentsViewController
        
        let post = posts[indexPath.row]
        commentsViewController.post = post
        
        if UIDevice.current.userInterfaceIdiom == .phone {
            // for iPhone we only want to push the view controller not navigation controller
            viewController = commentsViewController
        }
        
        showDetailViewController(viewController, sender: self)
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.row == posts.count - 5 {
            loadMorePosts()
        }
    }
    
    override func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let cell = cell as? PostCell {
            cell.cancelThumbnailTask?()
        }
    }
    
    // MARK: - UISplitViewControllerDelegate
    
    func splitViewController(_ splitViewController: UISplitViewController, collapseSecondary secondaryViewController: UIViewController, onto primaryViewController: UIViewController) -> Bool {
        return collapseDetailViewController
    }
    
    // MARK: - PostTitleViewDelegate
    
    func getSafariViewController(_ url: URL) -> SFSafariViewController {
        let safariViewController = SFSafariViewController(url: url)
        safariViewController.previewActionItemsDelegate = self
        return safariViewController
    }
    
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
    
    // MARK: - PostCellDelegate
    
    func didTapThumbnail(_ sender: Any) {
        guard let tapGestureRecognizer = sender as? UITapGestureRecognizer else { return }
        let point = tapGestureRecognizer.location(in: tableView)
        if let indexPath = tableView.indexPathForRow(at: point) {
            let post = posts[indexPath.row]
            didPressLinkButton(post)
        }
    }
    
    // MARK: - UIViewControllerPreviewingDelegate
    
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
    
    // MARK: - DZN

    func title(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        let attributes = [NSAttributedStringKey.font: UIFont.systemFont(ofSize: 24.0)]
        return isProcessing ? NSAttributedString(string: "", attributes: attributes) : NSAttributedString(string: "Nothing found", attributes: attributes)
    }
}
