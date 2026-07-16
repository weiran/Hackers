import Comments
import DesignSystem
import Domain
import Shared
import SwiftUI

struct BrowserControlsView: View {
    let fallbackURL: URL
    let onDismiss: @MainActor () -> Void
    @ObservedObject var controller: BrowserController

    var body: some View {
        GlassEffectContainer(spacing: 18) {
            controlsLayout
        }
    }

    private var controlsLayout: some View {
        ZStack {
            navigationControlsGroup
                .frame(maxWidth: .infinity, alignment: .center)

            HStack {
                closeButton
                    .padding(.leading, safeInsetPaddingLeft)

                Spacer()

                shareControlsGroup
                    .padding(.trailing, safeInsetPaddingRight)
            }
            .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity)
    }

    private var safeInsetPaddingLeft: CGFloat {
        let inset = PresentationContextProvider.shared.keyWindow?.safeAreaInsets.left ?? 0
        return max(inset, 12)
    }

    private var safeInsetPaddingRight: CGFloat {
        let inset = PresentationContextProvider.shared.keyWindow?.safeAreaInsets.right ?? 0
        return max(inset, 12)
    }

    private var navigationControlsGroup: some View {
        HStack(spacing: 0) {
            controlButton(systemName: "chevron.backward", isEnabled: controller.canGoBack) {
                controller.goBack()
            }

            if controller.canGoForward {
                controlButton(systemName: "chevron.forward") {
                    controller.goForward()
                }
            }

            controlButton(systemName: controller.isLoading ? "xmark" : "arrow.clockwise") {
                if controller.isLoading {
                    controller.stopLoading()
                } else {
                    controller.reload()
                }
            }
        }
        .padding(.horizontal, 6)
        .modifier(GlassCapsuleBackground())
        .shadow(color: .black.opacity(0.2), radius: 12, x: 0, y: 6)
    }

    private var shareControlsGroup: some View {
        HStack(spacing: 0) {
            controlButton(systemName: "square.and.arrow.up") {
                Task { @MainActor in
                    let targetURL = controller.currentURL ?? fallbackURL
                    ContentSharePresenter.shared.shareURL(targetURL, title: controller.currentTitle)
                }
            }

            controlButton(systemName: "safari") {
                let targetURL = controller.currentURL ?? fallbackURL
                LinkOpener.openInSystemBrowser(targetURL)
            }
        }
        .padding(.horizontal, 6)
        .modifier(GlassCapsuleBackground())
        .shadow(color: .black.opacity(0.2), radius: 12, x: 0, y: 6)
    }

    private var closeButton: some View {
        Button {
            Task { @MainActor in onDismiss() }
        } label: {
            Image(systemName: "xmark")
                .font(.system(size: 14, weight: .semibold))
                .frame(width: 20, height: 20)
                .padding(10)
        }
        .frame(width: 44, height: 44)
        .contentShape(Rectangle())
        .foregroundStyle(.primary)
        .accessibilityLabel("Close")
        .modifier(GlassCircleBackground())
        .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 4)
    }

    private func controlButton(
        systemName: String,
        isEnabled: Bool = true,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 14, weight: .semibold))
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(.primary)
        .opacity(isEnabled ? 1 : 0.35)
        .disabled(!isEnabled)
        .accessibilityLabel(controlLabel(for: systemName))
    }

    private func controlLabel(for systemName: String) -> String {
        switch systemName {
        case "chevron.backward":
            return "Back"
        case "chevron.forward":
            return "Forward"
        case "arrow.clockwise":
            return "Reload"
        case "xmark":
            return "Stop"
        case "square.and.arrow.up":
            return "Share"
        case "safari":
            return "Open in Safari"
        default:
            return "Button"
        }
    }
}

struct CollapsedBrowserControlsOverlay: View {
    let isVisible: Bool
    let fallbackURL: URL
    let onDismiss: @MainActor () -> Void
    @ObservedObject var controller: BrowserController

    var body: some View {
        ZStack {
            BrowserControlsView(
                fallbackURL: fallbackURL,
                onDismiss: onDismiss,
                controller: controller
            )
            .hidden()
            .accessibilityHidden(true)

            if isVisible {
                BrowserControlsView(
                    fallbackURL: fallbackURL,
                    onDismiss: onDismiss,
                    controller: controller
                )
                .transition(Self.visibilityTransition)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: isVisible)
        .allowsHitTesting(isVisible)
    }

    private static var visibilityTransition: AnyTransition {
        .asymmetric(
            insertion: .opacity.combined(with: .offset(y: 20)),
            removal: .opacity.combined(with: .offset(y: 20))
        )
    }
}

struct GlassCapsuleBackground: ViewModifier {
    func body(content: Content) -> some View {
        content.glassEffect(.regular.interactive(), in: .capsule)
    }
}

struct GlassCircleBackground: ViewModifier {
    func body(content: Content) -> some View {
        content.glassEffect(.regular.interactive(), in: .circle)
    }
}

struct CollapsedPostHeaderView: View {
    @Environment(\.colorScheme) private var colorScheme
    let post: Post
    let votingState: VotingState?
    let isLoading: Bool
    let onUpvote: () -> Void
    let onExpand: () -> Void
    let disablesUpvote: Bool
    let matchedGeometryNamespace: Namespace.ID?
    let isMatchedGeometrySource: Bool
    private static let collapsedVerticalPadding: CGFloat = 2
    private static let collapsedHorizontalPadding: CGFloat = 20
    private static let collapsedThumbnailSize: CGFloat = 28

    var body: some View {
        HStack(spacing: 12) {
            ThumbnailView(url: post.url, isEnabled: true)
                .postHeaderMatchedGeometry(
                    PostHeaderMatchedGeometryElement.thumbnail(postID: post.id),
                    namespace: matchedGeometryNamespace,
                    isSource: isMatchedGeometrySource
                )
                .frame(width: Self.collapsedThumbnailSize, height: Self.collapsedThumbnailSize)
                .clipShape(.rect(cornerRadius: min(16, Self.collapsedThumbnailSize * 0.3)))

            Text(domainText)
                .scaledFont(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .postHeaderMatchedGeometry(
                    PostHeaderMatchedGeometryElement.domain(postID: post.id),
                    namespace: matchedGeometryNamespace,
                    isSource: isMatchedGeometrySource
                )

            Spacer(minLength: 8)

            HStack(spacing: 8) {
                upvoteButton
                    .postHeaderMatchedGeometry(
                        PostHeaderMatchedGeometryElement.upvote(postID: post.id),
                        namespace: matchedGeometryNamespace,
                        isSource: isMatchedGeometrySource
                    )
                commentsPill
                    .postHeaderMatchedGeometry(
                        PostHeaderMatchedGeometryElement.comments(postID: post.id),
                        namespace: matchedGeometryNamespace,
                        isSource: isMatchedGeometrySource
                    )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, Self.collapsedHorizontalPadding)
        .padding(.vertical, Self.collapsedVerticalPadding)
        .contentShape(Rectangle())
        .onTapGesture(perform: onExpand)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(AccessibilityIdentifier.Browser.collapsedCommentsHeader)
    }

    private var domainText: String {
        let host = post.url.host ?? "Hackers"
        let trimmed = host.hasPrefix("www.") ? String(host.dropFirst(4)) : host
        return trimmed.uppercased()
    }

    private var commentsPill: some View {
        let style = AppColors.PillStyle.comments
        let textColor = AppColors.pillForeground(for: style, colorScheme: colorScheme)
        let backgroundColor = AppColors.pillBackground(for: style, colorScheme: colorScheme)

        return PostPillView(
            iconName: "message",
            text: "\(post.commentsCount)",
            textColor: textColor,
            backgroundColor: backgroundColor,
            numericValue: post.commentsCount
        )
        .accessibilityLabel("\(post.commentsCount) comments")
    }

    private var upvoteButton: some View {
        let isUpvoted = votingState?.isUpvoted ?? post.upvoted
        let score = votingState?.score ?? post.score
        let canVote = votingState?.canVote ?? (post.voteLinks?.upvote != nil)
        let canUnvote = votingState?.canUnvote ?? (post.voteLinks?.unvote != nil)
        let isVoting = votingState?.isVoting ?? isLoading
        let canInteract = ((canVote && !isUpvoted) || (canUnvote && isUpvoted)) && !isVoting
        let iconName = isUpvoted ? "arrow.up.circle.fill" : "arrow.up"
        let style = AppColors.PillStyle.upvote(isActive: isUpvoted)
        let textColor = AppColors.pillForeground(for: style, colorScheme: colorScheme)
        let backgroundColor = AppColors.pillBackground(for: style, colorScheme: colorScheme)

        return Button(action: onUpvote) {
            PostPillView(
                iconName: iconName,
                text: "\(score)",
                textColor: textColor,
                backgroundColor: backgroundColor,
                isLoading: isVoting,
                numericValue: score
            )
        }
        .buttonStyle(.plain)
        .disabled(!canInteract || disablesUpvote)
        .opacity(canInteract ? 1 : 0.55)
        .accessibilityLabel(isUpvoted ? "Upvoted" : "Upvote")
    }
}

private extension View {
    @ViewBuilder
    func postHeaderMatchedGeometry(
        _ id: String,
        namespace: Namespace.ID?,
        isSource: Bool
    ) -> some View {
        if let namespace {
            matchedGeometryEffect(id: id, in: namespace, isSource: isSource)
        } else {
            self
        }
    }
}

struct CollapsedPostHeaderLoadingView: View {
    var body: some View {
        HStack(spacing: 12) {
            Text("Loading...")
                .scaledFont(.caption)
                .foregroundStyle(.secondary)
            Spacer(minLength: 8)
            Capsule()
                .fill(.secondary.opacity(0.2))
                .frame(width: 52, height: 22)
            Capsule()
                .fill(.secondary.opacity(0.2))
                .frame(width: 52, height: 22)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 2)
    }
}

enum ControlsHeightPreferenceKey: PreferenceKey {
    static let defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

enum CollapsedHeaderHeightPreferenceKey: PreferenceKey {
    static let defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

struct CommentsSheetTopChrome: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var measuredTitleSize: CGSize = .zero
    let post: Post?
    let showThumbnails: Bool
    let titleProgress: CGFloat
    let isInteractiveMove: Bool
    let handleTopInset: CGFloat
    let chromeAreaHeight: CGFloat
    let titleMaximumWidth: CGFloat
    let toolbarControlCenterY: CGFloat?
    let handleWidth: CGFloat
    let handleThickness: CGFloat
    let navigationBarHeight: CGFloat
    let onTitleTap: () -> Void

    private var progress: CGFloat {
        min(max(titleProgress, 0), 1)
    }

    private var easedProgress: CGFloat {
        progress * progress * (3 - (2 * progress))
    }

    private var handleOpacity: CGFloat {
        1 - titleContentProgress
    }

    private var glassSurfaceOpacity: CGFloat {
        min(max(easedProgress / 0.18, 0), 1)
    }

    private var titleContentProgress: CGFloat {
        min(max((easedProgress - 0.24) / 0.52, 0), 1)
    }

    private var resolvedTitleSize: CGSize {
        guard measuredTitleSize.width > 0, measuredTitleSize.height > 0 else {
            return CGSize(width: 220, height: navigationBarHeight)
        }
        return measuredTitleSize
    }

    private var morphWidth: CGFloat {
        interpolate(from: handleWidth, to: resolvedTitleSize.width, progress: easedProgress)
    }

    private var morphHeight: CGFloat {
        interpolate(from: handleThickness, to: resolvedTitleSize.height, progress: easedProgress)
    }

    private var morphVerticalOffset: CGFloat {
        let handleOffset = (chromeAreaHeight - handleThickness) / 2
        let titleOffset = toolbarControlCenterY.map {
            max($0 - handleTopInset - (resolvedTitleSize.height / 2), 0)
        } ?? max((chromeAreaHeight - resolvedTitleSize.height) / 2, 0)
        return interpolate(from: handleOffset, to: titleOffset, progress: easedProgress)
    }

    var body: some View {
        ZStack(alignment: .top) {
            if let post {
                measuredTitleContent(for: post)
            }

            morphingChrome
                .padding(.top, handleTopInset)
                .offset(y: morphVerticalOffset)
        }
        .frame(maxWidth: .infinity)
        .frame(height: navigationBarHeight + handleTopInset, alignment: .top)
        .animation(isInteractiveMove ? nil : chromeAnimation, value: progress)
    }

    private var morphingChrome: some View {
        Button(action: onTitleTap) {
            ZStack {
                if glassSurfaceOpacity > 0 {
                    ZStack {
                        if let post {
                            CommentsHeaderTitlePillContent(
                                post: post,
                                showThumbnails: showThumbnails,
                                maximumWidth: titleMaximumWidth
                            )
                                .opacity(titleContentProgress)
                        }
                    }
                    .frame(width: morphWidth, height: morphHeight)
                    .clipShape(.capsule)
                    .glassEffect(.regular.interactive(), in: .capsule)
                    .glassEffectTransition(.identity)
                    .opacity(glassSurfaceOpacity)
                }
                Capsule()
                    .fill(.secondary.opacity(0.52))
                    .frame(width: handleWidth, height: handleThickness)
                    .opacity(handleOpacity)
                    .allowsHitTesting(false)
            }
            .frame(width: morphWidth, height: morphHeight)
            .contentShape(.capsule)
        }
        .buttonStyle(.plain)
        .disabled(progress <= 0.5)
        .accessibilityIdentifier(AccessibilityIdentifier.Browser.expandedCommentsTitle)
        .accessibilityLabel(post?.title ?? "Comments sheet handle")
        .accessibilityHint("Collapse comments")
        .accessibilityHidden(progress <= 0.5)
    }

    private var chromeAnimation: Animation {
        if reduceMotion {
            .easeInOut(duration: 0.2)
        } else {
            .spring(response: 0.32, dampingFraction: 0.84, blendDuration: 0.05)
        }
    }

    private func measuredTitleContent(for post: Post) -> some View {
        CommentsHeaderTitlePillContent(
            post: post,
            showThumbnails: showThumbnails,
            maximumWidth: titleMaximumWidth
        )
            .hidden()
            .background(
                GeometryReader { proxy in
                    Color.clear.preference(key: TitlePillSizePreferenceKey.self, value: proxy.size)
                }
            )
            .allowsHitTesting(false)
            .accessibilityHidden(true)
            .onPreferenceChange(TitlePillSizePreferenceKey.self) { newValue in
                guard newValue.width > 0, newValue.height > 0 else { return }
                measuredTitleSize = newValue
            }
    }

    private func interpolate(from start: CGFloat, to end: CGFloat, progress: CGFloat) -> CGFloat {
        start + ((end - start) * progress)
    }
}

private struct TitlePillSizePreferenceKey: PreferenceKey {
    static let defaultValue: CGSize = .zero

    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        let next = nextValue()
        if next.width > 0, next.height > 0 {
            value = next
        }
    }
}

struct StableCommentsHost: View, @preconcurrency Equatable {
    let postID: Int
    let topContentInset: CGFloat
    let showsPostHeader: Bool
    let scrollDisabled: Bool
    let viewModel: CommentsViewModel
    let votingViewModel: VotingViewModel
    let postHeaderMatchedGeometryNamespace: Namespace.ID?
    let isPostHeaderMatchedGeometrySource: Bool
    let titleVisibility: CommentsHeaderTitleVisibility
    let toolbarGeometry: CommentsToolbarGeometry
    let showsToolbar: Bool
    let dragExpandedTop: CGFloat
    let dragCollapsedTop: CGFloat
    let onPostLinkTap: () -> Void
    let onTitleDragChanged: (DragGesture.Value) -> Void
    let onTitleDragEnded: (DragGesture.Value) -> Void

    static func == (lhs: StableCommentsHost, rhs: StableCommentsHost) -> Bool {
        lhs.postID == rhs.postID
            && lhs.topContentInset == rhs.topContentInset
            && lhs.showsPostHeader == rhs.showsPostHeader
            && lhs.scrollDisabled == rhs.scrollDisabled
            && lhs.isPostHeaderMatchedGeometrySource == rhs.isPostHeaderMatchedGeometrySource
            && lhs.showsToolbar == rhs.showsToolbar
            && lhs.dragExpandedTop == rhs.dragExpandedTop
            && lhs.dragCollapsedTop == rhs.dragCollapsedTop
            && ObjectIdentifier(lhs.viewModel) == ObjectIdentifier(rhs.viewModel)
            && ObjectIdentifier(lhs.votingViewModel) == ObjectIdentifier(rhs.votingViewModel)
            && ObjectIdentifier(lhs.toolbarGeometry) == ObjectIdentifier(rhs.toolbarGeometry)
    }

    var body: some View {
        CommentsView<NavigationStore>(
            postID: postID,
            showsPostHeader: showsPostHeader,
            allowsRefresh: false,
            showsToolbar: showsToolbar,
            controlsNavigationBarVisibility: true,
            presentationState: .customBrowser(topContentInset: topContentInset),
            postHeaderMatchedGeometryNamespace: postHeaderMatchedGeometryNamespace,
            isPostHeaderMatchedGeometrySource: isPostHeaderMatchedGeometrySource,
            headerTitleVisibility: titleVisibility,
            toolbarGeometry: toolbarGeometry,
            onPostLinkTap: onPostLinkTap,
            onTitleDragChanged: onTitleDragChanged,
            onTitleDragEnded: onTitleDragEnded,
            onPostHeaderDragChanged: onTitleDragChanged,
            onPostHeaderDragEnded: onTitleDragEnded,
            viewModel: viewModel,
            votingViewModel: votingViewModel
        )
        .scrollDisabled(scrollDisabled)
    }
}
