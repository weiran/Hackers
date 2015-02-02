//
//  PostViewController.swift
//  Hackers2
//
//  Created by Weiran Zhang on 07/06/2014.
//  Copyright (c) 2014 Glass Umbrella. All rights reserved.
//

import Foundation
import UIKit

class PostViewController: UIViewController, UIWebViewDelegate {
    
    var post: HNPost?
    var comments: [HNComment] = [HNComment]()

    @IBOutlet weak var webView: UIWebView!
    @IBOutlet weak var forwardButton: UIBarButtonItem!
    @IBOutlet weak var backButton: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem()
        navigationItem.leftItemsSupplementBackButton = true
        splitViewController?.preferredDisplayMode = .PrimaryOverlay
        
        if let currentPost = post {
            webView.loadRequest(NSURLRequest(URL: NSURL(string: String(currentPost.UrlString))!))
            HNManager.sharedManager().loadCommentsFromPost(post, completion: {
                (comments: [AnyObject]!) in
                if let downcastedArray = comments as? [HNComment] {
                    self.comments = downcastedArray
                }
            })
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setToolbarHidden(false, animated: true)
    }
    
    // MARK - Button actions
    
    @IBAction func share(sender: UIBarButtonItem) {
        let url = NSURL(string: String(post!.UrlString))
        let title = String(post!.Title)
        let objectsToShare: Array<AnyObject!> = [url, title]
        let activityViewController = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)
        activityViewController.popoverPresentationController?.barButtonItem = sender

        presentViewController(activityViewController, animated: true, completion: nil)
    }
    
    // MARK - UIWebViewDelegate
    
    func webViewDidStartLoad(webView: UIWebView!) {
        updateNavigationButtonsStateForWebView(webView)
    }
    
    func webViewDidFinishLoad(webView: UIWebView!) {
        updateNavigationButtonsStateForWebView(webView)
    }
    
    func updateNavigationButtonsStateForWebView(_webView: UIWebView) {
        backButton.enabled = _webView.canGoBack
        forwardButton.enabled = _webView.canGoForward
    }
    
    
    // MARK - UISegueDelegate
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!) {
        if segue.identifier == "ShowCommentsSegue" {
            let navigationController = segue.destinationViewController as UINavigationController
            let commentsViewController = navigationController.viewControllers[0] as CommentsViewController
            commentsViewController.post = post!
        }
    }
    
}