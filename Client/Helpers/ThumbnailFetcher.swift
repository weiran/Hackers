//
//  ThumbnailFetcher.swift
//  Hackers
//
//  Created by Weiran Zhang on 18/12/2017.
//  Copyright © 2017 Glass Umbrella. All rights reserved.
//

import Kingfisher

extension UIImageView {
    func setImageWithPlaceholder(url: URL?) {
        let placeholderImage = UIImage(named: "ThumbnailPlaceholderIcon")?.withRenderingMode(.alwaysTemplate)
        self.image = placeholderImage
        if let url = url, let thumbnailURL = URL(string: "https://image-extractor.now.sh/?url=" + url.absoluteString) {
            self.kf.setImage(with: thumbnailURL, placeholder: placeholderImage)
        }
    }
}
