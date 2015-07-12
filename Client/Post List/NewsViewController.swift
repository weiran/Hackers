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

class NewsViewController : UITableViewController, UISplitViewControllerDelegate, PostTitleViewDelegate, SFSafariViewControllerDelegate {
    
    var posts: [HNPost] = [HNPost]()
    private var collapseDetailViewController = true
    
    override func viewDidLoad() {
        tableView.estimatedRowHeight = 80
        tableView.rowHeight = UITableViewAutomaticDimension // auto cell size magic
        refreshControl?.backgroundColor = UIColor(red:0.937, green:0.937, blue:0.956, alpha:1)
        refreshControl!.addTarget(self, action: Selector("loadPosts"), forControlEvents: UIControlEvents.ValueChanged)
        
        splitViewController!.delegate = self
        
        loadPosts()
        
        super.viewDidLoad()
    }
    
    override func viewWillAppear(animated: Bool) {
        navigationController!.setToolbarHidden(true, animated: true)
        if let indexPath = tableView.indexPathForSelectedRow {
            tableView.deselectRowAtIndexPath(indexPath, animated: true)
        }
        
        super.viewWillAppear(animated)
    }
    
    func loadPosts() {
        if !refreshControl!.refreshing {
            refreshControl!.beginRefreshing()
        }
        
        HNManager.sharedManager().loadPostsWithFilter(.Top, completion: { (posts: [AnyObject]!, nextPageIdentifier: String!) -> Void in
            if let downcastedArray = posts as? [HNPost] {
                self.posts = downcastedArray
                self.tableView.reloadData()
                self.refreshControl!.endRefreshing()
            }
        })
    }
    
    
    // MARK: - UITableViewDataSource
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return posts.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("PostCell", forIndexPath: indexPath) as! PostCell
        let post = posts[indexPath.row]
        cell.postTitleView.post = post
        cell.postTitleView.delegate = self
        
        // todo: if not default post type, show ycombinator domain instead in metadataLabel
        // cant do it currently as Type is reserved keyword which libHN uses
        
        return cell
    }
    
    // MARK: - UITableViewDelegate
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        collapseDetailViewController = false
        let post = posts[indexPath.row]        
        let commentsViewController = storyboard?.instantiateViewControllerWithIdentifier("CommentsViewController") as! CommentsViewController
        commentsViewController.post = post
        showDetailViewController(commentsViewController, sender: self)
    }
    
    // MARK: - UISplitViewControllerDelegate
    
    func splitViewController(splitViewController: UISplitViewController, collapseSecondaryViewController secondaryViewController: UIViewController, ontoPrimaryViewController primaryViewController: UIViewController) -> Bool {
        return collapseDetailViewController
    }
    
    // MARK: - PostCellDelegate
    
    func didPressLinkButton(post: HNPost) {
        let safariViewController = SFSafariViewController(URL: NSURL(string: post.UrlString)!, entersReaderIfAvailable: false)
        safariViewController.delegate = self
        presentViewController(safariViewController, animated: true, completion: nil)
    }

    // MARK: - SFSafariViewControllerDelegate
    
    func safariViewControllerDidFinish(controller: SFSafariViewController) {
        controller.dismissViewControllerAnimated(true, completion: nil)
    }

}