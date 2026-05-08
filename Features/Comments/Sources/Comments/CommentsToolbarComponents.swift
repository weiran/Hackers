import DesignSystem
import Domain
import ProgressiveBlurHeader
import Shared
import SwiftUI
import VariableBlur

public struct ProgressiveHeaderBlurBackground: View {
    private let height: CGFloat
    private let fadeExtension: CGFloat
    private let maxBlurRadius: CGFloat
    private let tintOpacityTop: Double
    private let tintOpacityMiddle: Double
    @Environment(\.colorScheme) private var colorScheme

    public init(
        height: CGFloat,
        fadeExtension: CGFloat = 64,
        maxBlurRadius: CGFloat = 5,
        tintOpacityTop: Double = 0.7,
        tintOpacityMiddle: Double = 0.5
    ) {
        self.height = height
        self.fadeExtension = fadeExtension
        self.maxBlurRadius = maxBlurRadius
        self.tintOpacityTop = tintOpacityTop
        self.tintOpacityMiddle = tintOpacityMiddle
    }

    public var body: some View {
        let totalHeight = max(height + fadeExtension, 1)

        VariableBlurView(
            maxBlurRadius: maxBlurRadius,
            direction: .blurredTopClearBottom
        )
        .overlay {
            LinearGradient(
                stops: [
                    .init(color: fadeTint.opacity(tintOpacityTop), location: 0),
                    .init(color: fadeTint.opacity(tintOpacityMiddle), location: min(90 / totalHeight, 1)),
                    .init(color: fadeTint.opacity(0), location: 1)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .frame(height: totalHeight)
        .ignoresSafeArea(edges: .top)
        .allowsHitTesting(false)
    }

    private var fadeTint: Color {
        colorScheme == .dark ? .black : .white
    }
}

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
