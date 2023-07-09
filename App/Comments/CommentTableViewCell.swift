//
//  CommentTableViewCell.swift
//  Hackers
//
//  Created by Weiran Zhang on 07/06/2014.
//  Copyright (c) 2014 Weiran Zhang. All rights reserved.
//

import Foundation
import UIKit
import SwipeCellKit
import SwiftSoup

class CommentTableViewCell: SwipeTableViewCell {
    weak var commentDelegate: CommentDelegate?

    private var level: Int = 0 {
        didSet { updateIndentPadding() }
    }

    private var comment: Comment?
    private var isPostAuthor: Bool = false

    @IBOutlet var commentTextView: TouchableTextView!
    @IBOutlet var authorLabel: UILabel!
    @IBOutlet var datePostedLabel: UILabel!
    @IBOutlet var leftPaddingConstraint: NSLayoutConstraint!
    @IBOutlet weak var separatorView: UIView!
    @IBOutlet weak var upvoteIconImageView: UIImageView!

    override func awakeFromNib() {
        super.awakeFromNib()
        contentView.addGestureRecognizer(
            UITapGestureRecognizer(
                target: self,
                action: #selector(CommentTableViewCell.cellTapped)
            )
        )
        upvoteIconImageView?.image = UIImage(named: "PointsIcon")?
            .withTintColor(AppTheme.default.upvotedColor)
    }

    @objc private func cellTapped() {
        commentDelegate?.commentTapped(self)
        setSelected(!isSelected, animated: false)
    }

    private func updateIndentPadding() {
        let levelIndent = 15
        let padding = CGFloat(levelIndent * (level + 1))
        leftPaddingConstraint.constant = padding
    }

    func updateCommentContent(with comment: Comment, isPostAuthor: Bool? = nil) {
        self.comment = comment

        let isCollapsed = comment.visibility != .visible
        level = comment.level
        authorLabel.text = comment.by
        authorLabel.font = AppFont.commentUsernameFont(collapsed: isCollapsed)
        datePostedLabel.text = comment.age
        datePostedLabel.font = AppFont.commentDateFont(collapsed: isCollapsed)
        upvoteIconImageView?.isHidden = comment.upvoted == false

        if let isPostAuthor = isPostAuthor {
            self.isPostAuthor = isPostAuthor
            self.applyAuthorLabelTheme()
        }

        if let commentTextView = commentTextView, comment.visibility == .visible {
            // only for expanded comments
            let commentFont = UIFont.preferredFont(forTextStyle: .subheadline)
            let commentAttributedString = comment.text.parseToAttributedString()
            let commentRange = NSRange(location: 0, length: commentAttributedString.length)

            commentAttributedString.addAttribute(NSAttributedString.Key.font,
                                                 value: commentFont,
                                                 range: commentRange)
            commentAttributedString.addAttribute(NSAttributedString.Key.foregroundColor,
                                                 value: AppTheme.default.textColor,
                                                 range: commentRange)

            commentTextView.attributedText = commentAttributedString
        }
    }
}

extension CommentTableViewCell: UITextViewDelegate {
    func textView(_ textView: UITextView,
                  shouldInteractWith URL: URL,
                  in characterRange: NSRange,
                  interaction: UITextItemInteraction) -> Bool {
        switch interaction {
        case .invokeDefaultAction:
            // For some reason iOS 13 calls this multiple times when interacting with a link
            // so we need to check gesture recognizer to see if its when ended
            if textView.gestureRecognizers?.contains(where: {
                $0.isKind(of: UITapGestureRecognizer.self) &&
                $0.state == .ended }) == true {
                if let commentDelegate = commentDelegate {
                    if
                        let host = URL.host,
                        host.contains("news.ycombinator.com"),
                        let range = URL.absoluteString.range(of: "id="),
                        let id = Int(
                            URL.absoluteString[range.upperBound...]
                                .trimmingCharacters(in: .whitespaces)
                            ) {
                        commentDelegate.internalLinkTapped(postId: id, url: URL, sender: textView)
                    } else {
                        commentDelegate.linkTapped(URL, sender: textView)
                    }
                    return false
                }
            }
            return true
        default:
            // default case will handle presentActions (Long Press) case on url
            return true
        }
    }
}

extension CommentTableViewCell {
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        selected ? setSelectedBackground() : setUnselectedBackground()
    }

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        highlighted ? setSelectedBackground() : setUnselectedBackground()
    }

    private func setSelectedBackground() {
        backgroundColor = AppTheme.default.cellHighlightColor
    }

    private func setUnselectedBackground() {
        backgroundColor = AppTheme.default.backgroundColor
    }

    private func applyAuthorLabelTheme() {
        authorLabel.textColor = self.isPostAuthor ? AppTheme.default.appTintColor : AppTheme.default.titleTextColor
    }

}
