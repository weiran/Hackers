import DesignSystem
import Domain
import Observation
import Shared
import SwiftUI

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

@MainActor
@Observable
public final class CommentsToolbarGeometry {
    public var controlCenterY: CGFloat?
    /// Global frame of the bar title pill, published by the bar so the
    /// custom-browser sheet can mirror it exactly while a drag moves the
    /// title into the sheet layer.
    public var barTitleFrame: CGRect = .zero
    /// True while the custom-browser sheet is being dragged: the in-sheet
    /// capsule owns the title so it can track the finger, and the bar title
    /// steps aside until the drag settles.
    public var isBarTitleSuppressed = false

    public init() {}

    public func updateControlCenterY(_ centerY: CGFloat) {
        guard controlCenterY != centerY else { return }
        controlCenterY = centerY
    }

    public func updateBarTitleFrame(_ frame: CGRect) {
        guard barTitleFrame != frame else { return }
        barTitleFrame = frame
    }

    public func setBarTitleSuppressed(_ suppressed: Bool) {
        guard isBarTitleSuppressed != suppressed else { return }
        isBarTitleSuppressed = suppressed
    }
}

struct ToolbarTitle: View {
    let post: Post
    let showThumbnails: Bool
    let titleVisibility: CommentsHeaderTitleVisibility
    var accessibilityIdentifier: String? = nil
    var isAlwaysHittable: Bool = false
    var barTitleSuppression: CommentsToolbarGeometry? = nil
    let onTap: @MainActor @Sendable () -> Void
    let onDragChanged: ((DragGesture.Value) -> Void)?
    let onDragEnded: ((DragGesture.Value) -> Void)?

    var body: some View {
        CommentsHeaderTitleButton(
            post: post,
            showThumbnails: showThumbnails,
            titleVisibility: titleVisibility,
            accessibilityHint: "Open link",
            accessibilityIdentifier: accessibilityIdentifier,
            isAlwaysHittable: isAlwaysHittable,
            barTitleSuppression: barTitleSuppression,
            onTap: onTap
        )
        .onGeometryChange(for: CGRect.self) { proxy in
            proxy.frame(in: .global)
        } action: { frame in
            DispatchQueue.main.async { @MainActor in
                barTitleSuppression?.updateBarTitleFrame(frame)
            }
        }
        .simultaneousGesture(titleDragGesture)
    }

    private var titleDragGesture: some Gesture {
        DragGesture(minimumDistance: 18, coordinateSpace: .global)
            .onChanged { value in
                onDragChanged?(value)
            }
            .onEnded { value in
                onDragEnded?(value)
            }
    }
}

public struct CommentsHeaderTitleButton: View {
    private let post: Post
    private let showThumbnails: Bool
    private let titleVisibility: CommentsHeaderTitleVisibility
    private let accessibilityHint: String
    private let accessibilityIdentifier: String?
    private let isAlwaysHittable: Bool
    private let barTitleSuppression: CommentsToolbarGeometry?
    private let hitHeight: CGFloat
    private let fillsAvailableWidth: Bool
    private let usesOffsetTransition: Bool
    private let onTap: @MainActor @Sendable () -> Void

    public init(
        post: Post,
        showThumbnails: Bool,
        titleVisibility: CommentsHeaderTitleVisibility,
        accessibilityHint: String,
        accessibilityIdentifier: String? = nil,
        isAlwaysHittable: Bool = false,
        barTitleSuppression: CommentsToolbarGeometry? = nil,
        hitHeight: CGFloat = 44,
        fillsAvailableWidth: Bool = false,
        usesOffsetTransition: Bool = true,
        onTap: @escaping @MainActor @Sendable () -> Void
    ) {
        self.post = post
        self.showThumbnails = showThumbnails
        self.titleVisibility = titleVisibility
        self.accessibilityHint = accessibilityHint
        self.accessibilityIdentifier = accessibilityIdentifier
        self.isAlwaysHittable = isAlwaysHittable
        self.barTitleSuppression = barTitleSuppression
        self.hitHeight = hitHeight
        self.fillsAvailableWidth = fillsAvailableWidth
        self.usesOffsetTransition = usesOffsetTransition
        self.onTap = onTap
    }

    public var body: some View {
        let isVisible = titleVisibility.isVisible
        let isBarTitleShown = isVisible && !(barTitleSuppression?.isBarTitleSuppressed ?? false)
        let maxWidth: CGFloat? = fillsAvailableWidth ? .infinity : nil

        Button(action: onTap) {
            ZStack {
                CommentsHeaderTitlePillContent(post: post, showThumbnails: showThumbnails)
                    .hidden()
                    .accessibilityHidden(true)

                if isBarTitleShown {
                    CommentsHeaderTitlePill(post: post, showThumbnails: showThumbnails)
                        .transition(usesOffsetTransition ? Self.visibilityTransition : .opacity)
                }
            }
            .frame(maxWidth: maxWidth, alignment: .top)
            .frame(height: hitHeight, alignment: .top)
        }
        .buttonStyle(.plain)
        .allowsHitTesting(isVisible || isAlwaysHittable)
        .disabled(!isVisible && !isAlwaysHittable)
        .accessibilityLabel(post.title)
        .accessibilityHint(accessibilityHint)
        .if(accessibilityIdentifier != nil) { view in
            view.accessibilityIdentifier(accessibilityIdentifier ?? "")
        }
        .accessibilityHidden(!isVisible)
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
        CommentsHeaderTitlePillContent(post: post, showThumbnails: showThumbnails)
            .contentShape(.capsule)
            .glassEffect(.regular.interactive(), in: .capsule)
    }
}

public struct CommentsHeaderTitlePillContent: View {
    private let post: Post
    private let showThumbnails: Bool
    private let maximumWidth: CGFloat?

    public init(post: Post, showThumbnails: Bool, maximumWidth: CGFloat? = nil) {
        self.post = post
        self.showThumbnails = showThumbnails
        self.maximumWidth = maximumWidth
    }

    public var body: some View {
        WidthCappedLayout(maximumWidth: maximumWidth) {
            titleContent
                .padding(.leading, 14)
                .padding(.trailing, 10)
                .padding(.vertical, 5)
        }
        .frame(height: 44)
    }

    private var titleContent: some View {
        HStack(spacing: 7) {
            ThumbnailView(
                url: post.url,
                isEnabled: showThumbnails,
                showsPlaceholder: showThumbnails,
                thumbnailSize: CGSize(width: 24, height: 24)
            )
                .clipShape(.rect(cornerRadius: 7))
            Text(post.title)
                .scaledFont(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .truncationMode(.tail)
        }
    }
}

private struct WidthCappedLayout: Layout {
    let maximumWidth: CGFloat?

    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) -> CGSize {
        guard let subview = subviews.first else { return .zero }

        let idealSize = subview.sizeThatFits(.unspecified)
        let proposedWidth = proposal.width ?? .greatestFiniteMagnitude
        let cappedWidth = min(proposedWidth, maximumWidth ?? .greatestFiniteMagnitude)
        let width = min(idealSize.width, cappedWidth)
        let fittedSize = subview.sizeThatFits(.init(width: width, height: proposal.height))
        return CGSize(width: width, height: fittedSize.height)
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) {
        subviews.first?.place(
            at: bounds.origin,
            anchor: .topLeading,
            proposal: .init(width: bounds.width, height: bounds.height)
        )
    }
}

struct ShareMenu: View {
    let post: Post
    var toolbarGeometry: CommentsToolbarGeometry?

    var body: some View {
        Button {
            ContentSharePresenter.shared.shareHackerNewsPost(post)
        } label: {
            Label("Share", systemImage: "square.and.arrow.up")
                .labelStyle(.iconOnly)
                .onGeometryChange(for: CGFloat.self) { proxy in
                    proxy.frame(in: .global).midY
                } action: { centerY in
                    // Geometry callbacks run during view updates. Defer the
                    // observable mutation to the next main-actor turn so
                    // toolbar presentation does not publish recursively.
                    DispatchQueue.main.async { @MainActor in
                        toolbarGeometry?.updateControlCenterY(centerY)
                    }
                }
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
