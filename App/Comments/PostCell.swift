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

protocol PostCellDelegate: AnyObject {
    func didTapThumbnail(_ sender: Any)
}

class PostCell: SwipeTableViewCell {
    weak var postDelegate: PostCellDelegate?

    @IBOutlet weak var postTitleView: PostTitleView!
    @IBOutlet weak var thumbnailImageView: ThumbnailImageView!
    @IBOutlet weak var separatorView: UIView!

    override func layoutSubviews() {
        super.layoutSubviews()
        setupThumbnailGesture()
    }

    private func setupThumbnailGesture() {
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTapThumbnail(_:)))
        thumbnailImageView.addGestureRecognizer(tapGestureRecognizer)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        selected ? setSelectedBackground() : setUnselectedBackground()
    }

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        highlighted ? setSelectedBackground() : setUnselectedBackground()
    }

    private func setSelectedBackground() {
        backgroundColor = AppTheme.default.cellHighlightColor
    }

    private func setUnselectedBackground() {
        backgroundColor = AppTheme.default.backgroundColor
    }

    @objc private func didTapThumbnail(_ sender: Any) {
        postDelegate?.didTapThumbnail(sender)
    }

    func setImageWithPlaceholder(url: URL?) {
        _ = thumbnailImageView.setImageWithPlaceholder(url: url)
    }
}
