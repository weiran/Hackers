//
//  ItemCell.swift
//  Hackers
//
//  Created by Weiran Zhang on 10/04/2021.
//  Copyright © 2021 Weiran Zhang. All rights reserved.
//

import UIKit
import Nuke

class ItemCell: UICollectionViewListCell {
    @IBOutlet weak var thumbnailImageView: ThumbnailImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var metadataLabel: UILabel!

    var post: Post?
    var linkPressedHandler: ((Post) -> Void)?
    private var thumbnailGestureRecognizer: UITapGestureRecognizer?

    override var isSelected: Bool {
        didSet {
            contentView.backgroundColor = isSelected ?
                AppTheme.default.cellHighlightColor : AppTheme.default.backgroundColor
        }
    }

    func apply(post: Post) {
        self.post = post

        titleLabel.text = post.title
        metadataLabel.attributedText = metadataText(for: post)

        setupThumbnailGesture()
    }

    func setupThumbnail(with url: URL?) {
        _ = thumbnailImageView.setImageWithPlaceholder(url: url)
    }
}

extension ItemCell {
    private func setupThumbnailGesture() {
        if thumbnailGestureRecognizer == nil {
            let thumbnailGestureRecognizer = UITapGestureRecognizer(
                target: self,
                action: #selector(didTapThumbnail(_:))
            )
            thumbnailGestureRecognizer.cancelsTouchesInView = true
            thumbnailImageView.addGestureRecognizer(thumbnailGestureRecognizer)

            self.thumbnailGestureRecognizer = thumbnailGestureRecognizer
        }
    }

    @objc private func didTapThumbnail(_ sender: Any) {
        if let linkPressedHandler = linkPressedHandler,
           let post = post {
            linkPressedHandler(post)
        }
    }
}

extension ItemCell {
    private func domainLabelText(for post: Post) -> String {
        guard
            let urlComponents = URLComponents(url: post.url, resolvingAgainstBaseURL: false),
            var host = urlComponents.host else {
            return "news.ycombinator.com"
        }

        if host.starts(with: "www.") {
            host = String(host[4...])
        }

        return host
    }

    private func metadataText(for post: Post) -> NSAttributedString {
        let defaultAttributes = [NSAttributedString.Key.foregroundColor: AppTheme.default.textColor]
        var pointsAttributes = defaultAttributes
        var pointsTintColor: UIColor?

        if post.upvoted {
            pointsAttributes = [NSAttributedString.Key.foregroundColor: AppTheme.default.upvotedColor]
            pointsTintColor = AppTheme.default.upvotedColor
        }

        let pointsIconAttachment = textAttachment(for: "PointsIcon", tintColor: pointsTintColor)
        let pointsIconAttributedString = NSAttributedString(attachment: pointsIconAttachment)

        let commentsIconAttachment = textAttachment(for: "CommentsIcon", tintColor: AppTheme.default.textColor)
        let commentsIconAttributedString = NSAttributedString(attachment: commentsIconAttachment)

        let string = NSMutableAttributedString()
        string.append(NSAttributedString(string: "\(post.score)", attributes: pointsAttributes))
        string.append(pointsIconAttributedString)
        string.append(NSAttributedString(string: "• \(post.commentsCount) ", attributes: defaultAttributes))
        string.append(commentsIconAttributedString)
        string.append(NSAttributedString(string: " • \(domainLabelText(for: post))", attributes: defaultAttributes))
        return string
    }

    private func templateImage(named: String, tintColor: UIColor? = nil) -> UIImage? {
        let image = UIImage.init(named: named)
        var templateImage = image?.withRenderingMode(.alwaysTemplate)
        if let tintColor = tintColor {
           templateImage = templateImage?.withTintColor(tintColor)
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
