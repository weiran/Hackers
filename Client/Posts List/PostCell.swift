//
//  PostCell.swift
//  Hackers2
//
//  Created by Weiran Zhang on 07/06/2014.
//  Copyright (c) 2014 Glass Umbrella. All rights reserved.
//

import Foundation
import UIKit

protocol PostCellDelegate {
    func didTapThumbnail(_ sender: Any)
}

class PostCell : UITableViewCell {
    var post: HNPost?
    var delegate: PostCellDelegate?
    
    @IBOutlet weak var postTitleView: PostTitleView!
    @IBOutlet weak var thumbnailImageView: UIImageView!

    override func awakeFromNib() {
        super.awakeFromNib()
        contentView.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(PostCell.cellLongPress)))
    }

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
    
    func setSelectedBackground() {
        backgroundColor = AppThemeProvider.shared.currentTheme.cellHighlightColor
    }
    
    func setUnselectedBackground() {
        backgroundColor = AppThemeProvider.shared.currentTheme.backgroundColor
    }
    
    func clearImage() {
        let placeholder = UIImage(named: "ThumbnailPlaceholderIcon")?.withRenderingMode(.alwaysTemplate)
        thumbnailImageView.image = placeholder
    }
    
    @objc func didTapThumbnail(_ sender: Any) {
        delegate?.didTapThumbnail(sender)
    }

    @objc func cellLongPress() {
        if let post = post {
            let alertController = UIAlertController(title: "Share...", message: nil, preferredStyle: .actionSheet)
            let postURLAction = UIAlertAction(title: "Content Link", style: .default) { action in
                let linkVC = post.LinkActivityViewController
                UIApplication.shared.keyWindow?.rootViewController?.present(linkVC, animated: true, completion: nil)
            }
            let hackerNewsURLAction = UIAlertAction(title: "Hacker News Link", style: .default) { action in
                let commentsVC = post.CommentsActivityViewController
                UIApplication.shared.keyWindow?.rootViewController?.present(commentsVC, animated: true, completion: nil)
            }
            alertController.addAction(postURLAction)
            alertController.addAction(hackerNewsURLAction)
            alertController.addAction(UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel, handler: nil))

            UIApplication.shared.keyWindow?.rootViewController?.present(alertController,
                                                                        animated: true, completion: nil)
        }
    }
}

extension PostCell: Themed {
    func applyTheme(_ theme: AppTheme) {
        backgroundColor = theme.backgroundColor
    }
}
