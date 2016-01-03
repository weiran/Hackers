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
        super.viewDidLoad()
        
        tableView.estimatedRowHeight = 80
        tableView.rowHeight = UITableViewAutomaticDimension // auto cell size magic

        refreshControl!.backgroundColor = Theme.backgroundGreyColour
        refreshControl!.tintColor = Theme.orangeColour
        refreshControl!.addTarget(self, action: Selector("loadPosts"), forControlEvents: UIControlEvents.ValueChanged)
        
        splitViewController!.delegate = self
        
        Theme.setNavigationBarBackground(navigationController!.navigationBar)
        loadPosts()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if let indexPath = tableView.indexPathForSelectedRow {
            tableView.deselectRowAtIndexPath(indexPath, animated: true)
        }
        
        UIApplication.sharedApplication().statusBarStyle = .LightContent
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
        var viewController = storyboard!.instantiateViewControllerWithIdentifier("PostViewNavigationController")
        let commentsViewController = (viewController as! UINavigationController).viewControllers.first as! CommentsViewController
        
        let post = posts[indexPath.row]
        commentsViewController.post = post
        
        if UIDevice.currentDevice().userInterfaceIdiom == .Phone {
            // for iPhone we only want to push the view controller not navigation controller
            viewController = commentsViewController
        }
        
        showDetailViewController(viewController, sender: self)
    }
    
    // MARK: - UISplitViewControllerDelegate
    
    func splitViewController(splitViewController: UISplitViewController, collapseSecondaryViewController secondaryViewController: UIViewController, ontoPrimaryViewController primaryViewController: UIViewController) -> Bool {
        return collapseDetailViewController
    }
    
    // MARK: - PostCellDelegate
    
    func didPressLinkButton(post: HNPost) {
        let safariViewController = SFSafariViewController(URL: NSURL(string: post.UrlString)!)
        self.navigationController?.presentViewController(safariViewController, animated: true, completion: nil)
        UIApplication.sharedApplication().statusBarStyle = .Default
    }
}