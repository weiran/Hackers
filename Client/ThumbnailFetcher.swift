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
        if let url = URL(string: "http://localhost:3000/?url=" + urlString) {
            self.kf.setImage(with: url, placeholder: placeholderImage, completionHandler: {
                (image, error, cacheType, imageUrl) in
                if image != nil {
                    self.contentMode = .scaleAspectFill
                }
            })
        }
    }
}
