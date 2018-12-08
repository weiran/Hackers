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
        if let url = URL(string: "https://image-extractor.now.sh/?url=" + urlString) {
            let deviceScale = UIScreen.main.scale
            let thumbnailSize = 60 * deviceScale
            let imageSizeProcessor = ResizingImageProcessor(referenceSize: CGSize(width: thumbnailSize, height: thumbnailSize), mode: .aspectFit)
            self.kf.setImage(with: url, placeholder: placeholderImage, options: [.processor(imageSizeProcessor)])
        }
    }
}
