//
//  ThumbnailFetcher.swift
//  Hackers
//
//  Created by Weiran Zhang on 18/12/2017.
//  Copyright © 2017 Glass Umbrella. All rights reserved.
//

import Kingfisher

extension UIImageView {
    func setImageWithPlaceholder(urlString: String) {
        let placeholderImage = UIImage(named: "ThumbnailPlaceholderIcon")?.withRenderingMode(.alwaysTemplate)
        self.image = placeholderImage
        if let url = URL(string: "https://image-extractor.now.sh/?url=" + urlString) {
            self.kf.setImage(with: url, placeholder: placeholderImage)
        }
    }
}
