//
//  CommentsViewController.swift
//  Hackers2
//
//  Created by Weiran Zhang on 07/06/2014.
//  Copyright (c) 2014 Glass Umbrella. All rights reserved.
//

import Foundation
import UIKit

class CommentsViewController : UIViewController, UITableViewDelegate, UITableViewDataSource, CommentDelegate {
    
    var post: HNPost = HNPost()
    var comments: [CommentModel] = [CommentModel]() {
        didSet {
            commentsController.comments = comments
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
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return commentsController.visibleComments.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let comment = commentsController.visibleComments[indexPath.row]
        assert(comment.visibility != .Hidden, "Cell cannot be hidden and in the array of visible cells")
        let cellIdentifier = comment.visibility == CommentVisibilityType.Visible ? "OpenCommentCell" : "ClosedCommentCell"

        let cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier, forIndexPath: indexPath) as CommentTableViewCell
        
        cell.comment = comment
        cell.delegate = self
        
        return cell
    }
    
    func commentTapped(sender: UITableViewCell) {
        let indexPath = tableView.indexPathForCell(sender)
        toggleCellVisibilityForCell(indexPath)
    }
    
    func toggleCellVisibilityForCell(indexPath: NSIndexPath!) {
        let comment = self.commentsController.visibleComments[indexPath.row]
        
        let (modifiedIndexPaths, visibility) = commentsController.toggleCommentChildrenVisibility(comment)
                
        tableView.beginUpdates()
        tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        if visibility == CommentVisibilityType.Hidden {
            tableView.deleteRowsAtIndexPaths(modifiedIndexPaths, withRowAnimation: .Middle)
        } else {
            tableView.insertRowsAtIndexPaths(modifiedIndexPaths, withRowAnimation: UITableViewRowAnimation.Middle)
        }
        tableView.endUpdates()
    }
    
    @IBAction func close(sender : AnyObject) {
        dismissViewControllerAnimated(true, completion: nil)
    }
}