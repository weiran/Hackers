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

struct EmbeddedWebView: View {
    let url: URL
    let onDismiss: @MainActor () -> Void
    let showsCloseButton: Bool

    @State private var currentURL: URL?
    @State private var currentTitle: String?
    @State private var canGoBack = false
    @State private var canGoForward = false
    @State private var page = WebPage()

    var body: some View {
        WebView(page)
            .task(id: url) { await load(url) }
            .task { await monitorNavigations() }
            .toolbar {
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
                            goBack()
                        } label: {
                            Image(systemName: "chevron.backward")
                        }
                        .accessibilityLabel("Back")
                        .disabled(!canGoBack)

                        Button {
                            goForward()
                        } label: {
                            Image(systemName: "chevron.forward")
                        }
                        .accessibilityLabel("Forward")
                        .disabled(!canGoForward)

                        Button {
                            reload()
                        } label: {
                            Image(systemName: "arrow.clockwise")
                        }
                        .accessibilityLabel("Reload")
                    }
                }
            }
    }

    private var shareButton: some View {
        Button {
            Task { @MainActor in
                let targetURL = currentURL ?? url
                ContentSharePresenter.shared.shareURL(targetURL, title: currentTitle)
            }
        } label: {
            Image(systemName: "square.and.arrow.up")
        }
        .accessibilityLabel("Share")
    }

    private var openInSafariButton: some View {
        Button {
            Task { @MainActor in
                let targetURL = currentURL ?? url
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
        guard currentURL != target else { return }
        currentURL = target
        _ = page.load(target)
        updateState()
    }

    @MainActor
    private func monitorNavigations() async {
        updateState()
        do {
            for try await _ in page.navigations {
                updateState()
            }
        } catch {
            // Ignore navigation stream errors; state updates happen on successful events.
        }
    }

    @MainActor
    private func updateState() {
        currentURL = page.url ?? currentURL ?? url
        currentTitle = page.title
        let list = page.backForwardList
        canGoBack = !list.backList.isEmpty
        canGoForward = !list.forwardList.isEmpty
    }

    @MainActor
    private func reload() {
        _ = page.reload()
        updateState()
    }

    @MainActor
    private func goBack() {
        guard let item = page.backForwardList.backList.last else { return }
        _ = page.load(item)
        updateState()
    }

    @MainActor
    private func goForward() {
        guard let item = page.backForwardList.forwardList.first else { return }
        _ = page.load(item)
        updateState()
    }
}

struct PostLinkBrowserView: View {
    let post: Post
    @Environment(\.dismiss) private var dismiss
    @State private var showingCommentsPane = false
    @State private var commentsDetent: PresentationDetent = .height(PostCommentsSheet.initialCollapsedHeight)

    var body: some View {
        EmbeddedWebView(
            url: post.url,
            onDismiss: { dismiss() },
            showsCloseButton: true
        )
        .navigationBarBackButtonHidden(true)
        .task { showingCommentsPane = true }
        .sheet(isPresented: $showingCommentsPane) {
            PostCommentsSheet(post: post, detent: $commentsDetent)
        }
    }
}

private struct PostCommentsSheet: View {
    static let initialCollapsedHeight: CGFloat = 150

    @Binding var detent: PresentationDetent

    @State private var viewModel: CommentsViewModel
    @State private var votingViewModel: VotingViewModel
    @State private var collapsedHeight: CGFloat = initialCollapsedHeight

    init(post: Post, detent: Binding<PresentationDetent>) {
        _detent = detent
        _viewModel = State(initialValue: CommentsViewModel(post: post))
        let container = DependencyContainer.shared
        _votingViewModel = State(initialValue: VotingViewModel(
            votingStateProvider: container.getVotingStateProvider(),
            commentVotingStateProvider: container.getCommentVotingStateProvider(),
            authenticationUseCase: container.getAuthenticationUseCase()
        ))
    }

    var body: some View {
        ZStack(alignment: .top) {
            CommentsView<NavigationStore>(
                postID: viewModel.postID,
                initialPost: viewModel.post,
                showsPostHeader: detent == .large,
                allowsRefresh: false,
                viewModel: viewModel,
                votingViewModel: votingViewModel
            )
            .toolbar(.hidden, for: .navigationBar)
            .scrollDisabled(detent != .large)
            .opacity(detent == .large ? 1 : 0)
            .allowsHitTesting(detent == .large)

            collapsedHeader
                .opacity(detent == .large ? 0 : 1)
                .allowsHitTesting(detent != .large)
        }
        .onPreferenceChange(CollapsedHeaderHeightPreferenceKey.self) { newValue in
            let updated = ceil(newValue)
            guard updated.isFinite, updated > 60 else { return }
            guard abs(updated - collapsedHeight) > 0.5 else { return }
            collapsedHeight = updated
            if isCollapsed {
                detent = collapsedDetent
            }
        }
        .presentationDetents([collapsedDetent, .large], selection: $detent)
        .presentationDragIndicator(.visible)
        .presentationBackgroundInteraction(.enabled(upThrough: collapsedDetent))
        .presentationCornerRadius(16)
        // Prefer expanding the sheet (collapsed -> large) before scrolling the comments list.
        .presentationContentInteraction(.resizes)
        .interactiveDismissDisabled(true)
    }

    private var isCollapsed: Bool {
        !isExpanded
    }

    private var isExpanded: Bool {
        detent == .large
    }

    private var collapsedDetent: PresentationDetent {
        .height(collapsedHeight)
    }

    private var collapsedHeader: some View {
        Group {
            if let post = viewModel.post {
                CollapsedPostHeaderView(post: post) {
                    detent = .large
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
            .padding(.top, 20)
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
        .padding(.top, 20)
        .padding(.bottom, 12)
    }
}

private enum CollapsedHeaderHeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}
