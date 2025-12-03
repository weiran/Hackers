//
//  ThumbnailView.swift
//  DesignSystem
//
//  Copyright © 2025 Weiran Zhang. All rights reserved.
//

import CoreGraphics
import ImageIO
import SwiftUI

public struct ThumbnailView: View {
    let url: URL?
    let isEnabled: Bool

    @State private var image: Image?

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

    private func loadThumbnail(from thumbnailURL: URL) async {
        await MainActor.run {
            image = nil
        }

        var request = URLRequest(url: thumbnailURL)
        request.cachePolicy = .returnCacheDataElseLoad

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            // Google responds with 404 when it serves its own fallback icon; treat that as missing.
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else { return }

            guard let cgImage = cgImage(from: data) else { return }
            let swiftUIImage = Image(decorative: cgImage, scale: 1, orientation: .up)

            await MainActor.run {
                image = swiftUIImage
            }
        } catch {
            await MainActor.run {
                image = nil
            }
        }
    }

    private func cgImage(from data: Data) -> CGImage? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
        return CGImageSourceCreateImageAtIndex(source, 0, nil)
    }

    public var body: some View {
        if isEnabled, let url, let thumbnailURL = thumbnailURL(for: url) {
            ZStack {
                if let image {
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    placeholderImage
                }
            }
            .task(id: thumbnailURL) {
                await loadThumbnail(from: thumbnailURL)
            }
            .accessibilityHidden(true)
        } else {
            placeholderImage
                .accessibilityHidden(true)
        }
    }
}
