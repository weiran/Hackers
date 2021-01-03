//
//  ThumbnailImageView.swift
//  Hackers
//
//  Created by Weiran Zhang on 16/06/2019.
//  Copyright © 2019 Weiran Zhang. All rights reserved.
//

import UIKit
import Nuke

class ThumbnailImageView: UIImageView {
    private lazy var placeholderImage: UIImage = getPlaceholderImage()

    func setImageWithPlaceholder(url: URL?) -> ImageRequest? {
        guard
            let url = url,
            let thumbnailURL = thumbnailURL(for: url)
        else {
            image = placeholderImage
            contentMode = .center
            return nil
        }

        let options = ImageLoadingOptions(
            placeholder: placeholderImage,
            contentModes: .init(
                success: .scaleAspectFill,
                failure: .center,
                placeholder: .center
            )
        )

        let request = ImageRequest(url: thumbnailURL)
        Nuke.loadImage(with: request, options: options, into: self)

        return request
    }

    private func getPlaceholderImage() -> UIImage {
        let symbolConfiguration = UIImage.SymbolConfiguration(pointSize: 24, weight: .medium, scale: .large)
        return UIImage(systemName: "safari", withConfiguration: symbolConfiguration)!
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
}
