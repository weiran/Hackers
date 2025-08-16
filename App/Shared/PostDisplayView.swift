//
//  PostDisplayView.swift
//  Hackers
//
//  Created by Weiran Zhang on SwiftUI Migration.
//  Copyright © 2024 Glass Umbrella. All rights reserved.
//

import SwiftUI

struct PostDisplayView: View {
    let post: Post
    let showVoteButton: Bool
    let showPostText: Bool
    let onVote: (() async -> Void)?
    let onLinkTap: () -> Void
    let onThumbnailTap: (() -> Void)?
    
    init(
        post: Post,
        showVoteButton: Bool = false,
        showPostText: Bool = false,
        onVote: (() async -> Void)? = nil,
        onLinkTap: @escaping () -> Void,
        onThumbnailTap: (() -> Void)? = nil
    ) {
        self.post = post
        self.showVoteButton = showVoteButton
        self.showPostText = showPostText
        self.onVote = onVote
        self.onLinkTap = onLinkTap
        self.onThumbnailTap = onThumbnailTap
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 12) {
                // Thumbnail with proper loading
                ThumbnailView(url: UserDefaults.standard.showThumbnails ? post.url : nil)
                    .frame(width: 55, height: 55)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if showVoteButton {
                            // Comments view - thumbnail taps to open link
                            onLinkTap()
                        } else if let onThumbnailTap = onThumbnailTap {
                            // Feed view - thumbnail has specific tap behavior
                            onThumbnailTap()
                        }
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
                        if showVoteButton {
                            // Only show vote button if we can actually vote/unvote
                            if !post.upvoted || post.voteLinks?.unvote != nil {
                                Button {
                                    Task { await onVote?() }
                                } label: {
                                    HStack(spacing: 0) {
                                        Text("\(post.score)")
                                            .foregroundColor(post.upvoted ? Color(UIColor(named: "upvotedColor")!) : .secondary)
                                        Image(systemName: "arrow.up")
                                            .foregroundColor(post.upvoted ? Color(UIColor(named: "upvotedColor")!) : .secondary)
                                            .font(.caption2)
                                    }
                                }
                            } else {
                                // Show non-interactive vote display when upvoted but no unvote link
                                HStack(spacing: 0) {
                                    Text("\(post.score)")
                                        .foregroundColor(post.upvoted ? Color(UIColor(named: "upvotedColor")!) : .secondary)
                                    Image(systemName: "arrow.up")
                                        .foregroundColor(post.upvoted ? Color(UIColor(named: "upvotedColor")!) : .secondary)
                                        .font(.caption2)
                                }
                            }
                        } else {
                            HStack(spacing: 0) {
                                Text("\(post.score)")
                                    .foregroundColor(post.upvoted ? Color(UIColor(named: "upvotedColor")!) : .secondary)
                                Image(systemName: "arrow.up")
                                    .foregroundColor(post.upvoted ? Color(UIColor(named: "upvotedColor")!) : .secondary)
                                    .font(.caption2)
                            }
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
            .if(showVoteButton) { view in
                view
                    .contentShape(Rectangle())
                    .onTapGesture {
                        // In comments view, the entire content taps to open link
                        onLinkTap()
                    }
            }

            if showPostText, let text = post.text, !text.isEmpty {
                let parsedText = CommentHTMLParser.parseHTMLText(text)
                Text(parsedText)
                    .foregroundColor(.primary)
                    .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct PostContextMenu: View {
    let post: Post
    let onVote: () -> Void
    let onOpenLink: () -> Void
    let onShare: () -> Void

    var body: some View {
        Group {
            if post.upvoted {
                // Only show unvote if unvote link is available
                if post.voteLinks?.unvote != nil {
                    Button {
                        onVote()
                    } label: {
                        Label("Unvote", systemImage: "arrow.uturn.down")
                    }
                }
            } else {
                Button {
                    onVote()
                } label: {
                    Label("Upvote", systemImage: "arrow.up")
                }
            }

            Divider()

            if !post.url.absoluteString.starts(with: "item?id=") {
                Button {
                    onOpenLink()
                } label: {
                    Label("Open Link", systemImage: "safari")
                }
            }

            Button {
                onShare()
            } label: {
                Label("Share", systemImage: "square.and.arrow.up")
            }
        }
    }
}

struct ThumbnailView: View {
    let url: URL?

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

    var body: some View {
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

extension View {
    @ViewBuilder
    func `if`<Transform: View>(_ condition: Bool, transform: (Self) -> Transform) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}