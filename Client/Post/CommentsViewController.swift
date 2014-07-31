//
//  CommentsViewController.swift
//  Hackers2
//
//  Created by Weiran Zhang on 07/06/2014.
//  Copyright (c) 2014 Glass Umbrella. All rights reserved.
//

import Foundation
import UIKit

class CommentsViewController : UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    var post: HNPost = HNPost()
    var comments: [CommentModel] = [CommentModel]() {
        didSet {
            commentsController.commentsSource = comments
        }
    }
    
    var commentsController = CommentsController()
    
    @IBOutlet var tableView: UITableView!
    
    override func viewDidLoad() {
        tableView.estimatedRowHeight = 44.0
        tableView.rowHeight = UITableViewAutomaticDimension
        if comments.count == 0 {
            loadComments()
        }
        commentsController = CommentsController()
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
    
    // MARK - UITableViewDataSource
    
    func tableView(tableView: UITableView!, numberOfRowsInSection section: Int) -> Int {
        return commentsController.comments.count
    }
    
    func tableView(tableView: UITableView!, cellForRowAtIndexPath indexPath: NSIndexPath!) -> UITableViewCell! {
        let comment = commentsController.comments[indexPath.row]
        assert(comment.visibility != .Hidden, "Cell cannot be hidden and in the array of visible cells")
        let cellIdentifier = comment.visibility == CommentVisibilityType.Visible ? "OpenCommentCell" : "ClosedCommentCell"

        let cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier, forIndexPath: indexPath) as CommentTableViewCell
        
        cell.authorLabel.text = comment.authorUsername
        cell.datePostedLabel.text = comment.dateCreatedString
        cell.commentString = comment.text
        cell.level = comment.level
        return cell
    }
    
    func tableView(tableView: UITableView!, didSelectRowAtIndexPath indexPath: NSIndexPath!) {
        NSLog("cell selected")
        toggleCellVisibilityForCell(indexPath)
    }
    
    func tableView(tableView: UITableView!, didDeselectRowAtIndexPath indexPath: NSIndexPath!) {
        NSLog("cell deselected")
        toggleCellVisibilityForCell(indexPath)
    }
    
    func toggleCellVisibilityForCell(indexPath: NSIndexPath!) {
        let (modifiedIndexPaths, visibility) = commentsController.toggleCommentChildrenVisibility(indexPath)
        
        tableView.beginUpdates()
        tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
        if visibility == CommentVisibilityType.Hidden {
            tableView.deleteRowsAtIndexPaths(modifiedIndexPaths, withRowAnimation: .Middle)
        } else {
            tableView.insertRowsAtIndexPaths(modifiedIndexPaths, withRowAnimation: UITableViewRowAnimation.Bottom)
        }
        tableView.endUpdates()
    }
    
    @IBAction func close(sender : AnyObject) {
        //dismissModalViewControllerAnimated(true)
        tableView.selectRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 0), animated: true, scrollPosition: UITableViewScrollPosition.None)
        toggleCellVisibilityForCell(NSIndexPath(forRow: 0, inSection: 0))
    }
}