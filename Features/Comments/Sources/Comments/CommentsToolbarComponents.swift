import DesignSystem
import Domain
import Observation
import Shared
import SwiftUI
import UIKit

@MainActor
@Observable
public final class CommentsHeaderTitleVisibility {
    public var isVisible: Bool

    public init(isVisible: Bool = false) {
        self.isVisible = isVisible
    }

    public func setVisible(_ isVisible: Bool) {
        guard self.isVisible != isVisible else { return }
        self.isVisible = isVisible
    }
}

struct ToolbarTitle: View {
    let post: Post
    let showThumbnails: Bool
    let titleVisibility: CommentsHeaderTitleVisibility
    let onTap: @MainActor @Sendable () -> Void

    var body: some View {
        CommentsHeaderTitleButton(
            post: post,
            showThumbnails: showThumbnails,
            titleVisibility: titleVisibility,
            accessibilityHint: "Open link",
            onTap: onTap
        )
    }
}

public struct CommentsHeaderTitleButton: View {
    private let post: Post
    private let showThumbnails: Bool
    private let titleVisibility: CommentsHeaderTitleVisibility
    private let accessibilityHint: String
    private let hitHeight: CGFloat
    private let fillsAvailableWidth: Bool
    private let usesOffsetTransition: Bool
    private let visualHitAlignmentOffset: CGFloat
    private let onTap: @MainActor @Sendable () -> Void

    public init(
        post: Post,
        showThumbnails: Bool,
        titleVisibility: CommentsHeaderTitleVisibility,
        accessibilityHint: String,
        hitHeight: CGFloat = 44,
        fillsAvailableWidth: Bool = false,
        usesOffsetTransition: Bool = true,
        visualHitAlignmentOffset: CGFloat = 4,
        onTap: @escaping @MainActor @Sendable () -> Void
    ) {
        self.post = post
        self.showThumbnails = showThumbnails
        self.titleVisibility = titleVisibility
        self.accessibilityHint = accessibilityHint
        self.hitHeight = hitHeight
        self.fillsAvailableWidth = fillsAvailableWidth
        self.usesOffsetTransition = usesOffsetTransition
        self.visualHitAlignmentOffset = visualHitAlignmentOffset
        self.onTap = onTap
    }

    public var body: some View {
        let isVisible = titleVisibility.isVisible
        let maxWidth: CGFloat? = fillsAvailableWidth ? .infinity : nil

        ZStack {
            CommentsHeaderTitlePillLayout(post: post, showThumbnails: showThumbnails)
                .hidden()
                .accessibilityHidden(true)
                .offset(y: visualHitAlignmentOffset)

            if isVisible {
                CommentsHeaderTitlePill(post: post, showThumbnails: showThumbnails)
                    .transition(usesOffsetTransition ? Self.visibilityTransition : .opacity)
                    .offset(y: visualHitAlignmentOffset)
            }

            // Keep tap handling above the interactive glass pill, and align the
            // visible glass with the toolbar's real hit frame. Otherwise the top
            // pixels can visually react without delivering the tap action.
            CommentsHeaderTitleTapOverlay(onTap: onTap)
                .allowsHitTesting(isVisible)
                .accessibilityHidden(true)
        }
        .frame(maxWidth: maxWidth, alignment: .top)
        .frame(height: hitHeight, alignment: .top)
        .contentShape(.interaction, Rectangle())
        .allowsHitTesting(isVisible)
        .accessibilityLabel(post.title)
        .accessibilityAddTraits(.isButton)
        .accessibilityHint(accessibilityHint)
        .accessibilityHidden(!isVisible)
        .accessibilityAction(.default, onTap)
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
        CommentsHeaderTitlePillLayout(post: post, showThumbnails: showThumbnails)
            .contentShape(.capsule)
            .glassEffect(.regular.interactive(), in: .capsule)
    }
}

private struct CommentsHeaderTitlePillLayout: View {
    private static let wrappedTitleWidth: CGFloat = 170
    let post: Post
    let showThumbnails: Bool

    var body: some View {
        ViewThatFits(in: .horizontal) {
            titleContent(font: .subheadline, lineLimit: 1, titleWidth: nil)
                .fixedSize(horizontal: true, vertical: false)

            titleContent(font: .caption, lineLimit: 2, titleWidth: Self.wrappedTitleWidth)
        }
        .padding(.leading, 14)
        .padding(.trailing, 10)
        .padding(.vertical, 5)
        .frame(height: 44)
    }

    private func titleContent(font: Font, lineLimit: Int, titleWidth: CGFloat?) -> some View {
        HStack(spacing: 7) {
            ThumbnailView(
                url: post.url,
                isEnabled: showThumbnails,
                showsPlaceholder: false,
                thumbnailSize: CGSize(width: 24, height: 24)
            )
                .clipShape(.rect(cornerRadius: 7))
            Text(post.title)
                .scaledFont(font)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
                .lineLimit(lineLimit)
                .multilineTextAlignment(.leading)
                .truncationMode(.tail)
                .frame(width: titleWidth, alignment: .leading)
        }
    }
}

private struct CommentsHeaderTitleTapOverlay: UIViewRepresentable {
    let onTap: @MainActor () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onTap: onTap)
    }

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = true
        view.isAccessibilityElement = false

        let tapGesture = UITapGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleTap)
        )
        tapGesture.cancelsTouchesInView = false
        tapGesture.delaysTouchesBegan = false
        tapGesture.delaysTouchesEnded = false
        view.addGestureRecognizer(tapGesture)

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.onTap = onTap
    }

    @MainActor
    final class Coordinator: NSObject {
        var onTap: @MainActor () -> Void

        init(onTap: @escaping @MainActor () -> Void) {
            self.onTap = onTap
        }

        @objc func handleTap() {
            onTap()
        }
    }
}

struct ShareMenu: View {
    let post: Post

    var body: some View {
        Button {
            ContentSharePresenter.shared.shareHackerNewsPost(post)
        } label: {
            Label("Share", systemImage: "square.and.arrow.up")
                .labelStyle(.iconOnly)
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
