import Comments
import DesignSystem
import Domain
import Shared
import SwiftUI
import UIKit

struct PostCommentsSheet: View {
    static let initialCollapsedHeight: CGFloat = 150
    private static let handleWidth: CGFloat = 36
    private static let handleThickness: CGFloat = 5
    private static let handleAreaHeight: CGFloat = 22
    private static let handleToolbarSpacing: CGFloat = 8
    private static let expandedToolbarHeight: CGFloat = 44
    private static let expandedContentSpacing: CGFloat = 8
    private static let controlsSpacing: CGFloat = 12
    private static let sheetAnimationDuration: TimeInterval = WebViewAnimations.panelDuration

    let onDismiss: @MainActor () -> Void
    let fallbackURL: URL
    @ObservedObject private var browserController: BrowserController
    @State private var viewModel: CommentsViewModel
    @State private var votingViewModel: VotingViewModel
    @State private var collapsedHeight: CGFloat = initialCollapsedHeight
    @State private var sheetState: SheetState = .collapsed
    @State private var dragTranslation: CGFloat = 0
    @State private var isTrackingDrag = false
    @State private var dragStartAllowsSheetDrag = false
    @State private var isHandleDragActive = false
    @State private var controlsHeight: CGFloat = 0
    @State private var isScrollAtTop = true
    @State private var showsExpandedToolbar = false
    @State private var expandedTitleVisibility = CommentsHeaderTitleVisibility()
    @State private var suppressesCollapsedUpvote = false
    @Namespace private var postHeaderNamespace

    init(
        post: Post,
        controller: BrowserController,
        initialPresentation: PostLinkPresentation = .collapsedBrowser,
        onDismiss: @MainActor @escaping () -> Void
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
        _sheetState = State(initialValue: initialSheetState)
        _showsExpandedToolbar = State(initialValue: initialSheetState == .expanded)
        self.onDismiss = onDismiss
        fallbackURL = post.url
    }

    var body: some View {
        GeometryReader { proxy in
            let safeInsets = resolvedSafeAreaInsets(for: proxy)
            let screenSize = resolvedScreenSize(for: proxy)
            let expandedTop: CGFloat = 0
            let collapsedTop = max(screenSize.height - (collapsedHeight + safeInsets.bottom), expandedTop)
            let baseTop = isExpanded ? expandedTop : collapsedTop
            let proposedTop = baseTop + dragTranslation
            let clampedTop = min(max(proposedTop, expandedTop), collapsedTop)
            let alignedTop = clampedTop
            let controlsOffset = max(controlsHeight, 44.0) + Self.controlsSpacing
            let controlsTop = alignedTop - controlsOffset
            let showsExpandedPresentation = viewModel.post != nil
            let showsCollapsedControls = sheetState == .collapsed && !isTrackingDrag && !isHandleDragActive
            let expansionProgress: CGFloat = if collapsedTop > expandedTop {
                1 - ((alignedTop - expandedTop) / (collapsedTop - expandedTop))
            } else {
                isExpanded ? 1 : 0
            }
            let handleTopInset = safeInsets.top * min(max(expansionProgress, 0), 1)
            // Keep the comments list's inset stable while sheet chrome animates.
            let expandedCommentsTopInset = expandedTopOverlayHeight(handleTopInset: safeInsets.top)
            let contentFadeProgress = min(max(expansionProgress, 0), 1)
            let isInteractiveMove = isTrackingDrag || isHandleDragActive

            ZStack(alignment: .topLeading) {
                Color.clear.allowsHitTesting(false)

                sheetContent(
                    expandedTop: expandedTop,
                    collapsedTop: collapsedTop,
                    handleTopInset: handleTopInset,
                    commentsTopContentInset: expandedCommentsTopInset,
                    contentFadeProgress: contentFadeProgress,
                    isInteractiveMove: isInteractiveMove,
                    showsExpandedPresentation: showsExpandedPresentation
                )
                .frame(width: screenSize.width, height: screenSize.height, alignment: .top)
                .background(sheetBackground)
                .clipShape(sheetShape)
                .shadow(
                    color: isInteractiveMove ? .clear : .black.opacity(0.12),
                    radius: isInteractiveMove ? 0 : 10,
                    x: 0,
                    y: isInteractiveMove ? 0 : -5
                )
                .offset(y: alignedTop)

                CollapsedBrowserControlsOverlay(
                    isVisible: showsCollapsedControls,
                    fallbackURL: fallbackURL,
                    onDismiss: onDismiss,
                    controller: browserController
                )
                .frame(width: screenSize.width, alignment: .center)
                .offset(y: controlsTop)
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
            .onPreferenceChange(CollapsedHeaderHeightPreferenceKey.self) { updateCollapsedHeight($0) }
            .onPreferenceChange(ControlsHeightPreferenceKey.self) { updateControlsHeight($0) }
            .onChange(of: isExpanded) { _, newValue in
                updateExpandedToolbarVisibility(isExpanded: newValue)
            }
        }
    }

    private var isExpanded: Bool {
        sheetState == .expanded
    }

    private var isCollapsed: Bool {
        !isExpanded
    }

    private var handleAreaHeight: CGFloat {
        Self.handleAreaHeight
    }

    private var sheetShape: UnevenRoundedRectangle {
        UnevenRoundedRectangle(
            topLeadingRadius: 24,
            bottomLeadingRadius: 0,
            bottomTrailingRadius: 0,
            topTrailingRadius: 24
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
                .simultaneousGesture(sheetDragGesture(expandedTop: expandedTop, collapsedTop: collapsedTop))

                expandedTopOverlay(
                    handleTopInset: handleTopInset,
                    expandedTop: expandedTop,
                    collapsedTop: collapsedTop
                )
                .opacity(contentFadeProgress)
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
            .contentShape(LeadingEdgeExcludedRectangle(excludedWidth: systemBackGestureEdgeWidth))
            .simultaneousGesture(sheetDragGesture(expandedTop: expandedTop, collapsedTop: collapsedTop))

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
            scrollDisabled: !isExpanded || dragStartAllowsSheetDrag || isHandleDragActive,
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
        expandedTop: CGFloat,
        collapsedTop: CGFloat
    ) -> some View {
        VStack(spacing: 0) {
            Color.clear
                .frame(height: handleTopInset + Self.handleAreaHeight + Self.handleToolbarSpacing)
                .contentShape(LeadingEdgeExcludedRectangle(excludedWidth: systemBackGestureEdgeWidth))
                .simultaneousGesture(expandedToolbarDragGesture(expandedTop: expandedTop, collapsedTop: collapsedTop))

            GlassEffectContainer(spacing: 10) {
                HStack(spacing: 10) {
                    Button {
                        dismissBrowser()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.title3.weight(.medium))
                            .frame(width: 44, height: 44)
                    }
                    .buttonStyle(.plain)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
                    .accessibilityLabel("Back")
                    .modifier(GlassCircleBackground())

                    if let post = viewModel.post {
                        CommentsHeaderTitleButton(
                            post: post,
                            showThumbnails: viewModel.showThumbnails,
                            titleVisibility: expandedTitleVisibility,
                            accessibilityHint: "Collapse comments",
                            onTap: collapseSheet
                        )
                        .frame(maxWidth: .infinity, alignment: .center)
                    } else {
                        Spacer()
                    }

                    if let post = viewModel.post {
                        Button {
                            ContentSharePresenter.shared.shareURL(post.hackerNewsURL, title: post.title)
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
            .frame(height: Self.expandedToolbarHeight)
            .opacity(showsExpandedToolbar ? 1 : 0)
        }
        .allowsHitTesting(showsExpandedToolbar)
        .background(alignment: .top) {
            ProgressiveHeaderBlurBackground(
                height: expandedHeaderBlurHeight(handleTopInset: handleTopInset),
                fadeExtension: Self.expandedContentSpacing
            )
            .opacity(showsExpandedToolbar ? 1 : 0)
        }
    }

    private func expandedTopOverlayHeight(handleTopInset: CGFloat) -> CGFloat {
        expandedHeaderBlurHeight(handleTopInset: handleTopInset) + Self.expandedContentSpacing
    }

    private func expandedHeaderBlurHeight(handleTopInset: CGFloat) -> CGFloat {
        handleTopInset + Self.handleAreaHeight + Self.handleToolbarSpacing + Self.expandedToolbarHeight
    }

    private func sheetHandle(
        expandedTop: CGFloat,
        collapsedTop: CGFloat,
        handleTopInset: CGFloat
    ) -> some View {
        ZStack(alignment: .bottom) {
            Capsule()
                .fill(.secondary.opacity(0.35))
                .frame(width: Self.handleWidth, height: Self.handleThickness)
                .padding(.bottom, (Self.handleAreaHeight - Self.handleThickness) / 2)
        }
        .frame(maxWidth: .infinity)
        .frame(height: Self.handleAreaHeight + handleTopInset, alignment: .bottom)
        .contentShape(LeadingEdgeExcludedRectangle(excludedWidth: systemBackGestureEdgeWidth))
        .highPriorityGesture(handleDragGesture(expandedTop: expandedTop, collapsedTop: collapsedTop))
    }

    private var collapsedHeader: some View {
        collapsedHeaderView(onExpand: {
            animateSheet {
                sheetState = .expanded
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
                leadingGestureExclusionWidth: systemBackGestureEdgeWidth,
                disablesUpvote: suppressesCollapsedUpvote,
                matchedGeometryNamespace: postHeaderNamespace,
                isMatchedGeometrySource: isCollapsed
            )
        } else {
            CollapsedPostHeaderLoadingView()
        }
    }

    private func handleCollapsedUpvote(for post: Post) {
        guard !suppressesCollapsedUpvote else { return }
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
            sheetState = .collapsed
            dragTranslation = 0
            isTrackingDrag = false
            dragStartAllowsSheetDrag = false
            isHandleDragActive = false
        }
    }

    private func dismissBrowser() {
        onDismiss()
    }
}

private extension PostCommentsSheet {
    private func updateCollapsedHeight(_ newValue: CGFloat) {
        let updated = ceil(newValue)
        guard updated.isFinite, updated > 0 else { return }
        let totalHeight = updated + handleAreaHeight
        guard abs(totalHeight - collapsedHeight) > 0.5 else { return }
        collapsedHeight = totalHeight
    }

    private func updateControlsHeight(_ newValue: CGFloat) {
        let updated = ceil(newValue)
        guard updated.isFinite, updated > 0 else { return }
        guard abs(updated - controlsHeight) > 0.5 else { return }
        controlsHeight = updated
    }

    private func updateExpandedToolbarVisibility(isExpanded: Bool) {
        if isExpanded {
            showsExpandedToolbar = false
            DispatchQueue.main.asyncAfter(deadline: .now() + WebViewAnimations.revealDelay) {
                guard self.isExpanded else { return }
                withAnimation(WebViewAnimations.fast) {
                    showsExpandedToolbar = true
                }
            }
        } else {
            showsExpandedToolbar = false
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
        if let bounds = PresentationContextProvider.shared.keyWindow?.bounds,
           bounds.width > 0,
           bounds.height > 0 {
            return bounds.size
        }
        return proxy.size
    }

    private func sheetDragGesture(expandedTop: CGFloat, collapsedTop: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 6, coordinateSpace: .global)
            .onChanged { value in
                guard !isHandleDragActive else { return }
                guard value.startLocation.x > systemBackGestureEdgeWidth else { return }
                let verticalMovement = abs(value.translation.height)
                let horizontalMovement = abs(value.translation.width)
                let isMostlyVertical = verticalMovement > horizontalMovement * 1.2

                if !isTrackingDrag {
                    let startsSheetDrag = isCollapsed
                        || (isExpanded && isScrollAtTop && isMostlyVertical && value.translation.height > 0)
                    guard startsSheetDrag else { return }
                    dragStartAllowsSheetDrag = true
                    isTrackingDrag = true
                    suppressesCollapsedUpvote = true
                }
                guard dragStartAllowsSheetDrag else { return }
                dragTranslation = isExpanded ? max(0, value.translation.height) : value.translation.height
            }
            .onEnded { value in
                guard !isHandleDragActive else { return }
                guard value.startLocation.x > systemBackGestureEdgeWidth else {
                    resetDragTracking()
                    return
                }
                guard dragStartAllowsSheetDrag else {
                    resetDragTracking()
                    return
                }
                settleSheet(predictedTranslation: value.predictedEndTranslation.height, expandedTop, collapsedTop)
            }
    }

    private func handleDragGesture(expandedTop: CGFloat, collapsedTop: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .global)
            .onChanged { value in
                guard value.startLocation.x > systemBackGestureEdgeWidth else { return }
                if !isHandleDragActive {
                    suppressesCollapsedUpvote = true
                }
                isHandleDragActive = true
                dragTranslation = value.translation.height
            }
            .onEnded { value in
                guard value.startLocation.x > systemBackGestureEdgeWidth else {
                    isHandleDragActive = false
                    resetDragTracking()
                    return
                }
                settleSheet(predictedTranslation: value.predictedEndTranslation.height, expandedTop, collapsedTop)
                isHandleDragActive = false
            }
    }

    private func expandedToolbarDragGesture(expandedTop: CGFloat, collapsedTop: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 18, coordinateSpace: .global)
            .onChanged { value in
                guard isExpanded, !isHandleDragActive else { return }
                guard value.startLocation.x > systemBackGestureEdgeWidth else { return }

                let verticalMovement = abs(value.translation.height)
                let horizontalMovement = abs(value.translation.width)
                let isDownwardDrag = value.translation.height > 0
                let isMostlyVertical = verticalMovement > horizontalMovement * 1.2

                guard isDownwardDrag, isMostlyVertical else { return }
                if !isTrackingDrag {
                    isTrackingDrag = true
                    dragStartAllowsSheetDrag = true
                    suppressesCollapsedUpvote = true
                }
                dragTranslation = max(0, value.translation.height)
            }
            .onEnded { value in
                guard isTrackingDrag, dragStartAllowsSheetDrag else {
                    resetDragTracking()
                    return
                }
                settleSheet(predictedTranslation: value.predictedEndTranslation.height, expandedTop, collapsedTop)
            }
    }

    private func settleSheet(predictedTranslation: CGFloat, _ expandedTop: CGFloat, _ collapsedTop: CGFloat) {
        let baseTop = isExpanded ? expandedTop : collapsedTop
        let predictedTop = baseTop + predictedTranslation
        let midpoint = (expandedTop + collapsedTop) / 2
        let targetState: SheetState = predictedTop <= midpoint ? .expanded : .collapsed
        animateSheet {
            dragTranslation = 0
            sheetState = targetState
        }
        isTrackingDrag = false
        dragStartAllowsSheetDrag = false
        scheduleCollapsedUpvoteReenable()
    }

    private var systemBackGestureEdgeWidth: CGFloat {
        let leadingInset = PresentationContextProvider.shared.keyWindow?.safeAreaInsets.left ?? 0
        return leadingInset + 56
    }

    private func resetDragTracking() {
        isTrackingDrag = false
        dragStartAllowsSheetDrag = false
        dragTranslation = 0
        scheduleCollapsedUpvoteReenable()
    }

    private func scheduleCollapsedUpvoteReenable() {
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.sheetAnimationDuration) {
            guard !isTrackingDrag, !isHandleDragActive else { return }
            suppressesCollapsedUpvote = false
        }
    }
}

enum SheetState {
    case collapsed
    case expanded
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
