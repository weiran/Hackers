//
//  ThumbnailImageView.swift
//  Hackers
//
//  Created by Weiran Zhang on 16/06/2019.
//  Copyright © 2019 Weiran Zhang. All rights reserved.
//

import UIKit
import Kingfisher

class ThumbnailImageView: UIImageView {
    func setImageWithPlaceholder(url: URL?) -> DownloadTask? {
        setPlaceholder()

        guard let url = url, let thumbnailURL = thumbnailURL(for: url) else {
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
        DispatchQueue.main.async {
            let symbolConfiguration = UIImage.SymbolConfiguration(pointSize: 24, weight: .medium, scale: .large)
            let placeholderImage = UIImage(systemName: "safari", withConfiguration: symbolConfiguration)!
            self.contentMode = .center
            self.image = placeholderImage
        }
    }

    private func thumbnailURL(for url: URL) -> URL? {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "hackers-thumbnails.azurewebsites.net"
        components.path = "/api/FetchThumbnail"
        let urlString = url.absoluteString
        components.queryItems = [URLQueryItem(name: "url", value: urlString)]
        return components.url
    }

    override var intrinsicContentSize: CGSize {
        return CGSize(width: 60, height: 60)
    }
}
