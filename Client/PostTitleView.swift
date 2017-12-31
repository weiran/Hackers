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
        guard let urlComponents = URLComponents(string: post.urlString), var host = urlComponents.host else {
            return "news.ycombinator.com"
        }
        
        if host.starts(with: "www.") {
            host = String(host[4...])
        }
        
        return host
    }
    
    fileprivate func metadataText(for post: HNPost) -> NSAttributedString {
        let string = NSMutableAttributedString()
        
        let pointsIconAttachment = textAttachment(for: "PointsIcon")
        let pointsIconAttributedString = NSAttributedString(attachment: pointsIconAttachment)
        
        let commentsIconAttachment = textAttachment(for: "CommentsIcon")
        let commentsIconAttributedString = NSAttributedString(attachment: commentsIconAttachment)
        
        string.append(NSAttributedString(string: "\(post.points)"))
        string.append(pointsIconAttributedString)
        string.append(NSAttributedString(string: "• \(post.commentCount)"))
        string.append(commentsIconAttributedString)
        string.append(NSAttributedString(string: " • \(domainLabelText(for: post))"))
        
        return string
    }
    
    fileprivate func templateImage(named: String) -> UIImage? {
        let image = UIImage.init(named: named)
        let templateImage = image?.withRenderingMode(.alwaysTemplate)
        return templateImage
    }
    
    fileprivate func textAttachment(for imageNamed: String) -> NSTextAttachment {
        let attachment = NSTextAttachment()
        guard let image = templateImage(named: imageNamed) else { return attachment }
        attachment.image = image
        attachment.bounds = CGRect(x: 0, y: -2, width: image.size.width, height: image.size.height)
        return attachment
    }
}
