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

class PostTitleView: UIView, UIGestureRecognizerDelegate {
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var metadataLabel: UILabel!
    
    var isTitleTapEnabled = false
    
    var delegate: PostTitleViewDelegate?
    
    var post: HNPost? {
        didSet {
            guard let post = post else { return }
            titleLabel.text = post.title
            metadataLabel.text = "\(post.points) p • \(post.commentCount) c • \(domainLabelText(for: post))"
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let titleTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.didPressTitleText(_:)))
        titleLabel.addGestureRecognizer(titleTapGestureRecognizer)
    }
    
    @objc func didPressTitleText(_ sender: UITapGestureRecognizer) {
        if isTitleTapEnabled, let delegate = delegate {
            delegate.didPressLinkButton(post!)
        }
    }
    
    fileprivate func domainLabelText(for post: HNPost) -> String {
        guard let urlComponents = URLComponents(string: post.urlString), let host = urlComponents.host else {
            return "news.ycombinator.com"
        }
        return host
    }
}
