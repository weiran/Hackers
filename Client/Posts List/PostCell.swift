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
    var delegate: PostCellDelegate?
    
    @IBOutlet weak var postTitleView: PostTitleView!
    @IBOutlet weak var thumbnailImageView: UIImageView!
    
    var cancelThumbnailTask: (() -> Void)?
    
    override func layoutSubviews() {
        super.layoutSubviews()
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
        backgroundColor = Theme.backgroundPurpleColour
    }
    
    func setUnselectedBackground() {
        backgroundColor = UIColor.clear
    }
    
    func clearImage() {
        let placeholder = UIImage(named: "ThumbnailPlaceholderIcon")?.withRenderingMode(.alwaysTemplate)
        thumbnailImageView.image = placeholder
        thumbnailImageView.contentMode = .center
    }
    
    @objc func didTapThumbnail(_ sender: Any) {
        delegate?.didTapThumbnail(sender)
    }
}
