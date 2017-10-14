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
    
    var delegate: PostTitleViewDelegate?
    var post: HNPost? {
        didSet {
            guard let post = post else { return }
            titleLabel.text = post.title
            //TODO colour this so numbers are darker than text
            metadataLabel.text = "\(post.points) points • \(post.commentCount) comments"
        }
    }
    
    @IBAction func didPressLinkButton(_ sender: UIButton) {
        if let delegate = delegate {
            delegate.didPressLinkButton(post!)
        }
    }
}
