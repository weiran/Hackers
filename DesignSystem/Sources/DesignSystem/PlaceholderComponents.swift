import SwiftUI
import Domain

// These are placeholder components that will be migrated from the main app
// They allow the Comments feature module to compile independently

public struct PostDisplayView: View {
    let post: Post
    let showPostText: Bool
    let onThumbnailTap: (() -> Void)?

    public init(
        post: Post,
        showPostText: Bool = false,
        onThumbnailTap: (() -> Void)? = nil
    ) {
        self.post = post
        self.showPostText = showPostText
        self.onThumbnailTap = onThumbnailTap
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 12) {
                // Thumbnail
                ThumbnailView(url: post.url)
                    .frame(width: 55, height: 55)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .contentShape(Rectangle())
                    .onTapGesture {
                        onThumbnailTap?()
                    }

                VStack(alignment: .leading, spacing: 4) {
                    // Title
                    Text(post.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    // Metadata row
                    HStack(spacing: 3) {
                        HStack(spacing: 0) {
                            Text("\(post.score)")
                                .foregroundColor(post.upvoted ? Color("upvotedColor") : .secondary)
                            Image(systemName: "arrow.up")
                                .foregroundColor(post.upvoted ? Color("upvotedColor") : .secondary)
                                .font(.caption2)
                        }

                        Text("•")
                            .foregroundColor(.secondary)

                        HStack(spacing: 0) {
                            Text("\(post.commentsCount)")
                                .foregroundColor(.secondary)
                            Image(systemName: "message")
                                .foregroundColor(.secondary)
                                .font(.caption2)
                        }

                        if let host = post.url.host, !post.url.absoluteString.starts(with: "item?id=") {
                            Text("•")
                                .foregroundColor(.secondary)
                            Text(host)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    }
                    .font(.subheadline)
                }
            }

            if showPostText, let text = post.text, !text.isEmpty {
                Text(text)
                    .foregroundColor(.primary)
                    .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

public struct PostContextMenu: View {
    let post: Post
    let onVote: () -> Void
    let onOpenLink: () -> Void
    let onShare: () -> Void

    public init(
        post: Post,
        onVote: @escaping () -> Void,
        onOpenLink: @escaping () -> Void,
        onShare: @escaping () -> Void
    ) {
        self.post = post
        self.onVote = onVote
        self.onOpenLink = onOpenLink
        self.onShare = onShare
    }

    public var body: some View {
        Group {
            Button("Vote", action: onVote)
            Button("Open Link", action: onOpenLink)
            Button("Share", action: onShare)
        }
    }
}

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
        } else {
            placeholderImage
        }
    }
}

// Authentication dialog removed temporarily to avoid conflicts with existing implementation
