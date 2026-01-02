//
//  EmbeddedWebView.swift
//  Hackers
//
//  Created by Codex on 2025-09-18.
//

import Comments
import DesignSystem
import Domain
import Shared
import SwiftUI
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
                    if UIDevice.current.userInterfaceIdiom == .pad {
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
    let post: Post
    @Environment(\.dismiss) private var dismiss
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
    }
}

private struct PostCommentsSheet: View {
    static let initialCollapsedHeight: CGFloat = 150
    private static let handleWidth: CGFloat = 36
    private static let handleThickness: CGFloat = 5
    private static let handleVerticalPadding: CGFloat = 8
    private static let controlsSpacing: CGFloat = 12

    @State private var viewModel: CommentsViewModel
    @State private var votingViewModel: VotingViewModel
    @State private var collapsedHeight: CGFloat = initialCollapsedHeight
    @State private var sheetState: SheetState = .collapsed
    @GestureState private var dragTranslation: CGFloat = 0
    @State private var controlsHeight: CGFloat = 0
    @State private var isScrollAtTop = true
    @ObservedObject private var browserController: BrowserController
    let onDismiss: @MainActor () -> Void
    let fallbackURL: URL

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
            let handleHeight = handleAreaHeight
            let expandedTop = safeInsets.top
            let collapsedTop = max(
                screenSize.height - (collapsedHeight + handleHeight + safeInsets.bottom),
                expandedTop
            )
            let baseTop = isExpanded ? expandedTop : collapsedTop
            let proposedTop = baseTop + dragTranslation
            let clampedTop = min(max(proposedTop, expandedTop), collapsedTop)
            let alignedTop = floor(clampedTop)
            let sheetHeight = ceil(screenSize.height - alignedTop) + 1
            let controlsOffset = max(controlsHeight, 44) + Self.controlsSpacing
            let controlsTop = alignedTop - controlsOffset

            ZStack(alignment: .topLeading) {
                Color.clear.allowsHitTesting(false)

                sheetContent(expandedTop: expandedTop, collapsedTop: collapsedTop)
                    .frame(width: screenSize.width, height: sheetHeight, alignment: .top)
                    .background(sheetBackground)
                    .clipShape(sheetShape)
                    .shadow(color: .black.opacity(0.18), radius: 16, x: 0, y: -6)
                    .offset(y: alignedTop)

                if isCollapsed {
                    BrowserControlsView(
                        controller: browserController,
                        fallbackURL: fallbackURL,
                        onDismiss: onDismiss
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
            .ignoresSafeArea(.container, edges: [.horizontal, .bottom])
            .animation(.easeInOut(duration: 0.25), value: sheetState)
            .animation(.easeInOut(duration: 0.2), value: collapsedHeight)
            .onPreferenceChange(CollapsedHeaderHeightPreferenceKey.self) { newValue in
                let updated = ceil(newValue)
                guard updated.isFinite, updated > 60 else { return }
                guard abs(updated - collapsedHeight) > 0.5 else { return }
                collapsedHeight = updated
            }
            .onPreferenceChange(ControlsHeightPreferenceKey.self) { newValue in
                let updated = ceil(newValue)
                guard updated.isFinite, updated > 0 else { return }
                guard abs(updated - controlsHeight) > 0.5 else { return }
                controlsHeight = updated
            }
        }
    }

    private var isExpanded: Bool {
        sheetState == .expanded
    }

    private var isCollapsed: Bool {
        !isExpanded
    }

    private var shouldAllowSheetDrag: Bool {
        isCollapsed || (isExpanded && isScrollAtTop)
    }

    private var handleAreaHeight: CGFloat {
        Self.handleThickness + (Self.handleVerticalPadding * 2)
    }

    private func sheetContent(expandedTop: CGFloat, collapsedTop: CGFloat) -> some View {
        VStack(spacing: 0) {
            sheetHandle(expandedTop: expandedTop, collapsedTop: collapsedTop)

            ZStack(alignment: .top) {
                CommentsView<NavigationStore>(
                    postID: viewModel.postID,
                    initialPost: viewModel.post,
                    showsPostHeader: isExpanded,
                    allowsRefresh: false,
                    isAtTop: $isScrollAtTop,
                    viewModel: viewModel,
                    votingViewModel: votingViewModel
                )
                .toolbar(.hidden, for: .navigationBar)
                .scrollDisabled(!isExpanded)
                .opacity(isExpanded ? 1 : 0)
                .allowsHitTesting(isExpanded)

                collapsedHeader
                    .opacity(isExpanded ? 0 : 1)
                    .allowsHitTesting(!isExpanded)
            }
        }
        .contentShape(Rectangle())
        .if(shouldAllowSheetDrag) { view in
            view.simultaneousGesture(sheetDragGesture(expandedTop: expandedTop, collapsedTop: collapsedTop))
        }
    }

    private func sheetHandle(expandedTop: CGFloat, collapsedTop: CGFloat) -> some View {
        ZStack {
            Capsule()
                .fill(.secondary.opacity(0.35))
                .frame(width: Self.handleWidth, height: Self.handleThickness)

            if isExpanded {
                HStack {
                    Spacer()
                    Button {
                        Task { @MainActor in onDismiss() }
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .semibold))
                            .padding(6)
                            .background(.thinMaterial, in: Circle())
                    }
                    .accessibilityLabel("Close")
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, Self.handleVerticalPadding)
        .padding(.bottom, Self.handleVerticalPadding)
        .contentShape(Rectangle())
        .gesture(sheetDragGesture(expandedTop: expandedTop, collapsedTop: collapsedTop))
    }

    private var collapsedHeader: some View {
        Group {
            if let post = viewModel.post {
                CollapsedPostHeaderView(post: post) {
                    sheetState = .expanded
                }
            } else {
                CollapsedPostHeaderLoadingView()
            }
        }
        .background(
            GeometryReader { proxy in
                Color.clear.preference(key: CollapsedHeaderHeightPreferenceKey.self, value: proxy.size.height)
            }
        )
    }

    private var sheetShape: UnevenRoundedRectangle {
        UnevenRoundedRectangle(
            topLeadingRadius: 20,
            bottomLeadingRadius: 0,
            bottomTrailingRadius: 0,
            topTrailingRadius: 20
        )
    }

    private var sheetBackground: some View {
        sheetShape.fill(.background)
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
            .updating($dragTranslation) { value, state, _ in
                state = value.translation.height
            }
            .onEnded { value in
                let baseTop = isExpanded ? expandedTop : collapsedTop
                let predictedTop = baseTop + value.predictedEndTranslation.height
                let midpoint = (expandedTop + collapsedTop) / 2
                if predictedTop <= midpoint {
                    sheetState = .expanded
                } else {
                    sheetState = .collapsed
                }
            }
    }
}

private enum SheetState {
    case collapsed
    case expanded
}

private struct BrowserControlsView: View {
    @ObservedObject var controller: BrowserController
    let fallbackURL: URL
    let onDismiss: @MainActor () -> Void

    var body: some View {
        ZStack {
            HStack {
                Spacer()
                controlsGroup
                Spacer()
            }

            HStack {
                closeButton
                    .padding(.leading, safeInsetPadding)
                Spacer()
            }
        }
    }

    private var safeInsetPadding: CGFloat {
        let inset = PresentationContextProvider.shared.windowScene?.windows.first?.safeAreaInsets.left ?? 0
        return max(inset, 12)
    }

    private var controlsGroup: some View {
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
        .background(.thinMaterial, in: Capsule())
        .overlay(
            Capsule()
                .stroke(.white.opacity(0.2), lineWidth: 1)
        )
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
                .background(.thinMaterial, in: Circle())
        }
        .foregroundStyle(.primary)
        .accessibilityLabel("Close")
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

private enum ControlsHeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

private struct CollapsedPostHeaderView: View {
    let post: Post
    let onExpand: () -> Void

    var body: some View {
        Button(action: onExpand) {
            VStack(alignment: .leading, spacing: 6) {
                Text(post.title)
                    .scaledFont(.headline)
                    .foregroundStyle(.primary)
                    .lineLimit(2)

                Text(metadataText)
                    .scaledFont(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 12)
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
    }

    private var metadataText: String {
        let points = post.score == 1 ? "point" : "points"
        let comments = post.commentsCount == 1 ? "comment" : "comments"
        return "\(post.score) \(points) • \(post.commentsCount) \(comments) • \(post.age)"
    }
}

private struct CollapsedPostHeaderLoadingView: View {
    var body: some View {
        HStack(spacing: 12) {
            Text("Loading...")
                .scaledFont(.headline)
            Spacer()
            ProgressView()
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 12)
    }
}

private enum CollapsedHeaderHeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}
