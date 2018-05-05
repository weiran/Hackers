//
//  CommentTableViewCell.swift
//  Hackers2
//
//  Created by Weiran Zhang on 07/06/2014.
//  Copyright (c) 2014 Glass Umbrella. All rights reserved.
//

import Foundation
import UIKit


class CommentTableViewCell : UITableViewCell {
    
    var delegate: CommentDelegate?
    
    var level: Int = 0 {
        didSet { updateIndentPadding() }
    }
    
    var comment: CommentModel? {
        didSet {
            guard let comment = comment else { return }
            updateCommentContent(with: comment)
        }
    }
    
    private var currentTextColor: UIColor = .darkGray
    
    @IBOutlet var commentTextView: TouchableTextView!
    @IBOutlet var authorLabel : UILabel!
    @IBOutlet var datePostedLabel : UILabel!
    @IBOutlet var leftPaddingConstraint : NSLayoutConstraint!
    @IBOutlet weak var separatorView: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupTheming()
        contentView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(CommentTableViewCell.cellTapped)))
    }
    
    @objc func cellTapped() {
        delegate?.commentTapped(self)
        setSelected(!isSelected, animated: false)
    }
    
    func updateIndentPadding() {
        let levelIndent = 15
        let padding = CGFloat(levelIndent * (level + 1))
        leftPaddingConstraint.constant = padding
    }
    
    func updateCommentContent(with comment: CommentModel) {
        level = comment.level
        datePostedLabel.text = comment.dateCreatedString
        authorLabel.text = comment.authorUsername
        
        if let commentTextView = commentTextView {
            // only for expanded comments
            let commentFont = UIFont.systemFont(ofSize: 15)
            let commentTextColor = currentTextColor
            let lineSpacing = 4 as CGFloat
            
            let commentAttributedString = NSMutableAttributedString(string: comment.text)
            let paragraphStyle = NSMutableParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle
            paragraphStyle.lineSpacing = lineSpacing
            
            let commentRange = NSMakeRange(0, commentAttributedString.length)
            
            commentAttributedString.addAttribute(NSAttributedStringKey.font, value: commentFont, range: commentRange)
            commentAttributedString.addAttribute(NSAttributedStringKey.foregroundColor, value: commentTextColor, range: commentRange)
            commentAttributedString.addAttribute(NSAttributedStringKey.paragraphStyle, value: paragraphStyle, range: commentRange)
            
            commentTextView.attributedText = commentAttributedString
        }
    }
}

extension CommentTableViewCell: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange) -> Bool {
        if let delegate = delegate {
            delegate.linkTapped(URL, sender: textView)
            return false
        }
        return true
    }
}

extension CommentTableViewCell: Themed {
    func applyTheme(_ theme: AppTheme) {
        backgroundColor = theme.backgroundColor
        if commentTextView != nil {
            commentTextView.tintColor = theme.appTintColor
        }
        if authorLabel != nil {
            authorLabel.textColor = theme.textColor
        }
        if datePostedLabel != nil {
            datePostedLabel.textColor = theme.lightTextColor
        }
        if separatorView != nil {
            separatorView.backgroundColor = theme.separatorColor
        }
        currentTextColor = theme.textColor
    }
}
