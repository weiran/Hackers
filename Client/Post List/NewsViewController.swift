//
//  NewsViewController.swift
//  Hackers2
//
//  Created by Weiran Zhang on 07/06/2014.
//  Copyright (c) 2014 Glass Umbrella. All rights reserved.
//

import Foundation
import UIKit

class NewsViewController : UITableViewController, UISplitViewControllerDelegate {
    
    var posts: [HNPost] = [HNPost]()
    private var collapseDetailViewController = true
    
    override func viewDidLoad() {
        tableView.estimatedRowHeight = 80
        tableView.rowHeight = UITableViewAutomaticDimension // auto cell size magic
        refreshControl!.addTarget(self, action: Selector("loadPosts"), forControlEvents: UIControlEvents.ValueChanged)
        
        splitViewController?.delegate = self
        
        loadPosts()
        
        super.viewDidLoad()
    }
    
    override func viewWillAppear(animated: Bool) {
        navigationController!.setToolbarHidden(true, animated: true)
        if (tableView.indexPathForSelectedRow() != nil) {
            tableView .deselectRowAtIndexPath(tableView.indexPathForSelectedRow()!, animated: true)
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
        let cellIdentifier = "PostCell"
        let cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier, forIndexPath: indexPath) as PostCell
        let post = posts[indexPath.row]
        
        cell.titleLabel.text = post.Title
        cell.metadataLabel.text = post.UrlDomain
        cell.commentsLabel.text = "\(post.CommentCount) comments"
        
        // todo: if not default post type, show ycombinator domain instead in metadataLabel
        // cant do it currently as Type is reserved keyword which libHN uses
        
        return cell
    }
    
    // MARK: - UITableViewDelegate
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        collapseDetailViewController = false
        let post = posts[indexPath.row]
        let postViewNavigationController = UIStoryboard(name: "Storyboard", bundle: nil).instantiateViewControllerWithIdentifier("PostViewNavigationController") as UINavigationController
        let postViewController = postViewNavigationController.topViewController as PostViewController
        postViewController.post = post
        self.showDetailViewController(postViewNavigationController, sender: self)
    }
    
    // MARK: - UISplitViewControllerDelegate
    
    func splitViewController(splitViewController: UISplitViewController, collapseSecondaryViewController secondaryViewController: UIViewController!, ontoPrimaryViewController primaryViewController: UIViewController!) -> Bool {
        return collapseDetailViewController
    }

}