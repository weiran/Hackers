//
//  PostTitleView.swift
//  Hackers
//
//  Created by Weiran Zhang on 12/07/2015.
//  Copyright © 2015 Glass Umbrella. All rights reserved.
//

import UIKit
import HNScraper

protocol PostTitleViewDelegate: class {
    func didPressLinkButton(_ post: HNPost)
}

class PostTitleView: UIView, UIGestureRecognizerDelegate {
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var metadataLabel: UILabel!

    public var isTitleTapEnabled = false

    public weak var delegate: PostTitleViewDelegate?

    public var post: HNPost? {
        didSet {
            guard let post = post else { return }
            titleLabel.text = post.title
            metadataLabel.attributedText = metadataText(for: post, theme: themeProvider.currentTheme)
        }
    }

    override open func layoutSubviews() {
        super.layoutSubviews()
        setupTheming()

        let titleTapGestureRecognizer = UITapGestureRecognizer(target: self,
                                                               action: #selector(didPressTitleText(_:)))
        titleLabel.addGestureRecognizer(titleTapGestureRecognizer)
    }

    @objc private func didPressTitleText(_ sender: UITapGestureRecognizer) {
        if isTitleTapEnabled, let delegate = self.delegate, let post = self.post {
            delegate.didPressLinkButton(post)
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

    private func metadataText(for post: HNPost, theme: AppTheme) -> NSAttributedString {
        let defaultAttributes = [NSAttributedString.Key.foregroundColor: theme.textColor]
        var pointsAttributes = defaultAttributes
        var pointsTintColor: UIColor?

        if post.upvoted {
            pointsAttributes = [NSAttributedString.Key.foregroundColor: theme.upvotedColor]
            pointsTintColor = theme.upvotedColor
        }

        let pointsIconAttachment = textAttachment(for: "PointsIcon", tintColor: pointsTintColor)
        let pointsIconAttributedString = NSAttributedString(attachment: pointsIconAttachment)

        let commentsIconAttachment = textAttachment(for: "CommentsIcon", tintColor: theme.textColor)
        let commentsIconAttributedString = NSAttributedString(attachment: commentsIconAttachment)

        let string = NSMutableAttributedString()
        string.append(NSAttributedString(string: "\(post.points)", attributes: pointsAttributes))
        string.append(pointsIconAttributedString)
        string.append(NSAttributedString(string: "• \(post.commentCount) ", attributes: defaultAttributes))
        string.append(commentsIconAttributedString)
        string.append(NSAttributedString(string: " • \(domainLabelText(for: post))", attributes: defaultAttributes))
        return string
    }

    private func templateImage(named: String, tintColor: UIColor? = nil) -> UIImage? {
        let image = UIImage.init(named: named)
        var templateImage = image?.withRenderingMode(.alwaysTemplate)
        if let tintColor = tintColor {
           templateImage = templateImage?.withTint(color: tintColor)
        }
        return templateImage
    }

    private func textAttachment(for imageNamed: String, tintColor: UIColor? = nil) -> NSTextAttachment {
        let attachment = NSTextAttachment()
        guard let image = templateImage(named: imageNamed, tintColor: tintColor) else { return attachment }
        attachment.image = image
        attachment.bounds = CGRect(x: 0, y: -2, width: image.size.width, height: image.size.height)
        return attachment
    }
}

extension PostTitleView: Themed {
    func applyTheme(_ theme: AppTheme) {
        titleLabel.textColor = theme.titleTextColor
        if let post = post {
            metadataLabel.attributedText = metadataText(for: post, theme: theme)
        }
        overrideUserInterfaceStyle = theme.userInterfaceStyle
    }
}
