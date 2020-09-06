//
//  FeedItemCell.swift
//  Hackers
//
//  Created by Weiran Zhang on 06/07/2020.
//  Copyright © 2020 Weiran Zhang. All rights reserved.
//

import UIKit

class FeedItemCell: UICollectionViewListCell {
    @IBOutlet var postTitleView: PostTitleView!
    @IBOutlet var thumbnailImageView: ThumbnailImageView!

    var linkPressedHandler: ((Post) -> Void)?

    override func layoutSubviews() {
        super.layoutSubviews()

        setupTheming()
        setupThumbnailGesture()
    }

    override func updateConstraints() {
        super.updateConstraints()

        separatorLayoutGuide.leadingAnchor.constraint(
            equalTo: postTitleView.leadingAnchor
        ).isActive = true
    }

    private func setupThumbnailGesture() {
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTapThumbnail(_:)))
        thumbnailImageView.addGestureRecognizer(tapGestureRecognizer)
    }

    @objc private func didTapThumbnail(_ sender: Any) {
        if let linkPressedHandler = linkPressedHandler,
           let post = postTitleView.post {
            linkPressedHandler(post)
        }
    }

    func setImageWithPlaceholder(url: URL?) {
        thumbnailImageView.setImageWithPlaceholder(url: url)
    }

    func setPost(post: Post) {
        postTitleView.post = post
    }
}

extension FeedItemCell: Themed {
    func applyTheme(_ theme: AppTheme) {
        thumbnailImageView.backgroundColor = theme.groupedTableViewBackgroundColor
        overrideUserInterfaceStyle = theme.userInterfaceStyle
    }
}
