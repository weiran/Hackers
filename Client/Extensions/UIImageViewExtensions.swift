//
//  ThumbnailFetcher.swift
//  Hackers
//
//  Created by Weiran Zhang on 18/12/2017.
//  Copyright © 2017 Glass Umbrella. All rights reserved.
//

import Kingfisher

extension UIImageView {
    func setImageWithPlaceholder(url: URL?, resizeToSize: Int? = nil) {
        let placeholderImage = UIImage(named: "ThumbnailPlaceholderIcon")?.withRenderingMode(.alwaysTemplate)
        self.image = placeholderImage
        if let url = url, let thumbnailURL = URL(string: "https://image-extractor.now.sh/?url=" + url.absoluteString) {
            var options: KingfisherOptionsInfo?
            if let resizeToSize = resizeToSize {
                let thumbnailSize = CGFloat(resizeToSize) * UIScreen.main.scale
                let imageSizeProcessor = ResizingImageProcessor(referenceSize: CGSize(width: thumbnailSize, height: thumbnailSize), mode: .aspectFit)
                options = [.processor(imageSizeProcessor)]
            }
            self.kf.setImage(with: thumbnailURL, placeholder: placeholderImage, options: options)
        }
    }
}
