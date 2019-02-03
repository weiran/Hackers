//
//  PostTitleView.swift
//  Hackers
//
//  Created by Weiran Zhang on 12/07/2015.
//  Copyright © 2015 Glass Umbrella. All rights reserved.
//

import UIKit
import HNScraper

protocol PostTitleViewDelegate {
    func didPressLinkButton(_ post: HNPost)
}

class PostTitleView: UIView, UIGestureRecognizerDelegate {
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var metadataLabel: UILabel!
    
    var isTitleTapEnabled = false
    var pointsMetadataRangeToHighlight: NSRange?
    var popularPostPointsThreshold = 200
    
    var delegate: PostTitleViewDelegate?
    
    var post: HNPost? {
        didSet {
            guard let post = post else { return }
            titleLabel.text = post.title
            metadataLabel.attributedText = metadataText(for: post)
            highlightPointsInMetadata()
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        setupTheming()
        
        let titleTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.didPressTitleText(_:)))
        titleLabel.addGestureRecognizer(titleTapGestureRecognizer)
    }
    
    @objc func didPressTitleText(_ sender: UITapGestureRecognizer) {
        if isTitleTapEnabled, let delegate = delegate {
            delegate.didPressLinkButton(post!)
        }
    }
    
    private func domainLabelText(for post: HNPost) -> String {
        guard let url = post.url,
            let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false),
            var host = urlComponents.host else {
            return "news.ycombinator.com"
        }
        
        if host.starts(with: "www.") {
            host = String(host[4...])
        }
        
        return host
    }
    
    private func metadataText(for post: HNPost) -> NSAttributedString {
        let string = NSMutableAttributedString()
        
        let pointsIconAttachment = textAttachment(for: "PointsIcon")
        let pointsIconAttributedString = NSAttributedString(attachment: pointsIconAttachment)
        
        let commentsIconAttachment = textAttachment(for: "CommentsIcon")
        let commentsIconAttributedString = NSAttributedString(attachment: commentsIconAttachment)
        
        string.append(NSAttributedString(string: "\(post.points)"))
        string.append(pointsIconAttributedString)

        if (post.points > popularPostPointsThreshold) {
            pointsMetadataRangeToHighlight = NSRange(location: 0, length: string.length)
        } else {
            pointsMetadataRangeToHighlight = nil
        }

        string.append(NSAttributedString(string: "• \(post.commentCount)"))
        string.append(commentsIconAttributedString)
        string.append(NSAttributedString(string: " • \(domainLabelText(for: post))"))
        
        return string
    }
    
    private func templateImage(named: String) -> UIImage? {
        let image = UIImage.init(named: named)
        let templateImage = image?.withRenderingMode(.alwaysTemplate)
        return templateImage
    }
    
    private func textAttachment(for imageNamed: String) -> NSTextAttachment {
        let attachment = NSTextAttachment()
        guard let image = templateImage(named: imageNamed) else { return attachment }
        attachment.image = image
        attachment.bounds = CGRect(x: 0, y: -2, width: image.size.width, height: image.size.height)
        return attachment
    }

    private func highlightPointsInMetadata() {
        guard let mutableMetadataText = metadataLabel.attributedText?.mutableCopy() as? NSMutableAttributedString else {
            return
        }
        if let range = pointsMetadataRangeToHighlight {
            mutableMetadataText.addAttribute(
                NSAttributedString.Key.foregroundColor,
                value: UIColor.orange,
                range: range)
            metadataLabel.attributedText = mutableMetadataText
        }
    }
}

extension PostTitleView: Themed {
    func applyTheme(_ theme: AppTheme) {
        titleLabel.textColor = theme.titleTextColor
        metadataLabel.textColor = theme.textColor
        highlightPointsInMetadata()
    }
}
