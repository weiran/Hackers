//
//  PostCell.swift
//  Hackers2
//
//  Created by Weiran Zhang on 07/06/2014.
//  Copyright (c) 2014 Glass Umbrella. All rights reserved.
//

import Foundation
import UIKit

protocol PostCellDelegate {
    func didPressLinkButton(post: HNPost)
}

class PostCell : UITableViewCell {
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var metadataLabel: UILabel!
    @IBOutlet var commentsLabel: UILabel!
    @IBOutlet var linkButton: UIButton!
    
    var delegate: PostCellDelegate?
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
        super.layoutSubviews()
        
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