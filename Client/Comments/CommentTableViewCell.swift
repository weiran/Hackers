//
//  CommentTableViewCell.swift
//  Hackers2
//
//  Created by Weiran Zhang on 07/06/2014.
//  Copyright (c) 2014 Glass Umbrella. All rights reserved.
//

import Foundation
import UIKit
import HNScraper
import SwipeCellKit

class CommentTableViewCell: SwipeTableViewCell {
    public weak var commentDelegate: CommentDelegate?

    private var level: Int = 0 {
        didSet { updateIndentPadding() }
    }

    private var comment: HNComment?

    @IBOutlet var commentTextView: TouchableTextView!
    @IBOutlet var authorLabel: UILabel!
    @IBOutlet var datePostedLabel: UILabel!
    @IBOutlet var leftPaddingConstraint: NSLayoutConstraint!
    @IBOutlet weak var separatorView: UIView!
    @IBOutlet weak var upvoteIconImageView: UIImageView!

    override func awakeFromNib() {
        super.awakeFromNib()
        setupTheming()
        contentView.addGestureRecognizer(UITapGestureRecognizer(target: self,
                                                                action: #selector(CommentTableViewCell.cellTapped)))
        upvoteIconImageView?.image = UIImage(named: "PointsIcon")?
            .withTint(color: themeProvider.currentTheme.upvotedColor)
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

    public func updateCommentContent(with comment: HNComment, theme: AppTheme) {
        self.comment = comment

        let isCollapsed = comment.visibility != .visible
        level = comment.level
        authorLabel.text = comment.username
        authorLabel.font = AppFont.commentUsernameFont(collapsed: isCollapsed)
        datePostedLabel.text = comment.created
        datePostedLabel.font = AppFont.commentDateFont(collapsed: isCollapsed)
        upvoteIconImageView?.isHidden = comment.upvoted == false

        if let commentTextView = commentTextView, comment.visibility == .visible {
            // only for expanded comments
            let commentFont = UIFont.preferredFont(forTextStyle: .subheadline)
            let commentAttributedString = NSMutableAttributedString(string: comment.text.parsedHTML())
            let commentRange = NSRange(location: 0, length: commentAttributedString.length)

            commentAttributedString.addAttribute(NSAttributedString.Key.font,
                                                 value: commentFont,
                                                 range: commentRange)
            commentAttributedString.addAttribute(NSAttributedString.Key.foregroundColor,
                                                 value: theme.textColor,
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
                    commentDelegate.linkTapped(URL, sender: textView)
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
        backgroundColor = AppThemeProvider.shared.currentTheme.cellHighlightColor
    }

    private func setUnselectedBackground() {
        backgroundColor = AppThemeProvider.shared.currentTheme.backgroundColor
    }
}

extension CommentTableViewCell: Themed {
    func applyTheme(_ theme: AppTheme) {
        backgroundColor = theme.backgroundColor
        if commentTextView != nil {
            commentTextView.tintColor = theme.appTintColor
        }
        if authorLabel != nil {
            authorLabel.textColor = theme.titleTextColor
        }
        if datePostedLabel != nil {
            datePostedLabel.textColor = theme.lightTextColor
        }
        if separatorView != nil {
            separatorView.backgroundColor = theme.separatorColor
        }
        if let comment = self.comment {
            updateCommentContent(with: comment, theme: theme)
        }
    }
}
