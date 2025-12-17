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
import UIKit
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
    @Environment(NavigationStore.self) private var navigationStore

    @State private var viewModel: CommentsViewModel
    @State private var votingViewModel: VotingViewModel
    @State private var hasRefreshedBookmarks = false
    @State private var collapsedHeight: CGFloat = initialCollapsedHeight
    @State private var containerHeight: CGFloat = 0
    @State private var expandedHeight: CGFloat = 0

    private let bookmarksController: BookmarksController

    init(post: Post, detent: Binding<PresentationDetent>) {
        _detent = detent
        _viewModel = State(initialValue: CommentsViewModel(post: post))
        let container = DependencyContainer.shared
        _votingViewModel = State(initialValue: VotingViewModel(
            votingStateProvider: container.getVotingStateProvider(),
            commentVotingStateProvider: container.getCommentVotingStateProvider(),
            authenticationUseCase: container.getAuthenticationUseCase()
        ))
        bookmarksController = container.makeBookmarksController()
    }

    var body: some View {
        ZStack(alignment: .top) {
            CommentsView<NavigationStore>(
                postID: viewModel.postID,
                initialPost: viewModel.post,
                showsPostHeader: false,
                viewModel: viewModel,
                votingViewModel: votingViewModel
            )
            .toolbar(.hidden, for: .navigationBar)
            .padding(.top, collapsedHeight)
            .opacity(commentsOpacity)
            .allowsHitTesting(commentsOpacity > 0.95)

            postHeader
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(
            GeometryReader { proxy in
                Color.clear.preference(key: SheetContainerHeightPreferenceKey.self, value: proxy.size.height)
            }
        )
        .onPreferenceChange(SheetContainerHeightPreferenceKey.self) { newValue in
            let updated = max(1, ceil(newValue))
            containerHeight = updated
            if isExpanded, abs(updated - expandedHeight) > 0.5 {
                expandedHeight = updated
            }
        }
        .onPreferenceChange(CollapsedHeaderHeightPreferenceKey.self) { newValue in
            let updated = max(1, ceil(newValue))
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
        .presentationContentInteraction(.scrolls)
        .interactiveDismissDisabled(true)
        .task {
            votingViewModel.navigationStore = navigationStore
            await refreshBookmarksIfNeeded()
        }
    }

    private var postHeader: some View {
        Group {
            if let post = viewModel.post {
                PostDisplayView(
                    post: post,
                    votingState: votingViewModel.votingState(for: post),
                    showPostText: false,
                    showThumbnails: DependencyContainer.shared.getSettingsUseCase().showThumbnails,
                    compactMode: false,
                    onThumbnailTap: { detent = .large },
                    onUpvoteTap: { await upvote(postID: post.id) },
                    onUnvoteTap: { await unvote(postID: post.id) },
                    onBookmarkTap: { await toggleBookmark(postID: post.id) },
                    onCommentsTap: { detent = .large }
                )
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .background(
                    GeometryReader { proxy in
                        Color.clear.preference(key: CollapsedHeaderHeightPreferenceKey.self, value: proxy.size.height)
                    }
                )
            } else {
                HStack {
                    Text("Comments")
                        .font(.headline)
                    Spacer()
                    ProgressView()
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
            }
        }
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

    private var expansionProgress: CGFloat {
        if isExpanded {
            return 1
        }
        let estimatedExpandedHeight = expandedHeight > 1 ? expandedHeight : UIScreen.main.bounds.height
        let range = max(1, estimatedExpandedHeight - collapsedHeight)
        let value = (containerHeight - collapsedHeight) / range
        return min(max(value, 0), 1)
    }

    private var commentsOpacity: CGFloat {
        // Fade comments in quickly once the pane starts expanding.
        let t = min(max((expansionProgress - 0.05) / 0.25, 0), 1)
        return t
    }

    @MainActor
    private func refreshBookmarksIfNeeded() async {
        guard hasRefreshedBookmarks == false else { return }
        hasRefreshedBookmarks = true
        let bookmarkedIDs = await bookmarksController.refreshBookmarks()
        guard var post = viewModel.post else { return }
        let isBookmarked = bookmarkedIDs.contains(post.id)
        if post.isBookmarked != isBookmarked {
            post.isBookmarked = isBookmarked
            viewModel.post = post
        }
    }

    @MainActor
    private func upvote(postID: Int) async -> Bool {
        guard var post = viewModel.post, post.id == postID else { return false }
        await votingViewModel.upvote(post: &post)
        viewModel.post = post
        return post.upvoted
    }

    @MainActor
    private func unvote(postID: Int) async -> Bool {
        guard var post = viewModel.post, post.id == postID else { return false }
        await votingViewModel.unvote(post: &post)
        viewModel.post = post
        return !post.upvoted
    }

    @MainActor
    private func toggleBookmark(postID: Int) async -> Bool {
        guard var post = viewModel.post, post.id == postID else { return false }
        let newState = await bookmarksController.toggle(post: post)
        post.isBookmarked = newState
        viewModel.post = post
        return newState
    }
}

private enum CollapsedHeaderHeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

private enum SheetContainerHeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}
