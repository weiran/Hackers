import Comments
import DesignSystem
import Domain
import Shared
import SwiftUI
import UIKit

// swiftlint:disable type_body_length

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
    private static let expandedHandleHitTargetHeight: CGFloat = 44
    private static let expandedHandleHitTargetWidth: CGFloat = 160
    private static let navigationBarHeight: CGFloat = 44
    private static let expandedContentSpacing: CGFloat = 8
    private static let expandedTopDragTrailingPassthroughWidth: CGFloat = 88
    private static let toolbarControlExclusionWidth: CGFloat = 88
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
    @State private var expandedTitleVisibility = CommentsHeaderTitleVisibility()
    @State private var toolbarGeometry = CommentsToolbarGeometry()
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
            let containerSize = resolvedContainerSize(for: proxy)
            let expandedHandleAreaHeight = max(
                proxy.safeAreaInsets.top - safeInsets.top,
                Self.navigationBarHeight
            )
            let layout = PostCommentsSheetLayout(
                safeInsets: safeInsets,
                containerSize: containerSize,
                commentsHorizontalInsets: (
                    proxy.safeAreaInsets.leading,
                    proxy.safeAreaInsets.trailing
                ),
                collapsedHeight: collapsedHeight,
                controlsHeight: controlsHeight,
                dragTranslation: presentation.dragTranslation,
                isExpanded: presentation.isExpanded,
                expandedCommentsTopInset: expandedCommentsTopInset(handleTopInset:)
            )
            let currentChromeAreaHeight = Self.handleAreaHeight
                + ((expandedHandleAreaHeight - Self.handleAreaHeight) * layout.expansionProgress)
            let showsExpandedPresentation = viewModel.post != nil
            let titleMaximumWidth = max(
                containerSize.width
                    - proxy.safeAreaInsets.leading
                    - proxy.safeAreaInsets.trailing
                    - (Self.toolbarControlExclusionWidth * 2),
                0
            )
            let toolbarControlCenterY = toolbarGeometry.controlCenterY.map {
                $0 - layout.alignedTop
            }

            ZStack(alignment: .topLeading) {
                Color.clear.allowsHitTesting(false)

                sheetContent(
                    layout: layout,
                    isInteractiveMove: presentation.isInteractiveMove,
                    chromeAreaHeight: currentChromeAreaHeight,
                    titleMaximumWidth: titleMaximumWidth,
                    toolbarControlCenterY: toolbarControlCenterY,
                    showsExpandedPresentation: showsExpandedPresentation
                )
                .frame(width: layout.containerSize.width, height: layout.containerSize.height, alignment: .top)
                .background(sheetBackground)
                .clipShape(sheetShape)
                .shadow(
                    color: .black.opacity(0.12),
                    radius: 10,
                    x: 0,
                    y: -5
                )
                .offset(y: layout.alignedTop)

                CollapsedBrowserControlsOverlay(
                    isVisible: presentation.showsCollapsedControls,
                    fallbackURL: fallbackURL,
                    onDismiss: onDismiss,
                    controller: browserController
                )
                .frame(width: layout.containerSize.width, alignment: .center)
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
            .frame(width: layout.containerSize.width, height: layout.containerSize.height, alignment: .topLeading)
            .ignoresSafeArea(.container)
            .overlay {
                ExpandedCommentsTopDragHitArea(
                    isEnabled: showsExpandedPresentation && presentation.isExpanded,
                    hitAreaTop: layout.alignedTop,
                    hitAreaHeight: expandedTopDragHitAreaHeight(handleTopInset: layout.handleTopInset),
                    leadingPassthroughWidth: systemBackGestureEdgeWidth,
                    trailingPassthroughWidth: Self.expandedTopDragTrailingPassthroughWidth,
                    onTap: collapseSheet,
                    onDragChanged: { translation in
                        presentation.updateHandleDrag(translationHeight: max(0, translation.height))
                    },
                    onDragEnded: { translation, predictedTranslationHeight in
                        presentation.updateHandleDrag(
                            translationHeight: max(0, translation.height, predictedTranslationHeight)
                        )
                        guard presentation.canEndHandleDrag() else {
                            scheduleCollapsedUpvoteReenable()
                            return
                        }
                        settleSheet(predictedTranslation: predictedTranslationHeight, layout.expandedTop, layout.collapsedTop)
                    },
                    onDragCancelled: {
                        animateSheet(WebViewAnimations.fast) {
                            presentation.cancelHandleDrag()
                        }
                        scheduleCollapsedUpvoteReenable()
                    }
                )
                .frame(width: 0, height: 0)
            }
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
        layout: PostCommentsSheetLayout,
        isInteractiveMove: Bool,
        chromeAreaHeight: CGFloat,
        titleMaximumWidth: CGFloat,
        toolbarControlCenterY: CGFloat?,
        showsExpandedPresentation: Bool
    ) -> some View {
        ZStack(alignment: .top) {
            if showsExpandedPresentation {
                expandedCommentsView(
                    layout: layout,
                    showsPostHeader: true
                )
                .overlay {
                    if layout.contentFadeProgress < 0.01 {
                        Rectangle()
                            .fill(.background)
                            .allowsHitTesting(false)
                    } else if !isInteractiveMove, layout.contentFadeProgress < 1 {
                        Rectangle()
                            .fill(.background)
                            .opacity(1 - layout.contentFadeProgress)
                            .allowsHitTesting(false)
                    }
                }
                .allowsHitTesting(layout.contentFadeProgress >= 0.5)
                .accessibilityHidden(layout.contentFadeProgress < 0.5)
                .simultaneousGesture(
                    sheetDragGesture(expandedTop: layout.expandedTop, collapsedTop: layout.collapsedTop)
                )
            }

            VStack(spacing: 0) {
                Color.clear
                    .frame(height: Self.handleAreaHeight + layout.handleTopInset)

                collapsedHeader
                    .allowsHitTesting(true)
                    .simultaneousGesture(
                        sheetDragGesture(expandedTop: layout.expandedTop, collapsedTop: layout.collapsedTop)
                    )
            }
            .opacity(1 - layout.contentFadeProgress)
            .allowsHitTesting(layout.contentFadeProgress < 0.5)
            .accessibilityHidden(layout.contentFadeProgress >= 0.5)

            sheetHandle(
                expandedTop: layout.expandedTop,
                collapsedTop: layout.collapsedTop,
                handleTopInset: layout.handleTopInset,
                chromeAreaHeight: chromeAreaHeight,
                titleMaximumWidth: titleMaximumWidth,
                toolbarControlCenterY: toolbarControlCenterY,
                titleProgress: titleChromeProgress(contentFadeProgress: layout.contentFadeProgress)
            )
        }
    }

    private func expandedCommentsView(
        layout: PostCommentsSheetLayout,
        showsPostHeader: Bool
    ) -> some View {
        let viewport = layout.commentsViewport

        return StableCommentsHost(
            postID: viewModel.postID,
            topContentInset: layout.expandedCommentsTopInset,
            showsPostHeader: showsPostHeader,
            scrollDisabled: !isExpanded || presentation.isInteractiveMove,
            viewModel: viewModel,
            votingViewModel: votingViewModel,
            postHeaderMatchedGeometryNamespace: postHeaderNamespace,
            isPostHeaderMatchedGeometrySource: isExpanded,
            titleVisibility: expandedTitleVisibility,
            toolbarGeometry: toolbarGeometry,
            showsToolbar: isExpanded,
            dragExpandedTop: layout.expandedTop,
            dragCollapsedTop: layout.collapsedTop,
            onPostLinkTap: collapseSheet,
            onTitleDragChanged: { value in
                presentation.updateExpandedToolbarDrag(
                    startX: value.startLocation.x,
                    translation: value.translation,
                    systemBackGestureEdgeWidth: systemBackGestureEdgeWidth
                )
            },
            onTitleDragEnded: { value in
                guard presentation.canEndExpandedToolbarDrag() else {
                    scheduleCollapsedUpvoteReenable()
                    return
                }
                settleSheet(
                    predictedTranslation: value.predictedEndTranslation.height,
                    layout.expandedTop,
                    layout.collapsedTop
                )
            }
        )
        .equatable()
        .frame(width: viewport.width, height: viewport.height, alignment: .topLeading)
        .onScrollPhaseChange { oldPhase, newPhase, context in
            let offsetY = context.geometry.contentOffset.y + context.geometry.contentInsets.top
            presentation.updateScrollDragEligibility(
                oldPhase: oldPhase,
                newPhase: newPhase,
                isAtRestingTop: abs(offsetY) <= 1
            )
        }
        .offset(x: viewport.minX, y: viewport.minY)
        .frame(
            width: layout.containerSize.width,
            height: layout.containerSize.height,
            alignment: .topLeading
        )
    }

    private func expandedCommentsTopInset(handleTopInset: CGFloat) -> CGFloat {
        handleTopInset + Self.navigationBarHeight + Self.expandedContentSpacing
    }

    private func expandedTopDragHitAreaHeight(handleTopInset: CGFloat) -> CGFloat {
        handleTopInset
            + Self.navigationBarHeight
            + Self.expandedContentSpacing
    }

    private func sheetHandle(
        expandedTop: CGFloat,
        collapsedTop: CGFloat,
        handleTopInset: CGFloat,
        chromeAreaHeight: CGFloat,
        titleMaximumWidth: CGFloat,
        toolbarControlCenterY: CGFloat?,
        titleProgress: CGFloat
    ) -> some View {
        let handleHitTargetHeight = handleTopInset > 0 ? Self.expandedHandleHitTargetHeight : Self.handleAreaHeight

        return ZStack(alignment: .top) {
            CommentsSheetTopChrome(
                post: viewModel.post,
                showThumbnails: viewModel.showThumbnails,
                titleProgress: titleProgress,
                isInteractiveMove: presentation.isInteractiveMove,
                handleTopInset: handleTopInset,
                chromeAreaHeight: chromeAreaHeight,
                titleMaximumWidth: titleMaximumWidth,
                toolbarControlCenterY: toolbarControlCenterY,
                handleWidth: Self.handleWidth,
                handleThickness: Self.handleThickness,
                navigationBarHeight: Self.navigationBarHeight,
                onTitleTap: collapseSheet
            )
            .simultaneousGesture(titlePillDragGesture(expandedTop: expandedTop, collapsedTop: collapsedTop))
            .allowsHitTesting(titleProgress > 0.5)

            HStack {
                Spacer()

                Rectangle()
                    .fill(.background.opacity(0.001))
                    .frame(width: Self.expandedHandleHitTargetWidth, height: handleHitTargetHeight)
                    .contentShape(Rectangle())
                    .highPriorityGesture(handleDragGesture(expandedTop: expandedTop, collapsedTop: collapsedTop))
                    .allowsHitTesting(titleProgress <= 0.5)
                    .accessibilityElement()
                    .accessibilityLabel("Comments sheet handle")
                    .accessibilityIdentifier("browser.commentsSheet.handle")
                    .accessibilityHidden(titleProgress > 0.5)

                Spacer()
            }
            .padding(.top, handleTopInset)
        }
        .frame(maxWidth: .infinity)
        .frame(height: Self.navigationBarHeight + handleTopInset, alignment: .top)
    }

    private func titleChromeProgress(contentFadeProgress: CGFloat) -> CGFloat {
        guard expandedTitleVisibility.isVisible else { return 0 }
        return min(max(contentFadeProgress, 0), 1)
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

    private func resolvedContainerSize(for proxy: GeometryProxy) -> CGSize {
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
                    systemBackGestureEdgeWidth: systemBackGestureEdgeWidth
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
                presentation.updateHandleDrag(translationHeight: value.translation.height)
            }
            .onEnded { value in
                if !presentation.canEndHandleDrag() {
                    let endTranslation = value.translation.height > 0
                        ? value.translation.height
                        : value.predictedEndTranslation.height
                    presentation.updateHandleDrag(translationHeight: endTranslation)
                }
                guard presentation.canEndHandleDrag() else {
                    scheduleCollapsedUpvoteReenable()
                    return
                }
                settleSheet(predictedTranslation: value.predictedEndTranslation.height, expandedTop, collapsedTop)
            }
    }

    private func titlePillDragGesture(expandedTop: CGFloat, collapsedTop: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 18, coordinateSpace: .global)
            .onChanged { value in
                presentation.updateExpandedToolbarDrag(
                    startX: value.startLocation.x,
                    translation: value.translation,
                    systemBackGestureEdgeWidth: systemBackGestureEdgeWidth
                )
            }
            .onEnded { value in
                guard presentation.canEndExpandedToolbarDrag() else {
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

// SwiftUI toolbar items can sit above the sheet content, so this installs a
// transparent window hit area that handles the title zone while leaving the
// leading and trailing toolbar button zones tappable.
private struct ExpandedCommentsTopDragHitArea: UIViewRepresentable {
    let isEnabled: Bool
    let hitAreaTop: CGFloat
    let hitAreaHeight: CGFloat
    let leadingPassthroughWidth: CGFloat
    let trailingPassthroughWidth: CGFloat
    let onTap: () -> Void
    let onDragChanged: (_ translation: CGSize) -> Void
    let onDragEnded: (_ translation: CGSize, _ predictedTranslationHeight: CGFloat) -> Void
    let onDragCancelled: () -> Void

    func makeUIView(context: Context) -> WindowAttachmentObserverView {
        let view = WindowAttachmentObserverView()
        view.isUserInteractionEnabled = false
        view.onWindowChange = { [weak coordinator = context.coordinator] window in
            coordinator?.attach(to: window)
        }
        return view
    }

    func updateUIView(_ uiView: WindowAttachmentObserverView, context: Context) {
        context.coordinator.update(self)
        context.coordinator.attach(to: uiView.window)
    }

    static func dismantleUIView(_ uiView: WindowAttachmentObserverView, coordinator: Coordinator) {
        coordinator.detach()
        uiView.onWindowChange = nil
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        private var recognizer: UIPanGestureRecognizer?
        private var tapRecognizer: UITapGestureRecognizer?
        private weak var installedWindow: UIWindow?
        private weak var hitAreaView: WindowTopDragHitAreaView?
        private var configuration: ExpandedCommentsTopDragHitArea
        private var hasActiveDrag = false

        init(_ configuration: ExpandedCommentsTopDragHitArea) {
            self.configuration = configuration
            super.init()
        }

        func update(_ configuration: ExpandedCommentsTopDragHitArea) {
            self.configuration = configuration
            updateHitAreaConfiguration()
        }

        func attach(to window: UIWindow?) {
            guard installedWindow !== window else { return }
            detach()
            guard let window else { return }

            let hitAreaView = WindowTopDragHitAreaView()
            hitAreaView.backgroundColor = .clear
            hitAreaView.frame = window.bounds
            hitAreaView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

            let recognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
            recognizer.cancelsTouchesInView = false
            recognizer.delaysTouchesBegan = false
            recognizer.delaysTouchesEnded = false
            recognizer.delegate = self
            hitAreaView.addGestureRecognizer(recognizer)

            let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap))
            tapRecognizer.cancelsTouchesInView = false
            hitAreaView.addGestureRecognizer(tapRecognizer)
            window.addSubview(hitAreaView)

            installedWindow = window
            self.hitAreaView = hitAreaView
            self.recognizer = recognizer
            self.tapRecognizer = tapRecognizer
            updateHitAreaConfiguration()
        }

        func detach() {
            hitAreaView?.removeFromSuperview()
            recognizer = nil
            tapRecognizer = nil
            installedWindow = nil
            hitAreaView = nil
            hasActiveDrag = false
        }

        private func updateHitAreaConfiguration() {
            recognizer?.isEnabled = configuration.isEnabled
            tapRecognizer?.isEnabled = configuration.isEnabled
            hitAreaView?.isDragHitTestingEnabled = configuration.isEnabled
            hitAreaView?.hitAreaTop = configuration.hitAreaTop
            hitAreaView?.hitAreaHeight = configuration.hitAreaHeight
            hitAreaView?.leadingPassthroughWidth = configuration.leadingPassthroughWidth
            hitAreaView?.trailingPassthroughWidth = configuration.trailingPassthroughWidth
            if let installedWindow, let hitAreaView {
                hitAreaView.frame = installedWindow.bounds
                installedWindow.bringSubviewToFront(hitAreaView)
            }
        }

        func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            guard configuration.isEnabled,
                  let pan = gestureRecognizer as? UIPanGestureRecognizer,
                  let view = gestureRecognizer.view
            else { return false }

            let velocity = pan.velocity(in: view)
            let verticalMovement = abs(velocity.y)
            let horizontalMovement = abs(velocity.x)
            let isMostlyVertical = verticalMovement > horizontalMovement * PostCommentsSheetMetrics.verticalDragBias
            return velocity.y > 0 && isMostlyVertical
        }

        func gestureRecognizer(
            _ gestureRecognizer: UIGestureRecognizer,
            shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
        ) -> Bool {
            true
        }

        @objc private func handlePan(_ recognizer: UIPanGestureRecognizer) {
            guard let view = recognizer.view else { return }

            switch recognizer.state {
            case .began:
                hasActiveDrag = true
                configuration.onDragChanged(.zero)

            case .changed:
                guard hasActiveDrag else { return }
                configuration.onDragChanged(recognizer.translation(in: view).size)

            case .ended:
                guard hasActiveDrag else { return }
                let translation = recognizer.translation(in: view)
                let velocity = recognizer.velocity(in: view)
                let predictedTranslationHeight = translation.y + (velocity.y * 0.2)
                configuration.onDragEnded(
                    translation.size,
                    max(translation.y, predictedTranslationHeight)
                )
                hasActiveDrag = false

            case .cancelled, .failed:
                guard hasActiveDrag else { return }
                configuration.onDragCancelled()
                hasActiveDrag = false

            default:
                break
            }
        }

        @objc private func handleTap() {
            configuration.onTap()
        }
    }
}

private final class WindowAttachmentObserverView: UIView {
    var onWindowChange: ((UIWindow?) -> Void)?

    override func didMoveToWindow() {
        super.didMoveToWindow()
        onWindowChange?(window)
    }
}

private final class WindowTopDragHitAreaView: UIView {
    var isDragHitTestingEnabled = false
    var hitAreaTop: CGFloat = 0
    var hitAreaHeight: CGFloat = 0
    var leadingPassthroughWidth: CGFloat = 0
    var trailingPassthroughWidth: CGFloat = 0

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        guard isDragHitTestingEnabled else { return false }
        let trailingStart = bounds.width - trailingPassthroughWidth
        return point.y >= hitAreaTop
            && point.y <= hitAreaTop + hitAreaHeight
            && point.x > leadingPassthroughWidth
            && point.x < trailingStart
    }
}

private extension CGPoint {
    var size: CGSize {
        CGSize(width: x, height: y)
    }
}

private struct CommentsSheetTopChrome: View {
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
                .opacity(glassSurfaceOpacity)

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
