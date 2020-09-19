//
//  PostCell.swift
//  Hackers
//
//  Created by Weiran Zhang on 07/06/2014.
//  Copyright (c) 2014 Weiran Zhang. All rights reserved.
//

import Foundation
import UIKit
import SwipeCellKit

protocol PostCellDelegate: class {
    func didTapThumbnail(_ sender: Any)
}

class PostCell: SwipeTableViewCell {
    weak var postDelegate: PostCellDelegate?

    @IBOutlet weak var postTitleView: PostTitleView!
    @IBOutlet weak var thumbnailImageView: ThumbnailImageView!
    @IBOutlet weak var separatorView: UIView!

    override func layoutSubviews() {
        super.layoutSubviews()
        setupTheming()
        setupThumbnailGesture()
    }

    private func setupThumbnailGesture() {
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTapThumbnail(_:)))
        thumbnailImageView.addGestureRecognizer(tapGestureRecognizer)
    }

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

    @objc private func didTapThumbnail(_ sender: Any) {
        postDelegate?.didTapThumbnail(sender)
    }

    func setImageWithPlaceholder(url: URL?) {
        _ = thumbnailImageView.setImageWithPlaceholder(url: url!)
    }
}

extension PostCell: Themed {
    func applyTheme(_ theme: AppTheme) {
        backgroundColor = theme.backgroundColor
        separatorView?.backgroundColor = theme.separatorColor
        thumbnailImageView.backgroundColor = theme.groupedTableViewBackgroundColor
        overrideUserInterfaceStyle = theme.userInterfaceStyle
    }
}
