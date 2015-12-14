//
//  PostTitleView.swift
//  Hackers
//
//  Created by Weiran Zhang on 12/07/2015.
//  Copyright © 2015 Glass Umbrella. All rights reserved.
//

import UIKit

protocol PostTitleViewDelegate {
    func didPressLinkButton(post: HNPost)
}

class PostTitleView: UIView {
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var metadataLabel: UILabel!
    @IBOutlet var commentsLabel: UILabel!
    @IBOutlet var linkButton: UIButton!
    
    var delegate: PostTitleViewDelegate?
    var post: HNPost? {
        didSet {
            if let post = post {
                titleLabel.text = post.Title
                metadataLabel.text = "\(post.Points) points"
                commentsLabel.text = "\(post.CommentCount) comments"
                linkButton.setTitle(post.UrlDomain, forState: .Normal)
            }
        }
    }

    override func layoutSubviews() {
        setupLinkButton()
        titleLabel.preferredMaxLayoutWidth = titleLabel.bounds.size.width;
    }
    
    func setupLinkButton() {
        linkButton.layer.borderWidth = 0.5
        linkButton.layer.borderColor = UIColor(white: 0.9, alpha: 1).CGColor
        linkButton.layer.cornerRadius = 3
    }
    
    @IBAction func didPressLinkButton(sender: UIButton) {
        if let delegate = delegate {
            delegate.didPressLinkButton(post!)
        }
    }
}
