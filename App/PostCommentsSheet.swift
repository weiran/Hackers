import Comments
import DesignSystem
import Domain
import Shared
import SwiftUI
import UIKit

// swiftlint:disable type_body_length

private struct LeadingEdgeExcludedRectangle: Shape {
    let excludedWidth: CGFloat

    func path(in rect: CGRect) -> Path {
        let clampedWidth = min(max(excludedWidth, 0), rect.width)
        let hitRect = CGRect(
            x: rect.minX + clampedWidth,
            y: rect.minY,
            width: rect.width - clampedWidth,
            height: rect.height
        )
        return Path(hitRect)
    }
}

struct PostCommentsSheet: View {
    static let initialCollapsedHeight: CGFloat = PostCommentsSheetMetrics.initialCollapsedHeight
    static let collapsedTopCornerRadius: CGFloat = PostCommentsSheetMetrics.collapsedTopCornerRadius
    static let collapsedBrowserControlsHeight: CGFloat = PostCommentsSheetMetrics.collapsedBrowserControlsHeight
    static let collapsedBrowserControlsSpacing: CGFloat = PostCommentsSheetMetrics.collapsedBrowserControlsSpacing
    static let collapsedBrowserControlsMargin: CGFloat = PostCommentsSheetMetrics.collapsedBrowserControlsMargin
    static var defaultCollapsedBrowserObscuredBottomInset: CGFloat {
        PostCommentsSheetMetrics.defaultCollapsedBrowserObscuredBottomInset
    }

    private static let handleWidth: CGFloat = 36
    private static let handleThickness: CGFloat = 5
    private static let handleAreaHeight: CGFloat = PostCommentsSheetMetrics.handleAreaHeight
    private static let handleToolbarSpacing: CGFloat = 8
    private static let expandedToolbarTitleHitHeight: CGFloat = 58
    private static let expandedContentSpacing: CGFloat = 8
    private static let sheetAnimationDuration: TimeInterval = WebViewAnimations.panelDuration

    let onDismiss: @MainActor () -> Void
    let onCollapsedHeightChange: @MainActor (CGFloat) -> Void
    let onBrowserObscuredBottomInsetChange: @MainActor (CGFloat) -> Void
    let fallbackURL: URL
    @ObservedObject private var browserController: BrowserController
    @State private var viewModel: CommentsViewModel
    @State private var votingViewModel: VotingViewModel
    @State private var presentation: PostCommentsSheetPresentation
    @State private var collapsedHeight: CGFloat = initialCollapsedHeight
    @State private var controlsHeight: CGFloat = 0
    @State private var isScrollAtTop = true
    @State private var expandedTitleVisibility = CommentsHeaderTitleVisibility()
    @Namespace private var postHeaderNamespace

    init(
        post: Post,
        controller: BrowserController,
        initialPresentation: PostLinkPresentation = .collapsedBrowser,
        onDismiss: @MainActor @escaping () -> Void,
        onCollapsedHeightChange: @MainActor @escaping (CGFloat) -> Void = { _ in },
        onBrowserObscuredBottomInsetChange: @MainActor @escaping (CGFloat) -> Void = { _ in }
    ) {
        let initialSheetState: SheetState = switch initialPresentation {
        case .collapsedBrowser:
            .collapsed
        case .expandedComments:
            .expanded
        }

        _viewModel = State(initialValue: CommentsViewModel(post: post))
        let container = DependencyContainer.shared
        _votingViewModel = State(initialValue: VotingViewModel(
            votingStateProvider: container.getVotingStateProvider(),
            commentVotingStateProvider: container.getCommentVotingStateProvider(),
            authenticationUseCase: container.getAuthenticationUseCase()
        ))
        _browserController = ObservedObject(wrappedValue: controller)
        _presentation = State(initialValue: PostCommentsSheetPresentation(sheetState: initialSheetState))
        self.onDismiss = onDismiss
        self.onCollapsedHeightChange = onCollapsedHeightChange
        self.onBrowserObscuredBottomInsetChange = onBrowserObscuredBottomInsetChange
        fallbackURL = post.url
    }

    var body: some View {
        GeometryReader { proxy in
            let safeInsets = resolvedSafeAreaInsets(for: proxy)
            let screenSize = resolvedScreenSize(for: proxy)
            let layout = PostCommentsSheetLayout(
                safeInsets: safeInsets,
                screenSize: screenSize,
                collapsedHeight: collapsedHeight,
                controlsHeight: controlsHeight,
                dragTranslation: presentation.dragTranslation,
                isExpanded: presentation.isExpanded,
                expandedTopOverlayHeight: expandedTopOverlayHeight(handleTopInset:)
            )
            let showsExpandedPresentation = viewModel.post != nil

            ZStack(alignment: .topLeading) {
                Color.clear.allowsHitTesting(false)

                sheetContent(
                    expandedTop: layout.expandedTop,
                    collapsedTop: layout.collapsedTop,
                    handleTopInset: layout.handleTopInset,
                    commentsTopContentInset: layout.expandedCommentsTopInset,
                    contentFadeProgress: layout.contentFadeProgress,
                    isInteractiveMove: presentation.isInteractiveMove,
                    showsExpandedPresentation: showsExpandedPresentation
                )
                .frame(width: screenSize.width, height: screenSize.height, alignment: .top)
                .background(sheetBackground)
                .clipShape(sheetShape)
                .shadow(
                    color: presentation.isInteractiveMove ? .clear : .black.opacity(0.12),
                    radius: presentation.isInteractiveMove ? 0 : 10,
                    x: 0,
                    y: presentation.isInteractiveMove ? 0 : -5
                )
                .offset(y: layout.alignedTop)

                CollapsedBrowserControlsOverlay(
                    isVisible: presentation.showsCollapsedControls,
                    fallbackURL: fallbackURL,
                    onDismiss: onDismiss,
                    controller: browserController
                )
                .frame(width: screenSize.width, alignment: .center)
                .offset(y: layout.controlsTop)
                .background(
                    GeometryReader { controlsProxy in
                        Color.clear.preference(
                            key: ControlsHeightPreferenceKey.self,
                            value: controlsProxy.size.height
                        )
                    }
                )
            }
            .frame(width: screenSize.width, height: screenSize.height, alignment: .topLeading)
            .ignoresSafeArea(.container)
            .animation(WebViewAnimations.fast, value: collapsedHeight)
            .onAppear {
                onCollapsedHeightChange(collapsedHeight)
                updateBrowserObscuredBottomInset()
            }
            .onPreferenceChange(CollapsedHeaderHeightPreferenceKey.self) { updateCollapsedHeight($0) }
            .onPreferenceChange(ControlsHeightPreferenceKey.self) { updateControlsHeight($0) }
            .onChange(of: controlsHeight) { _, _ in
                updateBrowserObscuredBottomInset()
            }
            .onChange(of: isExpanded) { _, newValue in
                updateExpandedPresentation(isExpanded: newValue)
            }
            .accessibilityIdentifier("browser.commentsSheet")
        }
    }

    private var isExpanded: Bool {
        presentation.isExpanded
    }

    private var isCollapsed: Bool {
        presentation.isCollapsed
    }

    private var handleAreaHeight: CGFloat {
        Self.handleAreaHeight
    }

    private var sheetShape: UnevenRoundedRectangle {
        UnevenRoundedRectangle(
            topLeadingRadius: Self.collapsedTopCornerRadius,
            bottomLeadingRadius: 0,
            bottomTrailingRadius: 0,
            topTrailingRadius: Self.collapsedTopCornerRadius
        )
    }

    private var sheetBackground: some View {
        sheetShape.fill(.background)
    }

    private func sheetContent(
        expandedTop: CGFloat,
        collapsedTop: CGFloat,
        handleTopInset: CGFloat,
        commentsTopContentInset: CGFloat,
        contentFadeProgress: CGFloat,
        isInteractiveMove: Bool,
        showsExpandedPresentation: Bool
    ) -> some View {
        ZStack(alignment: .top) {
            if showsExpandedPresentation {
                expandedCommentsView(
                    topContentInset: commentsTopContentInset,
                    showsPostHeader: true
                )
                .overlay {
                    if contentFadeProgress < 0.01 {
                        Rectangle()
                            .fill(.background)
                            .allowsHitTesting(false)
                    } else if !isInteractiveMove, contentFadeProgress < 1 {
                        Rectangle()
                            .fill(.background)
                            .opacity(1 - contentFadeProgress)
                            .allowsHitTesting(false)
                    }
                }
                .allowsHitTesting(contentFadeProgress >= 0.5)
                .accessibilityHidden(contentFadeProgress < 0.5)
                .simultaneousGesture(sheetDragGesture(expandedTop: expandedTop, collapsedTop: collapsedTop))

                expandedTopOverlay(
                    handleTopInset: handleTopInset,
                    controlsOpacity: contentFadeProgress,
                    expandedTop: expandedTop,
                    collapsedTop: collapsedTop
                )
                .allowsHitTesting(contentFadeProgress >= 0.5)
            }

            VStack(spacing: 0) {
                Color.clear
                    .frame(height: Self.handleAreaHeight + handleTopInset)

                collapsedHeader
                    .allowsHitTesting(true)
            }
            .opacity(1 - contentFadeProgress)
            .allowsHitTesting(contentFadeProgress < 0.5)
            .accessibilityHidden(contentFadeProgress >= 0.5)

            sheetHandle(
                expandedTop: expandedTop,
                collapsedTop: collapsedTop,
                handleTopInset: handleTopInset
            )
        }
    }

    private func expandedCommentsView(
        topContentInset: CGFloat,
        showsPostHeader: Bool
    ) -> some View {
        StableCommentsHost(
            postID: viewModel.postID,
            topContentInset: topContentInset,
            showsPostHeader: showsPostHeader,
            scrollDisabled: !isExpanded || presentation.dragStartAllowsSheetDrag || presentation.isHandleDragActive,
            viewModel: viewModel,
            votingViewModel: votingViewModel,
            postHeaderMatchedGeometryNamespace: postHeaderNamespace,
            isPostHeaderMatchedGeometrySource: isExpanded,
            titleVisibility: expandedTitleVisibility,
            isAtTop: $isScrollAtTop,
            onPostLinkTap: collapseSheet
        )
        .equatable()
    }

    private func expandedTopOverlay(
        handleTopInset: CGFloat,
        controlsOpacity: CGFloat,
        expandedTop: CGFloat,
        collapsedTop: CGFloat
    ) -> some View {
        ZStack(alignment: .top) {
            VStack(spacing: 0) {
                Color.clear
                    .frame(height: handleTopInset + Self.handleAreaHeight + Self.handleToolbarSpacing)

                GlassEffectContainer(spacing: 10) {
                    HStack(alignment: .top, spacing: 10) {
                        Button {
                            onDismiss()
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.title3.weight(.medium))
                                .frame(width: 44, height: 44)
                        }
                        .buttonStyle(.plain)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                        .accessibilityLabel("Back")
                        .accessibilityIdentifier("browser.commentsSheet.back")
                        .modifier(GlassCircleBackground())

                        if let post = viewModel.post {
                            CommentsHeaderTitleButton(
                                post: post,
                                showThumbnails: viewModel.showThumbnails,
                                titleVisibility: expandedTitleVisibility,
                                accessibilityHint: "Collapse comments",
                                hitHeight: Self.expandedToolbarTitleHitHeight,
                                fillsAvailableWidth: true,
                                usesOffsetTransition: false,
                                onTap: collapseSheet
                            )
                            .frame(maxWidth: .infinity, alignment: .top)
                            .frame(height: Self.expandedToolbarTitleHitHeight, alignment: .top)
                        } else {
                            Spacer()
                        }

                        if let post = viewModel.post {
                            Button {
                                ContentSharePresenter.shared.shareHackerNewsPost(post)
                            } label: {
                                Image(systemName: "square.and.arrow.up")
                                    .frame(width: 44, height: 44)
                                    .contentShape(Circle())
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Share")
                            .modifier(GlassCircleBackground())
                        }
                    }
                }
                .padding(.horizontal, 16)
                .frame(height: Self.expandedToolbarTitleHitHeight, alignment: .top)
                .opacity(controlsOpacity)
            }
        }
        .allowsHitTesting(isExpanded)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("browser.commentsSheet.expandedToolbar")
        .background(alignment: .top) {
            ProgressiveHeaderBlurBackground(
                height: expandedHeaderBlurHeight(handleTopInset: handleTopInset),
                fadeExtension: Self.expandedContentSpacing
            )
        }
    }

    private func expandedTopOverlayHeight(handleTopInset: CGFloat) -> CGFloat {
        expandedHeaderBlurHeight(handleTopInset: handleTopInset) + Self.expandedContentSpacing
    }

    private func expandedHeaderBlurHeight(handleTopInset: CGFloat) -> CGFloat {
        handleTopInset + Self.handleAreaHeight + Self.handleToolbarSpacing + Self.expandedToolbarTitleHitHeight
    }

    private func sheetHandle(
        expandedTop: CGFloat,
        collapsedTop: CGFloat,
        handleTopInset: CGFloat
    ) -> some View {
        ZStack(alignment: .bottom) {
            HStack {
                Spacer()

                Capsule()
                    .fill(.secondary.opacity(0.35))
                    .frame(width: Self.handleWidth, height: Self.handleThickness)
                    .frame(width: 88, height: Self.handleAreaHeight, alignment: .center)

                Spacer()
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: Self.handleAreaHeight + handleTopInset, alignment: .bottom)
        .contentShape(LeadingEdgeExcludedRectangle(excludedWidth: systemBackGestureEdgeWidth))
        .highPriorityGesture(handleDragGesture(expandedTop: expandedTop, collapsedTop: collapsedTop))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Comments sheet handle")
        .accessibilityIdentifier("browser.commentsSheet.handle")
    }

    private var collapsedHeader: some View {
        collapsedHeaderView(onExpand: {
            animateSheet {
                presentation.expand()
            }
        })
        .background(
            GeometryReader { proxy in
                Color.clear.preference(key: CollapsedHeaderHeightPreferenceKey.self, value: proxy.size.height)
            }
        )
    }

    @ViewBuilder
    private func collapsedHeaderView(onExpand: @escaping () -> Void) -> some View {
        if let post = viewModel.post {
            CollapsedPostHeaderView(
                post: post,
                votingState: votingViewModel.votingState(for: post),
                isLoading: viewModel.isLoading,
                onUpvote: { handleCollapsedUpvote(for: post) },
                onExpand: onExpand,
                disablesUpvote: presentation.suppressesCollapsedUpvote,
                matchedGeometryNamespace: postHeaderNamespace,
                isMatchedGeometrySource: isCollapsed
            )
        } else {
            CollapsedPostHeaderLoadingView()
        }
    }

    private func handleCollapsedUpvote(for post: Post) {
        guard !presentation.suppressesCollapsedUpvote else { return }
        let state = votingViewModel.votingState(for: post)
        guard !state.isVoting else { return }
        let canUpvote = state.canVote && !state.isUpvoted
        let canUnvote = state.canUnvote && state.isUpvoted
        guard canUpvote || canUnvote else { return }

        Task {
            var updatedPost = post
            if updatedPost.upvoted {
                await votingViewModel.unvote(post: &updatedPost)
            } else {
                await votingViewModel.upvote(post: &updatedPost)
            }
            await MainActor.run {
                viewModel.post = updatedPost
            }
        }
    }

    private func animateSheet(_ animation: Animation = WebViewAnimations.panel, _ updates: () -> Void) {
        withAnimation(animation) {
            updates()
        }
    }

    private func collapseSheet() {
        guard isExpanded else { return }
        animateSheet {
            presentation.collapse()
        }
    }
}

private extension PostCommentsSheet {
    private func updateCollapsedHeight(_ newValue: CGFloat) {
        let updated = ceil(newValue)
        guard updated.isFinite, updated > 0 else { return }
        let totalHeight = updated + handleAreaHeight
        guard abs(totalHeight - collapsedHeight) > 0.5 else { return }
        collapsedHeight = totalHeight
        onCollapsedHeightChange(totalHeight)
    }

    private func updateControlsHeight(_ newValue: CGFloat) {
        let updated = ceil(newValue)
        guard updated.isFinite, updated > 0 else { return }
        guard abs(updated - controlsHeight) > 0.5 else { return }
        controlsHeight = updated
    }

    private func updateBrowserObscuredBottomInset() {
        onBrowserObscuredBottomInsetChange(
            PostCommentsSheetMetrics.browserObscuredBottomInset(controlsHeight: controlsHeight)
        )
    }

    private func updateExpandedPresentation(isExpanded: Bool) {
        if !isExpanded {
            withAnimation(.easeInOut(duration: 0.3)) {
                expandedTitleVisibility.setVisible(false)
            }
        }
    }

    private func resolvedSafeAreaInsets(for proxy: GeometryProxy) -> UIEdgeInsets {
        if let insets = PresentationContextProvider.shared.keyWindow?.safeAreaInsets {
            return insets
        }
        let insets = proxy.safeAreaInsets
        if insets.top != 0 || insets.leading != 0 || insets.bottom != 0 || insets.trailing != 0 {
            return UIEdgeInsets(
                top: insets.top,
                left: insets.leading,
                bottom: insets.bottom,
                right: insets.trailing
            )
        }
        return .zero
    }

    private func resolvedScreenSize(for proxy: GeometryProxy) -> CGSize {
        let size = proxy.size
        let insets = proxy.safeAreaInsets
        let fullSize = CGSize(
            width: size.width + insets.leading + insets.trailing,
            height: size.height + insets.top + insets.bottom
        )
        if fullSize.width > 0, fullSize.height > 0 {
            return fullSize
        }
        return PresentationContextProvider.shared.keyWindow?.bounds.size ?? fullSize
    }

    private func sheetDragGesture(expandedTop: CGFloat, collapsedTop: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 6, coordinateSpace: .global)
            .onChanged { value in
                presentation.updateSheetDrag(
                    startX: value.startLocation.x,
                    translation: value.translation,
                    systemBackGestureEdgeWidth: systemBackGestureEdgeWidth,
                    isScrollAtTop: isScrollAtTop
                )
            }
            .onEnded { value in
                guard presentation.canEndSheetDrag(
                    startX: value.startLocation.x,
                    systemBackGestureEdgeWidth: systemBackGestureEdgeWidth
                ) else {
                    scheduleCollapsedUpvoteReenable()
                    return
                }
                settleSheet(predictedTranslation: value.predictedEndTranslation.height, expandedTop, collapsedTop)
            }
    }

    private func handleDragGesture(expandedTop: CGFloat, collapsedTop: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .global)
            .onChanged { value in
                presentation.updateHandleDrag(
                    startX: value.startLocation.x,
                    translationHeight: value.translation.height,
                    systemBackGestureEdgeWidth: systemBackGestureEdgeWidth
                )
            }
            .onEnded { value in
                guard presentation.canEndHandleDrag(
                    startX: value.startLocation.x,
                    systemBackGestureEdgeWidth: systemBackGestureEdgeWidth
                ) else {
                    scheduleCollapsedUpvoteReenable()
                    return
                }
                settleSheet(predictedTranslation: value.predictedEndTranslation.height, expandedTop, collapsedTop)
            }
    }

    private var systemBackGestureEdgeWidth: CGFloat {
        let leadingInset = PresentationContextProvider.shared.keyWindow?.safeAreaInsets.left ?? 0
        return leadingInset + 56
    }

    private func settleSheet(predictedTranslation: CGFloat, _ expandedTop: CGFloat, _ collapsedTop: CGFloat) {
        animateSheet {
            presentation.settle(
                predictedTranslation: predictedTranslation,
                expandedTop: expandedTop,
                collapsedTop: collapsedTop
            )
        }
        scheduleCollapsedUpvoteReenable()
    }

    private func scheduleCollapsedUpvoteReenable() {
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.sheetAnimationDuration) {
            presentation.finishUpvoteSuppressionIfIdle()
        }
    }
}

private struct StableCommentsHost: View, @preconcurrency Equatable {
    let postID: Int
    let topContentInset: CGFloat
    let showsPostHeader: Bool
    let scrollDisabled: Bool
    let viewModel: CommentsViewModel
    let votingViewModel: VotingViewModel
    let postHeaderMatchedGeometryNamespace: Namespace.ID?
    let isPostHeaderMatchedGeometrySource: Bool
    let titleVisibility: CommentsHeaderTitleVisibility
    @Binding var isAtTop: Bool
    let onPostLinkTap: () -> Void

    static func == (lhs: StableCommentsHost, rhs: StableCommentsHost) -> Bool {
        lhs.postID == rhs.postID
            && lhs.topContentInset == rhs.topContentInset
            && lhs.showsPostHeader == rhs.showsPostHeader
            && lhs.scrollDisabled == rhs.scrollDisabled
            && lhs.isPostHeaderMatchedGeometrySource == rhs.isPostHeaderMatchedGeometrySource
            && ObjectIdentifier(lhs.viewModel) == ObjectIdentifier(rhs.viewModel)
            && ObjectIdentifier(lhs.votingViewModel) == ObjectIdentifier(rhs.votingViewModel)
    }

    var body: some View {
        CommentsView<NavigationStore>(
            postID: postID,
            showsPostHeader: showsPostHeader,
            allowsRefresh: false,
            showsToolbar: false,
            controlsNavigationBarVisibility: false,
            presentationState: .customBrowser(topContentInset: topContentInset),
            postHeaderMatchedGeometryNamespace: postHeaderMatchedGeometryNamespace,
            isPostHeaderMatchedGeometrySource: isPostHeaderMatchedGeometrySource,
            headerTitleVisibility: titleVisibility,
            isAtTop: $isAtTop,
            onPostLinkTap: onPostLinkTap,
            viewModel: viewModel,
            votingViewModel: votingViewModel
        )
        .scrollDisabled(scrollDisabled)
    }
}
