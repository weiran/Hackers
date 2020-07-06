//
//  FeedItemCell.swift
//  Hackers
//
//  Created by Weiran Zhang on 06/07/2020.
//  Copyright © 2020 Weiran Zhang. All rights reserved.
//

import UIKit
import Kingfisher

class FeedItemCell: UICollectionViewListCell {
    @IBOutlet var thumbnailImageView: ThumbnailImageView!
    @IBOutlet var postTitleView: PostTitleView!

    private var thumbnailDownloadTask: DownloadTask?

    var linkPressedHandler: ((Post) -> Void)?

    override func layoutSubviews() {
        super.layoutSubviews()

        setupTheming()
        setupThumbnailGesture()
    }

    override func updateConstraints() {
        super.updateConstraints()

        separatorLayoutGuide.leadingAnchor.constraint(
            equalTo: postTitleView.leadingAnchor).isActive = true
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
        thumbnailDownloadTask = thumbnailImageView.setImageWithPlaceholder(url: url)
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        thumbnailDownloadTask?.cancel()
    }
}

extension FeedItemCell: Themed {
    func applyTheme(_ theme: AppTheme) {
        thumbnailImageView.backgroundColor = theme.groupedTableViewBackgroundColor
        overrideUserInterfaceStyle = theme.userInterfaceStyle
    }
}
