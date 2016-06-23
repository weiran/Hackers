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
import libHN
import DZNEmptyDataSet

class CommentsViewController : UIViewController, UITableViewDelegate, UITableViewDataSource, CommentDelegate, SFSafariViewControllerDelegate, PostTitleViewDelegate, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {
    var post: HNPost?
    
    var comments: [CommentModel]? {
        didSet {
            commentsController.comments = comments!
        }
    }
    
    let commentsController = CommentsController()
    
    @IBOutlet var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        Theme.setNavigationBarBackground(navigationController!.navigationBar)
        setupPostTitleView()
        tableView.estimatedRowHeight = 44.0
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.emptyDataSetSource = self;
        tableView.emptyDataSetDelegate = self;
        
        loadComments()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        UIApplication.sharedApplication().statusBarStyle = .LightContent
    }
    
    func loadComments() {
        HNManager.sharedManager().loadCommentsFromPost(post, completion: {
            (_comments: [AnyObject]!) in
            if let downcastedArray = _comments as? [HNComment] {
                let mappedComments = downcastedArray.map { CommentModel(source: $0) }
                self.comments = mappedComments
                self.tableView.reloadData()
            }
        })
    }
    
    func setupPostTitleView() {
        if let postTitleView = tableView.tableHeaderView as? PostTitleView {
            postTitleView.post = post
            postTitleView.delegate = self
            
            postTitleView.setNeedsLayout()
            postTitleView.layoutIfNeeded()
            
            let height = postTitleView.systemLayoutSizeFittingSize(UILayoutFittingCompressedSize).height
            var frame = postTitleView.frame
            frame.size.height = height
            postTitleView.frame = frame
            
            tableView.tableHeaderView = postTitleView
        }
    }
    
    // MARK: - UITableViewDataSource
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return commentsController.visibleComments.count
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Comments"
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let comment = commentsController.visibleComments[indexPath.row]
        assert(comment.visibility != .Hidden, "Cell cannot be hidden and in the array of visible cells")
        let cellIdentifier = comment.visibility == CommentVisibilityType.Visible ? "OpenCommentCell" : "ClosedCommentCell"

        let cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier, forIndexPath: indexPath) as! CommentTableViewCell
        
        cell.comment = comment
        cell.delegate = self
        
        return cell
    }
    
    // MARK: - DZNEmptyDataSet
    
    func titleForEmptyDataSet(scrollView: UIScrollView!) -> NSAttributedString! {
        let attributes = [NSFontAttributeName: UIFont.systemFontOfSize(15.0)]
        return comments == nil ? NSAttributedString(string: "Loading comments", attributes: attributes) : NSAttributedString(string: "No comments", attributes: attributes)
    }
    
    // MARK: - Cell Actions
    
    func commentTapped(sender: UITableViewCell) {
        let indexPath = tableView.indexPathForCell(sender)
        toggleCellVisibilityForCell(indexPath)
    }
    
    func linkTapped(URL: NSURL, sender: UITextView) {
        let safariViewController = SFSafariViewController(URL: URL)
        self.navigationController!.presentViewController(safariViewController, animated: true, completion: nil)
        UIApplication.sharedApplication().statusBarStyle = .Default
    }
    
    func toggleCellVisibilityForCell(indexPath: NSIndexPath!) {
        let comment = commentsController.visibleComments[indexPath.row]
        let cellRectInTableView = tableView.rectForRowAtIndexPath(indexPath)
        let cellRectInSuperview = tableView.convertRect(cellRectInTableView, toView: tableView.superview)

        let (modifiedIndexPaths, visibility) = commentsController.toggleCommentChildrenVisibility(comment)
                
        tableView.beginUpdates()
        tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        if visibility == CommentVisibilityType.Hidden {
            tableView.deleteRowsAtIndexPaths(modifiedIndexPaths, withRowAnimation: .Middle)
        } else {
            tableView.insertRowsAtIndexPaths(modifiedIndexPaths, withRowAnimation: UITableViewRowAnimation.Middle)
        }
        tableView.endUpdates()
        
        if cellRectInSuperview.origin.y < 0 {
            tableView.scrollToRowAtIndexPath(indexPath, atScrollPosition: .Top, animated: true)
        }
    }
    
    // MARK: - PostCellDelegate
    
    func didPressLinkButton(post: HNPost) {
        let safariViewController = SFSafariViewController(URL: NSURL(string: post.UrlString)!)
        self.navigationController!.presentViewController(safariViewController, animated: true, completion: nil)
        UIApplication.sharedApplication().statusBarStyle = .Default
    }
    
    @IBAction func shareTapped(sender: AnyObject) {
        let activityViewController = UIActivityViewController(activityItems: [post!.Title, NSURL(string: post!.UrlString)!], applicationActivities: nil)
        activityViewController.popoverPresentationController?.barButtonItem = sender as? UIBarButtonItem
        presentViewController(activityViewController, animated: true, completion: nil)
    }
}