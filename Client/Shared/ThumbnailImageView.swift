//
//  ThumbnailImageView.swift
//  Hackers
//
//  Created by Weiran Zhang on 16/06/2019.
//  Copyright © 2019 Glass Umbrella. All rights reserved.
//

import UIKit
import Kingfisher

class ThumbnailImageView: UIImageView {
    public func setImageWithPlaceholder(url: URL?) -> DownloadTask? {
        setPlaceholder()

        guard let url = url,
            let thumbnailURL = URL(string: "https://image-extractor.now.sh/?url=\(url.absoluteString)") else {
                return nil
        }

        let newSize = 60
        let thumbnailSize = CGFloat(newSize) * UIScreen.main.scale
        let thumbnailCGSize = CGSize(width: thumbnailSize, height: thumbnailSize)
        let imageSizeProcessor = ResizingImageProcessor(referenceSize: thumbnailCGSize,
                                                        mode: .aspectFill)
        let options: KingfisherOptionsInfo = [
            .processor(imageSizeProcessor)
        ]

        let resource = ImageResource(downloadURL: thumbnailURL)

        let task = KingfisherManager.shared.retrieveImage(with: resource, options: options) { result in
            switch result {
            case .success(let imageResult):
                DispatchQueue.main.async {
                    self.contentMode = .scaleAspectFill
                    self.image = imageResult.image
                }
            default: break
            }
        }

        return task
    }

    private func setPlaceholder() {
        let symbolConfiguration = UIImage.SymbolConfiguration(pointSize: 24, weight: .medium, scale: .large)
        let placeholderImage = UIImage(systemName: "safari", withConfiguration: symbolConfiguration)!
        DispatchQueue.main.async {
            self.contentMode = .center
            self.image = placeholderImage
        }
    }

    private func resizeImage(image: UIImage, targetSize: CGSize) -> UIImage {
        let size = image.size

        let widthRatio  = targetSize.width  / size.width
        let heightRatio = targetSize.height / size.height

        // Figure out what our orientation is, and use that to form the rectangle
        var newSize: CGSize
        if widthRatio > heightRatio {
            newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
        } else {
            newSize = CGSize(width: size.width * widthRatio, height: size.height * widthRatio)
        }

        // This is the rect that we've calculated out and this is what is actually used below
        let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)

        // Actually do the resizing to the rect using the ImageContext stuff
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return newImage!
    }

    override var intrinsicContentSize: CGSize {
        return CGSize(width: 60, height: 60)
    }
}
