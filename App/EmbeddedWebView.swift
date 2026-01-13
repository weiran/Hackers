//
//  EmbeddedWebView.swift
//  Hackers
//
//  Created by Codex on 2025-09-18.
//

import Comments
import DesignSystem
import Domain
import Foundation
import Shared
import SwiftUI
import UIKit
import WebKit

@MainActor
final class BrowserController: ObservableObject {
    @Published var currentURL: URL?
    @Published var currentTitle: String?
    @Published var canGoBack = false
    @Published var canGoForward = false
    var fallbackURL: URL?
    let page = WebPage()

    func load(_ target: URL) {
        fallbackURL = target
        guard currentURL != target else { return }
        currentURL = target
        _ = page.load(target)
        updateState()
    }

    func updateState() {
        currentURL = page.url ?? currentURL ?? fallbackURL
        currentTitle = page.title
        let list = page.backForwardList
        canGoBack = !list.backList.isEmpty
        canGoForward = !list.forwardList.isEmpty
    }

    func reload() {
        _ = page.reload()
        updateState()
    }

    func goBack() {
        guard let item = page.backForwardList.backList.last else { return }
        _ = page.load(item)
        updateState()
    }

    func goForward() {
        guard let item = page.backForwardList.forwardList.first else { return }
        _ = page.load(item)
        updateState()
    }
}

struct EmbeddedWebView: View {
    let url: URL
    let onDismiss: @MainActor () -> Void
    let showsCloseButton: Bool
    let showsToolbar: Bool
    @StateObject private var controller: BrowserController

    init(
        url: URL,
        onDismiss: @MainActor @escaping () -> Void,
        showsCloseButton: Bool,
        showsToolbar: Bool = true,
        controller: BrowserController? = nil
    ) {
        self.url = url
        self.onDismiss = onDismiss
        self.showsCloseButton = showsCloseButton
        self.showsToolbar = showsToolbar
        _controller = StateObject(wrappedValue: controller ?? BrowserController())
    }

    var body: some View {
        WebView(controller.page)
            .task(id: url) { await load(url) }
            .task { await monitorNavigations() }
            .toolbar {
                if showsToolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        shareButton
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        openInSafariButton
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        if showsCloseButton {
                            closeButton
                        }
                    }
                    if isPadLayout {
                        ToolbarItemGroup(placement: .bottomBar) {
                            Button {
                                controller.goBack()
                            } label: {
                                Image(systemName: "chevron.backward")
                            }
                            .accessibilityLabel("Back")
                            .disabled(!controller.canGoBack)

                            Button {
                                controller.goForward()
                            } label: {
                                Image(systemName: "chevron.forward")
                            }
                            .accessibilityLabel("Forward")
                            .disabled(!controller.canGoForward)

                            Button {
                                controller.reload()
                            } label: {
                                Image(systemName: "arrow.clockwise")
                            }
                            .accessibilityLabel("Reload")
                        }
                    }
                }
            }
    }

    private var isPadLayout: Bool {
        #if targetEnvironment(macCatalyst)
        return true
        #else
        return UIDevice.current.userInterfaceIdiom == .pad || ProcessInfo.processInfo.isiOSAppOnMac
        #endif
    }

    private var shareButton: some View {
        Button {
            Task { @MainActor in
                let targetURL = controller.currentURL ?? url
                ContentSharePresenter.shared.shareURL(targetURL, title: controller.currentTitle)
            }
        } label: {
            Image(systemName: "square.and.arrow.up")
        }
        .accessibilityLabel("Share")
    }

    private var openInSafariButton: some View {
        Button {
            Task { @MainActor in
                let targetURL = controller.currentURL ?? url
                LinkOpener.openURL(targetURL)
            }
        } label: {
            Image(systemName: "safari")
        }
        .accessibilityLabel("Open in Safari")
    }

    private var closeButton: some View {
        Button {
            Task { @MainActor in onDismiss() }
        } label: {
            Image(systemName: "xmark")
        }
        .accessibilityLabel("Close")
    }

    @MainActor
    private func load(_ target: URL) async {
        controller.load(target)
    }

    @MainActor
    private func monitorNavigations() async {
        controller.updateState()
        do {
            for try await _ in controller.page.navigations {
                controller.updateState()
            }
        } catch {
            // Ignore navigation stream errors; state updates happen on successful events.
        }
    }
}

struct PostLinkBrowserView: View {
    @Environment(\.dismiss) private var dismiss
    let post: Post
    @State private var showingCommentsPane = false
    @StateObject private var browserController = BrowserController()

    var body: some View {
        ZStack(alignment: .bottom) {
            EmbeddedWebView(
                url: post.url,
                onDismiss: { dismiss() },
                showsCloseButton: false,
                showsToolbar: false,
                controller: browserController
            )

            if showingCommentsPane {
                PostCommentsSheet(
                    post: post,
                    controller: browserController,
                    onDismiss: { dismiss() }
                )
                .transition(.move(edge: .bottom))
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .task {
            withAnimation(.easeInOut(duration: 0.25)) {
                showingCommentsPane = true
            }
        }
        .background(InteractivePopGestureEnabler().allowsHitTesting(false))
    }
}

private struct InteractivePopGestureEnabler: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController {
        let controller = UIViewController()
        controller.view.backgroundColor = .clear
        return controller
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        guard let navigationController = uiViewController.navigationController else { return }
        context.coordinator.navigationController = navigationController
        if navigationController.interactivePopGestureRecognizer?.delegate !== context.coordinator {
            navigationController.interactivePopGestureRecognizer?.delegate = context.coordinator
        }
        navigationController.interactivePopGestureRecognizer?.isEnabled = true
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        weak var navigationController: UINavigationController?

        func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            (navigationController?.viewControllers.count ?? 0) > 1
        }

        func gestureRecognizer(
            _ gestureRecognizer: UIGestureRecognizer,
            shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
        ) -> Bool {
            true
        }
    }
}

private struct PostCommentsSheet: View {
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
            let collapsedTop = max(
                screenSize.height - (collapsedHeight + safeInsets.bottom),
                expandedTop
            )
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
            .animation(.easeInOut(duration: 0.25), value: sheetState)
            .animation(.easeInOut(duration: 0.2), value: collapsedHeight)
            .onPreferenceChange(CollapsedHeaderHeightPreferenceKey.self) { newValue in
                let updated = ceil(newValue)
                guard updated.isFinite, updated > 0 else { return }
                let totalHeight = updated + handleAreaHeight
                guard abs(totalHeight - collapsedHeight) > 0.5 else { return }
                collapsedHeight = totalHeight
            }
            .onPreferenceChange(ControlsHeightPreferenceKey.self) { newValue in
                let updated = ceil(newValue)
                guard updated.isFinite, updated > 0 else { return }
                guard abs(updated - controlsHeight) > 0.5 else { return }
                controlsHeight = updated
            }
            .onChange(of: isExpanded) { _, newValue in
                if newValue {
                    showsExpandedToolbar = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        guard isExpanded else { return }
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showsExpandedToolbar = true
                        }
                    }
                } else {
                    showsExpandedToolbar = false
                }
            }
        }
    }

    private var isExpanded: Bool {
        sheetState == .expanded
    }

    private var isCollapsed: Bool {
        !isExpanded
    }

    private func collapseSheet() {
        guard isExpanded else { return }
        withAnimation(.easeInOut(duration: 0.2)) {
            sheetState = .collapsed
            dragTranslation = 0
            isTrackingDrag = false
            dragStartAllowsSheetDrag = false
            isHandleDragActive = false
        }
    }

    private var handleAreaHeight: CGFloat {
        Self.handleThickness + (Self.handleVerticalPadding * 2)
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
                .opacity(isExpanded ? 1 : 0)
                .allowsHitTesting(isExpanded)

                collapsedHeader
                    .opacity(isExpanded ? 0 : 1)
                    .allowsHitTesting(!isExpanded)
            }
        }
        .contentShape(Rectangle())
        .simultaneousGesture(sheetDragGesture(expandedTop: expandedTop, collapsedTop: collapsedTop))
        .animation(.easeInOut(duration: 0.25), value: isExpanded)
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
        collapsedHeaderView(onExpand: { sheetState = .expanded })
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

    private var sheetShape: UnevenRoundedRectangle {
        UnevenRoundedRectangle(
            topLeadingRadius: 24,
            bottomLeadingRadius: 0,
            bottomTrailingRadius: 0,
            topTrailingRadius: 24
        )
    }

    private var sheetBackground: some View {
        sheetShape
            .fill(.background)
    }


    private func resolvedSafeAreaInsets(for proxy: GeometryProxy) -> UIEdgeInsets {
        let insets = proxy.safeAreaInsets
        if insets.top != 0 || insets.leading != 0 || insets.bottom != 0 || insets.trailing != 0 {
            return UIEdgeInsets(
                top: insets.top,
                left: insets.leading,
                bottom: insets.bottom,
                right: insets.trailing
            )
        }
        return PresentationContextProvider.shared.windowScene?.windows.first?.safeAreaInsets ?? .zero
    }

    private func resolvedScreenSize(for proxy: GeometryProxy) -> CGSize {
        if let bounds = PresentationContextProvider.shared.windowScene?.windows.first?.bounds,
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
                let baseTop = isExpanded ? expandedTop : collapsedTop
                let predictedTop = baseTop + value.predictedEndTranslation.height
                let midpoint = (expandedTop + collapsedTop) / 2
                withAnimation(.easeInOut(duration: 0.2)) {
                    dragTranslation = 0
                    if predictedTop <= midpoint {
                        sheetState = .expanded
                    } else {
                        sheetState = .collapsed
                    }
                }
                isTrackingDrag = false
                dragStartAllowsSheetDrag = false
            }
    }

    private func handleDragGesture(expandedTop: CGFloat, collapsedTop: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .global)
            .onChanged { value in
                isHandleDragActive = true
                dragTranslation = value.translation.height
            }
            .onEnded { value in
                let baseTop = isExpanded ? expandedTop : collapsedTop
                let predictedTop = baseTop + value.predictedEndTranslation.height
                let midpoint = (expandedTop + collapsedTop) / 2
                withAnimation(.easeInOut(duration: 0.2)) {
                    dragTranslation = 0
                    if predictedTop <= midpoint {
                        sheetState = .expanded
                    } else {
                        sheetState = .collapsed
                    }
                }
                isTrackingDrag = false
                dragStartAllowsSheetDrag = false
                isHandleDragActive = false
            }
    }
}

private enum SheetState {
    case collapsed
    case expanded
}

private struct BrowserControlsView: View {
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
        let inset = PresentationContextProvider.shared.windowScene?.windows.first?.safeAreaInsets.left ?? 0
        return max(inset, 12)
    }

    private var safeInsetPaddingRight: CGFloat {
        let inset = PresentationContextProvider.shared.windowScene?.windows.first?.safeAreaInsets.right ?? 0
        return max(inset, 12)
    }

    private var navigationControlsGroup: some View {
        HStack(spacing: 18) {
            controlButton(systemName: "chevron.backward", isEnabled: controller.canGoBack) {
                controller.goBack()
            }

            controlButton(systemName: "chevron.forward", isEnabled: controller.canGoForward) {
                controller.goForward()
            }

            controlButton(systemName: "arrow.clockwise") {
                controller.reload()
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .modifier(GlassCapsuleBackground())
        .shadow(color: .black.opacity(0.2), radius: 12, x: 0, y: 6)
    }

    private var shareControlsGroup: some View {
        HStack(spacing: 18) {
            controlButton(systemName: "square.and.arrow.up") {
                Task { @MainActor in
                    let targetURL = controller.currentURL ?? fallbackURL
                    ContentSharePresenter.shared.shareURL(targetURL, title: controller.currentTitle)
                }
            }

            controlButton(systemName: "safari") {
                let targetURL = controller.currentURL ?? fallbackURL
                LinkOpener.openURL(targetURL)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
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
                .frame(width: 20, height: 20)
        }
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
        case "square.and.arrow.up":
            return "Share"
        case "safari":
            return "Open in Safari"
        case "xmark":
            return "Close"
        default:
            return "Button"
        }
    }
}

private struct GlassCapsuleBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .glassEffect(.regular.interactive(), in: .capsule)
    }
}

private struct GlassCircleBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .glassEffect(.regular.interactive(), in: .circle)
    }
}

private enum ControlsHeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

private struct CollapsedPostHeaderView: View {
    @Environment(\.colorScheme) private var colorScheme
    let post: Post
    let votingState: VotingState?
    let isLoading: Bool
    let onUpvote: () -> Void
    let onExpand: () -> Void
    private static let collapsedVerticalPadding: CGFloat = 2
    private static let collapsedHorizontalPadding: CGFloat = 20
    private static let collapsedThumbnailSize: CGFloat = 28

    var body: some View {
        HStack(spacing: 12) {
            ThumbnailView(url: post.url, isEnabled: true)
                .frame(width: Self.collapsedThumbnailSize, height: Self.collapsedThumbnailSize)
                .clipShape(.rect(cornerRadius: min(16, Self.collapsedThumbnailSize * 0.3)))

            Text(domainText)
                .scaledFont(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)

            Spacer(minLength: 8)

            HStack(spacing: 8) {
                upvoteButton
                commentsPill
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, Self.collapsedHorizontalPadding)
        .padding(.vertical, Self.collapsedVerticalPadding)
        .contentShape(Rectangle())
        .onTapGesture(perform: onExpand)
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
        .disabled(!canInteract)
        .opacity(canInteract ? 1 : 0.55)
        .accessibilityLabel(isUpvoted ? "Upvoted" : "Upvote")
    }
}

private struct CollapsedPostHeaderLoadingView: View {
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

private enum CollapsedHeaderHeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}
