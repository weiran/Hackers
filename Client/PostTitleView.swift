//
//  PostTitleView.swift
//  Hackers
//
//  Created by Weiran Zhang on 12/07/2015.
//  Copyright © 2015 Glass Umbrella. All rights reserved.
//

import UIKit
import libHN

protocol PostTitleViewDelegate {
    func didPressLinkButton(_ post: HNPost)
}

class PostTitleView: UIView {
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var metadataLabel: UILabel!
    @IBOutlet var commentsLabel: UILabel!
    @IBOutlet var linkButton: UIButton!
    
    var delegate: PostTitleViewDelegate?
    var post: HNPost? {
        didSet {
            guard let post = post else { return }
            titleLabel.text = post.title
            metadataLabel.text = "\(post.points) points"
            commentsLabel.text = "\(post.commentCount) comments"
            linkButton.setTitle(post.urlDomain, for: .normal)
            if post.urlDomain == nil, post.type != .default {
                linkButton.setTitle("news.ycombinator.com", for: .normal)
            }
        }
    }
    
    @IBAction func didPressLinkButton(_ sender: UIButton) {
        if let delegate = delegate {
            delegate.didPressLinkButton(post!)
        }
    }
}
