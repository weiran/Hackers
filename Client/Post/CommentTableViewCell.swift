//
//  CommentTableViewCell.swift
//  Hackers2
//
//  Created by Weiran Zhang on 07/06/2014.
//  Copyright (c) 2014 Glass Umbrella. All rights reserved.
//

import Foundation
import UIKit


class CommentTableViewCell : UITableViewCell, UITextViewDelegate {
    
    var delegate: CommentDelegate?
    
    var level: Int = 0 {
        didSet { updateIndentPadding() }
    }
    
    var comment: CommentModel? {
        didSet {
            level = comment!.level
            datePostedLabel.text = comment?.dateCreatedString
            authorLabel.text = comment?.authorUsername
            
            if let textView = commentTextView {
                let commentFont = UIFont.systemFont(ofSize: 15) //UIFont(name: "HelveticaNeue-Light", size: 15)
                let commentTextColor = UIColor.darkGray
                let lineSpacing = 4 as CGFloat
                
                let commentAttributedString = NSMutableAttributedString(string: comment!.text)
                let paragraphStyle = NSMutableParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle
                paragraphStyle.lineSpacing = lineSpacing
                
                let commentRange = NSMakeRange(0, commentAttributedString.length)
                
                commentAttributedString.addAttribute(NSAttributedStringKey.font, value: commentFont, range: commentRange)
                commentAttributedString.addAttribute(NSAttributedStringKey.foregroundColor, value: commentTextColor, range: commentRange)
                commentAttributedString.addAttribute(NSAttributedStringKey.paragraphStyle, value: paragraphStyle, range: commentRange)
                
                textView.attributedText = commentAttributedString.copy() as! NSAttributedString
            }
        }
    }
    
    
    @IBOutlet var commentTextView: UITextView!
    @IBOutlet var authorLabel : UILabel!
    @IBOutlet var datePostedLabel : UILabel!
    @IBOutlet var leftPaddingConstraint : NSLayoutConstraint!
    
    override func awakeFromNib() {
        contentView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(CommentTableViewCell.cellTapped(_:))))
        isExclusiveTouch = true
        contentView.isExclusiveTouch = true
    }
    
    @objc func cellTapped(_ gestureRecognizer: UITapGestureRecognizer) {
        delegate?.commentTapped(self)
        setSelected(!isSelected, animated: false)
    }
    
    func updateIndentPadding() {
        let levelIndent = 15
        let padding = CGFloat(levelIndent * (level + 1))
        leftPaddingConstraint.constant = padding
    }
    
    // MARK - UITextViewDelegate
    
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange) -> Bool {
        if let _ = delegate {
            delegate!.linkTapped(URL, sender: textView)
            return false
        }
        return true
    }
    
}
