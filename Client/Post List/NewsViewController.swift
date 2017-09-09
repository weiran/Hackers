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

class NewsViewController : UITableViewController, UISplitViewControllerDelegate, PostTitleViewDelegate, PostCellDelegate,  SFSafariViewControllerDelegate, SFSafariViewControllerPreviewActionItemsDelegate, UIViewControllerPreviewingDelegate, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {
    
    var posts: [HNPost] = [HNPost]()
    
    private var selectedPostType: PostFilterType! = .top
    private var collapseDetailViewController = true
    private var peekedIndexPath: IndexPath?
    private var thumbnailProcessedUrls = [String]()
    private var nextPageIdentifier: String?
    private var isProcessing: Bool = false
    private var cancelFetch: (() -> Void)?
    
    @IBOutlet weak var postTypeSegmentedControl: UISegmentedControl!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        registerForPreviewing(with: self, sourceView: tableView)
        
        tableView.estimatedRowHeight = 150
        tableView.rowHeight = UITableViewAutomaticDimension // auto cell size magic
        tableView.emptyDataSetSource = self
        tableView.emptyDataSetDelegate = self

        refreshControl!.backgroundColor = Theme.backgroundGreyColour
        refreshControl!.tintColor = Theme.purpleColour
        refreshControl!.addTarget(self, action: #selector(NewsViewController.loadPosts), for: UIControlEvents.valueChanged)
        
        postTypeSegmentedControl.tintColor = Theme.purpleColour
        
        splitViewController!.delegate = self
        
        Theme.setNavigationBarBackground(navigationController!.navigationBar)
        NotificationCenter.default.addObserver(self, selector: #selector(CommentsViewController.viewDidRotate), name: .UIDeviceOrientationDidChange, object: nil)
        
        loadPosts()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        UIApplication.shared.statusBarStyle = .lightContent
        rz_smoothlyDeselectRows(tableView: tableView)
    }
    
    @objc func viewDidRotate() {
        Theme.setNavigationBarBackground(navigationController?.navigationBar)
    }
    
    @objc func loadPosts() {
        isProcessing = true
        posts = [HNPost]()
        tableView.reloadData()
        
        if let cancelFetch = cancelFetch {
            cancelFetch()
        }
        
        let (fetchPromise, cancel) = fetch()
        fetchPromise
        .then { (posts, nextPageIdentifier) -> Void in
            self.posts = posts ?? [HNPost]()
            self.nextPageIdentifier = nextPageIdentifier
            self.tableView.reloadData()
        }
        .always {
            self.isProcessing = false
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
            HNManager.shared().loadPosts(with: selectedPostType) { posts, nextPageIdentifier in
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
        if let nextPageIdentifier = nextPageIdentifier {
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
        
        if let url = URL(string: post.urlString), !SettingsModel.shared.hideThumbnails {
            if let image = ThumbnailFetcher.getThumbnailFromCache(url: url) {
                cell.setImage(image: image)
            } else if !thumbnailProcessedUrls.contains(url.absoluteString) {
                ThumbnailFetcher.getThumbnail(url: url) { [weak self] image in
                    if image != nil {
                        DispatchQueue.main.async {
                            self?.thumbnailProcessedUrls.append(url.absoluteString)
                            self?.tableView.beginUpdates()
                            self?.tableView.reloadRows(at: [indexPath], with: .none)
                            self?.tableView.endUpdates()
                        }
                    }
                }
            }
        }
        
        // TODO: if not default post type, show ycombinator domain instead in metadataLabel
        // cant do it currently as Type is reserved keyword which libHN uses
        
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
    
    // MARK: - PostTypeSegmentedControl
    
    @IBAction func postTypeChanged(_ sender: Any) {
        switch postTypeSegmentedControl.selectedSegmentIndex {
        case 0:
            selectedPostType = .top
            break
            
        case 1:
            selectedPostType = .ask
            break
            
        case 2:
            selectedPostType = .jobs
            break
            
        case 3:
            selectedPostType = .new
            break
            
            
        default:
            selectedPostType = .top
        }
        
        loadPosts()
    }
    
    
    // MARK: - UISplitViewControllerDelegate
    
    func splitViewController(_ splitViewController: UISplitViewController, collapseSecondary secondaryViewController: UIViewController, onto primaryViewController: UIViewController) -> Bool {
        return collapseDetailViewController
    }
    
    // MARK: - PostTitleViewDelegate
    
    func getSafariViewController(_ URL: String) -> SFSafariViewController {
        let safariViewController = SFSafariViewController(url: Foundation.URL(string: URL)!)
        safariViewController.previewActionItemsDelegate = self
        return safariViewController
    }
    
    func didPressLinkButton(_ post: HNPost) {
        self.navigationController?.present(getSafariViewController(post.urlString), animated: true, completion: nil)
        UIApplication.shared.statusBarStyle = .default
    }
    
    // MARK: - PostCellDelegate
    
    func didTapThumbnail(_ sender: Any) {
        if let tapGestureRecognizer = sender as? UITapGestureRecognizer {
            let point = tapGestureRecognizer.location(in: tableView)
            if let indexPath = tableView.indexPathForRow(at: point) {
                let post = posts[indexPath.row]
                didPressLinkButton(post)
            }
        }
    }
    
    // MARK: - UIViewControllerPreviewingDelegate
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        if let indexPath = tableView.indexPathForRow(at: location) {
            peekedIndexPath = indexPath
            previewingContext.sourceRect = tableView.rectForRow(at: indexPath)
            let post = posts[indexPath.row]
            return getSafariViewController(post.urlString)
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
        return isProcessing ? NSAttributedString(string: "Loading", attributes: attributes) : NSAttributedString(string: "Nothing found", attributes: attributes)
    }
}
