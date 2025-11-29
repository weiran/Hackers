//
//  ThumbnailView.swift
//  DesignSystem
//
//  Copyright © 2025 Weiran Zhang. All rights reserved.
//

import SwiftUI

public struct ThumbnailView: View {
    let url: URL?
    let isEnabled: Bool

    public init(url: URL?, isEnabled: Bool = true) {
        self.url = url
        self.isEnabled = isEnabled
    }

    private func thumbnailURL(for url: URL) -> URL? {
        guard let host = url.host else { return nil }
        var components = URLComponents()
        components.scheme = "https"
        components.host = "www.google.com"
        components.path = "/s2/favicons"
        components.queryItems = [
            URLQueryItem(name: "domain", value: host),
            URLQueryItem(name: "sz", value: "128")
        ]
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
        if isEnabled, let url, let thumbnailURL = thumbnailURL(for: url) {
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
