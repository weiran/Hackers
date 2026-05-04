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
    private static let handleVerticalPadding: CGFloat = 8
    private static let controlsSpacing: CGFloat = 12
    private static let navigationBarTopSpacing: CGFloat = 6

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

    init(post: Post, controller: BrowserController, onDismiss: @MainActor @escaping () -> Void) {
        _viewModel = State(initialValue: CommentsViewModel(post: post))
        let container = DependencyContainer.shared
        _votingViewModel = State(initialValue: VotingViewModel(
            votingStateProvider: container.getVotingStateProvider(),
            commentVotingStateProvider: container.getCommentVotingStateProvider(),
            authenticationUseCase: container.getAuthenticationUseCase()
        ))
        _browserController = ObservedObject(wrappedValue: controller)
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
            let sheetHeight = max(screenSize.height - alignedTop, 0)
            let controlsOffset = max(controlsHeight, 44.0) + Self.controlsSpacing
            let controlsTop = alignedTop - controlsOffset
            let handleTopInset = isExpanded ? safeInsets.top : 0

            ZStack(alignment: .topLeading) {
                Color.clear.allowsHitTesting(false)

                sheetContent(
                    expandedTop: expandedTop,
                    collapsedTop: collapsedTop,
                    handleTopInset: handleTopInset
                )
                .frame(width: screenSize.width, height: sheetHeight, alignment: .top)
                .background(sheetBackground)
                .clipShape(sheetShape)
                .shadow(color: .black.opacity(0.12), radius: 10, x: 0, y: -5)
                .offset(y: alignedTop)

                if isCollapsed {
                    BrowserControlsView(
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
        Self.handleThickness + (Self.handleVerticalPadding * 2)
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
        handleTopInset: CGFloat
    ) -> some View {
        VStack(spacing: 0) {
            sheetHandle(
                expandedTop: expandedTop,
                collapsedTop: collapsedTop,
                handleTopInset: handleTopInset
            )

            ZStack(alignment: .top) {
                expandedCommentsView
                    .opacity(isExpanded ? 1 : 0)
                    .allowsHitTesting(isExpanded)

                collapsedHeader
                    .opacity(isExpanded ? 0 : 1)
                    .allowsHitTesting(!isExpanded)
            }
        }
        .contentShape(Rectangle())
        .simultaneousGesture(sheetDragGesture(expandedTop: expandedTop, collapsedTop: collapsedTop))
    }

    private var expandedCommentsView: some View {
        NavigationView {
            CommentsView<NavigationStore>(
                postID: viewModel.postID,
                initialPost: viewModel.post,
                showsPostHeader: isExpanded,
                allowsRefresh: false,
                isAtTop: $isScrollAtTop,
                onPostLinkTap: collapseSheet,
                viewModel: viewModel,
                votingViewModel: votingViewModel
            )
            .scrollDisabled(!isExpanded)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        Task { @MainActor in onDismiss() }
                    } label: {
                        Label("Back", systemImage: "chevron.left")
                    }
                    .accessibilityLabel("Back")
                }
            }
            .toolbar(showsExpandedToolbar ? .visible : .hidden, for: .navigationBar)
        }
        .navigationViewStyle(.stack)
        .padding(.top, isExpanded ? Self.navigationBarTopSpacing : 0)
    }

    private func sheetHandle(
        expandedTop: CGFloat,
        collapsedTop: CGFloat,
        handleTopInset: CGFloat
    ) -> some View {
        ZStack {
            Capsule()
                .fill(.secondary.opacity(0.35))
                .frame(width: Self.handleWidth, height: Self.handleThickness)

            EmptyView()
        }
        .frame(maxWidth: .infinity)
        .padding(.top, Self.handleVerticalPadding + handleTopInset)
        .padding(.bottom, Self.handleVerticalPadding)
        .contentShape(Rectangle())
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
                onExpand: onExpand
            )
        } else {
            CollapsedPostHeaderLoadingView()
        }
    }

    private func handleCollapsedUpvote(for post: Post) {
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

    private func animateSheet(_ animation: Animation = WebViewAnimations.standard, _ updates: () -> Void) {
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
                if !isTrackingDrag {
                    dragStartAllowsSheetDrag = isCollapsed || isScrollAtTop
                    isTrackingDrag = true
                }
                guard dragStartAllowsSheetDrag else { return }
                dragTranslation = value.translation.height
            }
            .onEnded { value in
                guard !isHandleDragActive else { return }
                guard dragStartAllowsSheetDrag else { return }
                settleSheet(predictedTranslation: value.predictedEndTranslation.height, expandedTop, collapsedTop)
            }
    }

    private func handleDragGesture(expandedTop: CGFloat, collapsedTop: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .global)
            .onChanged { value in
                isHandleDragActive = true
                dragTranslation = value.translation.height
            }
            .onEnded { value in
                settleSheet(predictedTranslation: value.predictedEndTranslation.height, expandedTop, collapsedTop)
                isHandleDragActive = false
            }
    }

    private func settleSheet(predictedTranslation: CGFloat, _ expandedTop: CGFloat, _ collapsedTop: CGFloat) {
        let baseTop = isExpanded ? expandedTop : collapsedTop
        let predictedTop = baseTop + predictedTranslation
        let midpoint = (expandedTop + collapsedTop) / 2
        animateSheet {
            dragTranslation = 0
            sheetState = predictedTop <= midpoint ? .expanded : .collapsed
        }
        isTrackingDrag = false
        dragStartAllowsSheetDrag = false
    }
}

enum SheetState {
    case collapsed
    case expanded
}
