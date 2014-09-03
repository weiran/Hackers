//
//  NewsViewController.swift
//  Hackers2
//
//  Created by Weiran Zhang on 07/06/2014.
//  Copyright (c) 2014 Glass Umbrella. All rights reserved.
//

import Foundation
import UIKit

class NewsViewController : UITableViewController {
    
    var posts: [HNPost] = [HNPost]()
    
    override func viewDidLoad() {
        self.tableView.estimatedRowHeight = 66.0
        self.tableView.rowHeight = UITableViewAutomaticDimension // auto cell size magic
        self.refreshControl!.addTarget(self, action: Selector("loadPosts"), forControlEvents: UIControlEvents.ValueChanged)
        
        loadPosts()
        
        super.viewDidLoad()
    }
    
    override func viewWillAppear(animated: Bool) {
        self.navigationController!.setToolbarHidden(true, animated: true)
        if (self.tableView.indexPathForSelectedRow() != nil) {
            self.tableView .deselectRowAtIndexPath(self.tableView.indexPathForSelectedRow()!, animated: true)
        }
        
        super.viewWillAppear(animated)
    }
    
    func loadPosts() {
        if !refreshControl!.refreshing {
            refreshControl!.beginRefreshing()
        }
        
        HNManager.sharedManager().loadPostsWithFilter(PostFilterType.Top, completion: {
            (posts: [AnyObject]!) in
            if let downcastedArray = posts as? [HNPost] {
                self.posts = downcastedArray
                self.tableView.reloadData()
                self.refreshControl!.endRefreshing()
            }
        })
    }
    
    
    // MARK: UITableViewDataSource
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.posts.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cellIdentifier = "PostCell"
        let cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier, forIndexPath: indexPath) as PostCell
        let post = self.posts[indexPath.row]
        
        cell.titleLabel.text = post.Title
        cell.metadataLabel.text = post.UrlDomain
        cell.commentsLabel.text = "\(post.CommentCount) comments"
        
        // todo: if not default post type, show ycombinator domain instead in metadataLabel
        // cant do it currently as Type is reserved keyword which libHN uses
        
        return cell
    }
    
    
    // MARK: UISegueDelegate
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!) {
        if segue.identifier == "ShowPostSegue" {
            let postViewController = segue.destinationViewController as PostViewController
            let selectedIndexPath = self.tableView.indexPathForSelectedRow()
            let post = self.posts[selectedIndexPath!.row]
            postViewController.post = post
        }
    }
}