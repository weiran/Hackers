//
//  PostDisplayView.swift
//  DesignSystem
//
//  Reusable post display component
//

import SwiftUI
import Domain
import Shared

public struct PostDisplayView: View {
    let post: Post
    let showPostText: Bool
    let showThumbnails: Bool
    let onThumbnailTap: (() -> Void)?

    public init(
        post: Post,
        showPostText: Bool = false,
        showThumbnails: Bool = true,
        onThumbnailTap: (() -> Void)? = nil
    ) {
        self.post = post
        self.showPostText = showPostText
        self.showThumbnails = showThumbnails
        self.onThumbnailTap = onThumbnailTap
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 12) {
                // Thumbnail with proper loading
                if showThumbnails {
                    ThumbnailView(url: post.url)
                        .frame(width: 55, height: 55)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .contentShape(Rectangle())
                        .highPriorityGesture(
                            TapGesture()
                                .onEnded { _ in
                                    onThumbnailTap?()
                                }
                        )
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
                        // Always show non-interactive vote display (voting only via swipe gestures)
                        HStack(spacing: 0) {
                            Text("\(post.score)")
                                .foregroundColor(post.upvoted ? AppColors.upvoted : .secondary)
                            Image(systemName: "arrow.up")
                                .foregroundColor(post.upvoted ? AppColors.upvoted : .secondary)
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

                        if let host = post.url.host,
                           !post.url.absoluteString.starts(with: HackerNewsConstants.itemPrefix) {
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

            if !post.url.absoluteString.starts(with: HackerNewsConstants.itemPrefix) {
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
