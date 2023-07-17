//
//  TextSelectionViewController.swift
//  Hackers
//
//  Created by Peter Ajayi on 08/07/2023.
//  Copyright © 2023 Glass Umbrella. All rights reserved.
//

import UIKit

final class TextSelectionViewController: UIViewController {

    var comment: String?

    @IBOutlet private var commentTextView: UITextView!

    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }

    private func setup() {
        view.backgroundColor = AppTheme.default.backgroundColor
        setupCommentTextView()
    }

    private func setupCommentTextView() {
        commentTextView.attributedText = attributedComment()
        commentTextView.textContainerInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        commentTextView.textColor = AppTheme.default.textColor
        commentTextView.selectAll(nil)
    }

    private func attributedComment() -> NSAttributedString? {
        guard let comment = comment else { return nil }

        let attributedString = comment.parseToAttributedString()

        let commentRange = NSRange(location: 0, length: attributedString.length)
        let commentFont = UIFont.preferredFont(forTextStyle: .subheadline)

        attributedString.addAttribute(NSAttributedString.Key.font,
                                      value: commentFont,
                                      range: commentRange)

        attributedString.addAttribute(NSAttributedString.Key.foregroundColor,
                                      value: AppTheme.default.textColor,
                                      range: commentRange)

        return attributedString
    }

    @IBAction private func didPressDone(_ sender: Any) {
        dismiss(animated: true)
    }
}
