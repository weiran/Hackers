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
        CommentsHeaderTitleButton(
            post: post,
            showThumbnails: showThumbnails,
            isVisible: showTitle,
            accessibilityHint: "Open link",
            onTap: onTap
        )
    }
}

public struct CommentsHeaderTitleButton: View {
    private let post: Post
    private let showThumbnails: Bool
    private let isVisible: Bool
    private let accessibilityHint: String
    private let onTap: () -> Void

    public init(
        post: Post,
        showThumbnails: Bool,
        isVisible: Bool,
        accessibilityHint: String,
        onTap: @escaping () -> Void
    ) {
        self.post = post
        self.showThumbnails = showThumbnails
        self.isVisible = isVisible
        self.accessibilityHint = accessibilityHint
        self.onTap = onTap
    }

    public var body: some View {
        ZStack {
            Color.clear
                .frame(height: 44)

            if isVisible {
                Button(action: onTap) {
                    CommentsHeaderTitlePill(post: post, showThumbnails: showThumbnails)
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(.isButton)
                .accessibilityHint(accessibilityHint)
                .transition(Self.visibilityTransition)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: isVisible)
    }

    private static var visibilityTransition: AnyTransition {
        .asymmetric(
            insertion: .opacity.combined(with: .offset(y: 20)),
            removal: .opacity.combined(with: .offset(y: 20))
        )
    }
}

public struct CommentsHeaderTitlePill: View {
    private let post: Post
    private let showThumbnails: Bool

    public init(post: Post, showThumbnails: Bool) {
        self.post = post
        self.showThumbnails = showThumbnails
    }

    public var body: some View {
        HStack(spacing: 7) {
            ThumbnailView(url: post.url, isEnabled: showThumbnails)
                .frame(width: 24, height: 24)
                .clipShape(.rect(cornerRadius: 7))
            Text(post.title)
                .scaledFont(.subheadline)
                .fontWeight(.semibold)
                .lineLimit(1)
                .truncationMode(.tail)
        }
        .padding(.leading, 5)
        .padding(.trailing, 10)
        .padding(.vertical, 5)
        .frame(height: 44)
        .contentShape(.capsule)
        .glassEffect(.regular.interactive(), in: .capsule)
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

extension View {
    func plainListRow() -> some View {
        listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets())
    }
}
