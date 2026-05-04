import DesignSystem
import Domain
import Shared
import SwiftUI

struct ToolbarTitle: View {
    let post: Post
    let showTitle: Bool
    let showThumbnails: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                ThumbnailView(url: post.url, isEnabled: showThumbnails)
                    .frame(width: 33, height: 33)
                    .clipShape(.rect(cornerRadius: 10))
                Text(post.title)
                    .scaledFont(.headline)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(.isButton)
        .accessibilityHint("Open link")
        .opacity(showTitle ? 1.0 : 0.0)
        .offset(y: showTitle ? 0 : 20)
        .animation(.easeInOut(duration: 0.3), value: showTitle)
    }
}

struct BookmarkToolbarButton: View {
    let isBookmarked: Bool
    let toggleBookmark: @Sendable () async -> Bool
    @State private var isSubmitting = false

    var body: some View {
        Button {
            guard !isSubmitting else { return }
            isSubmitting = true
            Task { @MainActor in
                _ = await toggleBookmark()
                isSubmitting = false
            }
        } label: {
            Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
        }
        .accessibilityLabel(isBookmarked ? "Remove Bookmark" : "Save Bookmark")
        .accessibilityHint(
            isBookmarked
                ? "Double-tap to remove from bookmarks"
                : "Double-tap to add to bookmarks"
        )
        .disabled(isSubmitting)
    }
}

struct ShareMenu: View {
    let post: Post

    var body: some View {
        Button {
            ContentSharePresenter.shared.shareURL(post.hackerNewsURL, title: post.title)
        } label: {
            Image(systemName: "square.and.arrow.up")
                .accessibilityLabel("Share")
        }
    }
}

struct LoadingView: View {
    var body: some View {
        AppLoadingStateView(message: "Loading...")
    }
}

struct EmptyCommentsView: View {
    var body: some View {
        AppEmptyStateView(iconSystemName: "bubble.left", title: "No comments yet")
    }
}

struct ViewOffsetKey: PreferenceKey {
    typealias Value = CGFloat
    static let defaultValue = CGFloat.zero
    static func reduce(value: inout Value, nextValue: () -> Value) {
        value += nextValue()
    }
}

struct CommentPositionsPreferenceKey: PreferenceKey {
    typealias Value = [Int: CGRect]
    static let defaultValue: [Int: CGRect] = [:]
    static func reduce(value: inout Value, nextValue: () -> Value) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}

extension View {
    func plainListRow() -> some View {
        listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets())
    }
}
