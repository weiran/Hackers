import Comments
import DesignSystem
import Domain
import Shared
import SwiftUI

struct PostCommentsSheet: View {
    static let initialCollapsedHeight: CGFloat = PostCommentsSheetMetrics.initialCollapsedHeight
    static let collapsedTopCornerRadius: CGFloat = PostCommentsSheetMetrics.collapsedTopCornerRadius
    static let collapsedDetent: PresentationDetent = .height(PostCommentsSheetMetrics.initialCollapsedHeight)
    static let expandedDetent: PresentationDetent = .large

    static var defaultCollapsedBrowserScrollContentInset: CGFloat {
        PostCommentsSheetMetrics.defaultCollapsedBrowserScrollContentInset
    }

    let onDismiss: @MainActor () -> Void
    let onBrowserScrollContentInsetChange: @MainActor (CGFloat) -> Void
    let fallbackURL: URL
    @ObservedObject private var browserController: BrowserController
    @Binding private var selectedDetent: PresentationDetent
    @State private var viewModel: CommentsViewModel
    @State private var votingViewModel: VotingViewModel
    @State private var controlsHeight: CGFloat = PostCommentsSheetMetrics.collapsedBrowserControlsHeight
    @State private var isScrollAtTop = true
    @State private var expandedTitleVisibility = CommentsHeaderTitleVisibility()
    @Namespace private var postHeaderNamespace

    init(
        post: Post,
        controller: BrowserController,
        selectedDetent: Binding<PresentationDetent>,
        onDismiss: @MainActor @escaping () -> Void,
        onBrowserScrollContentInsetChange: @MainActor @escaping (CGFloat) -> Void = { _ in }
    ) {
        _viewModel = State(initialValue: CommentsViewModel(post: post))
        let container = DependencyContainer.shared
        _votingViewModel = State(initialValue: VotingViewModel(
            votingStateProvider: container.getVotingStateProvider(),
            commentVotingStateProvider: container.getCommentVotingStateProvider(),
            authenticationUseCase: container.getAuthenticationUseCase()
        ))
        _browserController = ObservedObject(wrappedValue: controller)
        _selectedDetent = selectedDetent
        self.onDismiss = onDismiss
        self.onBrowserScrollContentInsetChange = onBrowserScrollContentInsetChange
        fallbackURL = post.url
    }

    var body: some View {
        GeometryReader { proxy in
            sheetContent
                .frame(
                    width: proxy.size.width,
                    height: isExpanded ? proxy.size.height : Self.initialCollapsedHeight,
                    alignment: .top
                )
                .background(.background)
                .clipShape(sheetShape)
                .shadow(color: .black.opacity(isExpanded ? 0 : 0.12), radius: 10, x: 0, y: -5)
                .frame(width: proxy.size.width, height: proxy.size.height, alignment: .bottom)
        }
        .ignoresSafeArea(.container, edges: .bottom)
        .animation(WebViewAnimations.fast, value: isExpanded)
        .onAppear {
            updateBrowserScrollContentInset()
        }
        .onPreferenceChange(ControlsHeightPreferenceKey.self) { updateControlsHeight($0) }
        .onChange(of: controlsHeight) { _, _ in
            updateBrowserScrollContentInset()
        }
        .onChange(of: isExpanded) { _, newValue in
            updateExpandedPresentation(isExpanded: newValue)
        }
        .accessibilityIdentifier("browser.commentsSheet")
    }

    private var sheetContent: some View {
        VStack(spacing: 0) {
            BrowserControlsView(
                fallbackURL: fallbackURL,
                onDismiss: onDismiss,
                controller: browserController
            )
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 12)
            .background(
                GeometryReader { controlsProxy in
                    Color.clear.preference(
                        key: ControlsHeightPreferenceKey.self,
                        value: controlsProxy.size.height
                    )
                }
            )

            if isExpanded {
                expandedCommentsView
                    .transition(.opacity)
            } else {
                collapsedHeader
                    .padding(.bottom, 10)
                    .transition(.opacity)
            }
        }
    }

    private var sheetShape: UnevenRoundedRectangle {
        UnevenRoundedRectangle(
            topLeadingRadius: isExpanded ? 0 : Self.collapsedTopCornerRadius,
            bottomLeadingRadius: 0,
            bottomTrailingRadius: 0,
            topTrailingRadius: isExpanded ? 0 : Self.collapsedTopCornerRadius
        )
    }

    private var isExpanded: Bool {
        selectedDetent == Self.expandedDetent
    }

    private var collapsedHeader: some View {
        collapsedHeaderView(onExpand: expandComments)
    }

    private var expandedCommentsView: some View {
        StableCommentsHost(
            postID: viewModel.postID,
            topContentInset: 0,
            showsPostHeader: true,
            viewModel: viewModel,
            votingViewModel: votingViewModel,
            postHeaderMatchedGeometryNamespace: postHeaderNamespace,
            isPostHeaderMatchedGeometrySource: isExpanded,
            titleVisibility: expandedTitleVisibility,
            isAtTop: $isScrollAtTop,
            onPostLinkTap: collapseComments
        )
        .equatable()
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
                matchedGeometryNamespace: postHeaderNamespace,
                isMatchedGeometrySource: !isExpanded
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

    private func expandComments() {
        selectedDetent = Self.expandedDetent
    }

    private func collapseComments() {
        selectedDetent = Self.collapsedDetent
    }
}

private extension PostCommentsSheet {
    private func updateControlsHeight(_ newValue: CGFloat) {
        let updated = ceil(newValue)
        guard updated.isFinite, updated > 0 else { return }
        guard abs(updated - controlsHeight) > 0.5 else { return }
        controlsHeight = updated
    }

    private func updateBrowserScrollContentInset() {
        let controlsInset = PostCommentsSheetMetrics.browserScrollContentInset(controlsHeight: controlsHeight)
        let sheetInset = PostCommentsSheetMetrics.initialCollapsedHeight + PostCommentsSheetMetrics.collapsedBrowserControlsMargin
        onBrowserScrollContentInsetChange(max(controlsInset, sheetInset))
    }

    private func updateExpandedPresentation(isExpanded: Bool) {
        if !isExpanded {
            withAnimation(.easeInOut(duration: 0.3)) {
                expandedTitleVisibility.setVisible(false)
            }
        }
    }
}

private struct StableCommentsHost: View, @preconcurrency Equatable {
    let postID: Int
    let topContentInset: CGFloat
    let showsPostHeader: Bool
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
    }
}
