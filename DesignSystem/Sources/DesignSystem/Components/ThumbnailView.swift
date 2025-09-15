//
//  ThumbnailView.swift
//  DesignSystem
//
//  Copyright © 2025 Weiran Zhang. All rights reserved.
//

import SwiftUI

public struct ThumbnailView: View {
    let url: URL?

    public init(url: URL?) {
        self.url = url
    }

    private func thumbnailURL(for url: URL) -> URL? {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "hackers-thumbnails.weiranzhang.com"
        components.path = "/api/FetchThumbnail"
        let urlString = url.absoluteString
        components.queryItems = [URLQueryItem(name: "url", value: urlString)]
        return components.url
    }

    private var placeholderImage: some View {
        Image(systemName: "safari")
            .font(.title2)
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.secondary.opacity(0.1))
    }

    public var body: some View {
        if let url = url, let thumbnailURL = thumbnailURL(for: url) {
            AsyncImage(url: thumbnailURL) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                placeholderImage
            }
            .accessibilityHidden(true)
        } else {
            placeholderImage
                .accessibilityHidden(true)
        }
    }
}
