//
//  PostViewController.swift
//  Hackers2
//
//  Created by Weiran Zhang on 07/06/2014.
//  Copyright (c) 2014 Glass Umbrella. All rights reserved.
//

import Foundation

class PostViewController : UIViewController, UIWebViewDelegate {
    var post: HNPost = HNPost()
    var comments: HNComment[] = HNComment[]()

    @IBOutlet var webView: UIWebView
    @IBOutlet var backButton: UIBarButtonItem
    @IBOutlet var forwardButton: UIBarButtonItem
    

    override func viewDidLoad() {
        self.webView.loadRequest(NSURLRequest(URL: NSURL(string: self.post.UrlString)))
        HNManager.sharedManager().loadCommentsFromPost(self.post, completion: {
            (comments: AnyObject[]!) in
            if let downcastedArray = comments as? HNComment[] {
                self.comments = downcastedArray
            }
        })
        
        super.viewDidLoad()
    }
    
    override func viewWillAppear(animated: Bool) {
        self.navigationController.setToolbarHidden(false, animated: true)
        
        super.viewWillAppear(animated)
    }
    
    // MARK - Button actions
    
    @IBAction func share(sender: UIView) {
        let content = OSKShareableContent(fromURL: NSURL(string: self.post.UrlString))
        let presentationManager = OSKPresentationManager.sharedInstance()
        presentationManager.presentActivitySheetForContent(content, presentingViewController: self.navigationController, options: nil)
    }
    
    // MARK - UIWebViewDelegate
    
    func webViewDidStartLoad(webView: UIWebView!) {
        updateNavigationButtonsStateForWebView(webView)
    }
    
    func webViewDidFinishLoad(webView: UIWebView!) {
        updateNavigationButtonsStateForWebView(webView)
    }
    
    func updateNavigationButtonsStateForWebView(_webView: UIWebView) {
        self.backButton.enabled = _webView.canGoBack
        self.forwardButton.enabled = _webView.canGoForward
    }
    
    
    // MARK - UISegueDelegate
    
    override func prepareForSegue(segue: UIStoryboardSegue!, sender: AnyObject!) {
        if segue.identifier == "ShowCommentsSegue" {
            let navigationController = segue.destinationViewController as UINavigationController
            let commentsViewController = navigationController.viewControllers[0] as CommentsViewController
            commentsViewController.post = self.post
        }
    }
    
}