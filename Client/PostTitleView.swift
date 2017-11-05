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
//            metadataLabel.text = "\(post.points) p • \(post.commentCount) c • \(domainLabelText(for: post))"
            metadataLabel.attributedText = metadataText(for: post)
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
    
    fileprivate func metadataText(for post: HNPost) -> NSAttributedString {
        let string = NSMutableAttributedString()
        
        let pointsIconAttachment = NSTextAttachment()
        pointsIconAttachment.image = templateImage(named: "PointsIcon")
        let pointsIconAttributedString = NSAttributedString(attachment: pointsIconAttachment)
        
        let commentsIconAttachment = NSTextAttachment()
        commentsIconAttachment.image = templateImage(named: "CommentsIcon")
        let commentsIconAttributedString = NSAttributedString(attachment: commentsIconAttachment)
        
        string.append(NSAttributedString(string: "\(post.points) "))
        string.append(pointsIconAttributedString)
        string.append(NSAttributedString(string: " • \(post.commentCount) "))
        string.append(commentsIconAttributedString)
        string.append(NSAttributedString(string: " • \(domainLabelText(for: post))"))
        
        return string
    }
    
    fileprivate func templateImage(named: String) -> UIImage? {
        let image = UIImage.init(named: named)
        let templateImage = image?.withRenderingMode(.alwaysTemplate)
        return templateImage
    }
}
