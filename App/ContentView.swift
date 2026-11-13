//
//  ContentView.swift
//  Hackers
//
//  Copyright © 2025 Weiran Zhang. All rights reserved.
//

import Authentication
import Comments
import DesignSystem
import Domain
import Feed
import Settings
import Shared
import SwiftUI
import UIKit
import Foundation

@MainActor
struct MainContentView: View {
    @Environment(NavigationStore.self) private var navigationStore
    @Environment(SessionService.self) private var sessionService
    @Environment(ToastPresenter.self) private var toastPresenter
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    private let whatsNewCoordinator: WhatsNewCoordinator
    @State private var settingsViewModel = SettingsViewModel()
    @State private var feedViewModel = FeedViewModel()
    @State private var commentsViewModels = CommentsViewModelCache()
    @State private var browserControllers = BrowserControllerCache()
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    @State private var showWhatsNew = false
    @State private var showWhatsNewPanel = false
    private var preferredCompactColumnBinding: Binding<NavigationSplitViewColumn> {
        Binding(
            get: { navigationStore.preferredCompactColumn },
            set: { navigationStore.preferredCompactColumn = $0 }
        )
    }
    private var detailPathBinding: Binding<[NavigationDetailDestination]> {
        Binding(
            get: { navigationStore.detailPath },
            set: { navigationStore.detailPath = $0 }
        )
    }
    private var showingLoginBinding: Binding<Bool> {
        Binding(
            get: { navigationStore.showingLogin },
            set: { navigationStore.showingLogin = $0 }
        )
    }
    private var showingSettingsBinding: Binding<Bool> {
        Binding(
            get: { navigationStore.showingSettings },
            set: { navigationStore.showingSettings = $0 }
        )
    }
    private var isPresentingModal: Bool {
        navigationStore.showingLogin || navigationStore.showingSettings || showWhatsNew
    }
    private var effectiveHorizontalSizeClass: UserInterfaceSizeClass? {
        #if DEBUG
        if let override = UITestSizeClassOverride.shared.horizontalSizeClass {
            return override
        }
        #endif
        return horizontalSizeClass
    }
    private var isRegularWidth: Bool {
        effectiveHorizontalSizeClass == .regular
    }
    private var whatsNewPanel: WhatsNewPanel? {
        guard showWhatsNewPanel else { return nil }
        return whatsNewCoordinator.makeWhatsNewPanel(
            onOpen: { showWhatsNew = true },
            onDismiss: {
                whatsNewCoordinator.markWhatsNewShown()
                withAnimation(.default) {
                    showWhatsNewPanel = false
                }
            }
        )
    }

    init(container: DependencyContainer = .shared) {
        whatsNewCoordinator = WhatsNewCoordinator(
            whatsNewUseCase: container.getWhatsNewUseCase()
        )
    }

    var body: some View {
        // One adaptive split view for every size: it shows feed and detail side by side
        // in regular width (iPad, iPhone Duo inner display) and collapses to a single
        // stack in compact width, keeping each column's state across folds and resizes.
        NavigationSplitView(
            columnVisibility: $columnVisibility,
            preferredCompactColumn: preferredCompactColumnBinding
        ) {
            FeedView<NavigationStore>(
                viewModel: feedViewModel,
                isSidebar: isRegularWidth,
                whatsNewPanel: whatsNewPanel
            )
            .overlay(alignment: .trailing) {
                if isRegularWidth {
                    Rectangle()
                        .fill(Color(uiColor: .separator))
                        .frame(width: 1)
                        .ignoresSafeArea(edges: .vertical)
                        .allowsHitTesting(false)
                        .accessibilityHidden(true)
                }
            }
        } detail: {
            NavigationStack(path: detailPathBinding) {
                Group {
                    if let root = navigationStore.detailRoot {
                        detailView(for: root)
                    } else {
                        EmptyDetailView()
                    }
                }
                .navigationDestination(for: NavigationDetailDestination.self) { destination in
                    detailView(for: destination)
                }
            }
            // iOS uses different navigation-bar hosts for the Duo's compact outer display
            // and regular inner display. Recreate only that host at the trait boundary so
            // toolbar representations don't leave blank platform slots. Detail models and
            // scroll anchors live above it and survive the replacement.
            .id(effectiveHorizontalSizeClass)
        }
        .navigationSplitViewStyle(.balanced)
        .environment(\.horizontalSizeClass, effectiveHorizontalSizeClass)
        .textScaling(for: settingsViewModel.textSize)
        .buttonStyle(AppDefaultButtonStyle())
        .accentColor(.accentColor)
        .onChange(of: isRegularWidth, initial: true) { _, isRegular in
            DeviceLayout.hasRegularWidthWindow = isRegular
        }
        .onChange(of: navigationStore.detailRoot) { _, root in
            guard root == nil else { return }
            commentsViewModels.removeAll()
            browserControllers.removeAll()
        }
        .toastOverlay(toastPresenter, isActive: !isPresentingModal)
        .sheet(isPresented: showingLoginBinding) {
            LoginView(
                isAuthenticated: sessionService.authenticationState == .authenticated,
                currentUsername: sessionService.username,
                onLogin: { username, password in
                    _ = try await sessionService.authenticate(username: username, password: password)
                },
                onLogout: {
                    try await sessionService.unauthenticate()
                },
                textSize: settingsViewModel.textSize
            )
            .textScaling(for: settingsViewModel.textSize)
                .toastOverlay(toastPresenter)
        }
        .sheet(isPresented: showingSettingsBinding) {
            SettingsView(
                viewModel: settingsViewModel,
                isAuthenticated: sessionService.authenticationState == .authenticated,
                currentUsername: sessionService.username,
                onLogin: { username, password in
                    _ = try await sessionService.authenticate(username: username, password: password)
                },
                onLogout: {
                    try await sessionService.unauthenticate()
                },
                onWhatsNewDismiss: {
                    whatsNewCoordinator.markWhatsNewShown()
                }
            )
            .textScaling(for: settingsViewModel.textSize)
            .toastOverlay(toastPresenter)
        }
        .sheet(
            isPresented: $showWhatsNew,
            onDismiss: {
                // Also covers swipe-to-dismiss, so the panel doesn't return for this version.
                whatsNewCoordinator.markWhatsNewShown()
                withAnimation(.default) {
                    showWhatsNewPanel = false
                }
            }
        ) {
            whatsNewCoordinator
                .makeWhatsNewView {
                    showWhatsNew = false
                }
                .textScaling(for: settingsViewModel.textSize)
                .toastOverlay(toastPresenter)
        }
        .task {
            if whatsNewCoordinator.shouldShowWhatsNew() {
                showWhatsNewPanel = true
            }
        }
    }

    @ViewBuilder
    private func detailView(for destination: NavigationDetailDestination) -> some View {
        switch destination {
        case let .comments(postID):
            CommentsView<NavigationStore>(
                postID: postID,
                initialPost: navigationStore.selectedPost?.id == postID ? navigationStore.selectedPost : nil,
                viewModel: commentsViewModels.viewModel(
                    postID: postID,
                    initialPost: navigationStore.selectedPost?.id == postID ? navigationStore.selectedPost : nil
                )
            )
            .id(postID)
        case let .postBrowser(post, presentation):
            if isRegularWidth {
                Group {
                    if presentation == .expandedComments {
                        CommentsView<NavigationStore>(
                            postID: post.id,
                            initialPost: post,
                            viewModel: commentsViewModels.viewModel(postID: post.id, initialPost: post)
                        )
                        .id(post.id)
                    } else {
                        let controller = browserControllers.controller(key: "post:\(post.id)")
                        EmbeddedWebView(
                            url: post.url,
                            onDismiss: { navigationStore.dismissDetail() },
                            showsCloseButton: false,
                            controller: controller
                        )
                        .modifier(AdaptiveBrowserControls())
                        .onAppear {
                            controller.setMediaPlaybackSuspended(false)
                        }
                        .accessibilityElement(children: .contain)
                        .accessibilityIdentifier(AccessibilityIdentifier.Browser.view)
                        .id("browser-\(post.id)")
                    }
                }
                .toolbar {
                    storyToggle(post: post, presentation: presentation)
                }
            } else {
                PostLinkBrowserView(
                    post: post,
                    presentation: presentation,
                    controller: browserControllers.controller(
                        key: "post:\(post.id)",
                        mediaPlaybackSuspended: presentation == .expandedComments
                    ),
                    commentsViewModel: commentsViewModels.viewModel(postID: post.id, initialPost: post),
                    onClose: { navigationStore.dismissDetail() }
                )
                .id("browser-\(post.id)")
            }
        case let .web(url):
            EmbeddedWebView(
                url: url,
                onDismiss: { navigationStore.dismissDetail() },
                showsCloseButton: false,
                controller: browserControllers.controller(key: "url:\(url.absoluteString)")
            )
            .modifier(AdaptiveBrowserControls())
            .id(url.absoluteString)
        }
    }

    @ToolbarContentBuilder
    private func storyToggle(post: Post, presentation: PostLinkPresentation) -> some ToolbarContent {
        if #available(iOS 27.1, *) {
            ToolbarItem(id: "story.toggle", placement: .topBarPinnedTrailing) {
                storyToggleButton(post: post, presentation: presentation)
            }
            .axisBehavior(UIDevice.current.userInterfaceIdiom == .pad ? .horizontalOnly : .verticalPreferred)
            ToolbarSpacer(.fixed, placement: .topBarPinnedTrailing)
                .axisBehavior(UIDevice.current.userInterfaceIdiom == .pad ? .horizontalOnly : .verticalPreferred)
        } else {
            ToolbarItem(placement: .topBarTrailing) {
                storyToggleButton(post: post, presentation: presentation)
            }
            ToolbarSpacer(.fixed, placement: .topBarTrailing)
        }
    }

    private func storyToggleButton(post: Post, presentation: PostLinkPresentation) -> some View {
        let showingComments = presentation == .expandedComments
        return Button(
            showingComments ? "Show Article" : "Show Comments",
            systemImage: showingComments ? "safari" : "message"
        ) {
            browserControllers.controller(key: "post:\(post.id)")
                .setMediaPlaybackSuspended(!showingComments)
            navigationStore.showPostLink(
                post,
                presentation: showingComments ? .collapsedBrowser : .expandedComments
            )
        }
    }
}

@MainActor
private final class BrowserControllerCache {
    private static let capacity = 8
    private var controllers: [String: BrowserController] = [:]
    private var recentKeys: [String] = []

    func controller(key: String, mediaPlaybackSuspended: Bool = false) -> BrowserController {
        if let controller = controllers[key] {
            markRecent(key)
            return controller
        }
        let controller = BrowserController(mediaPlaybackSuspended: mediaPlaybackSuspended)
        controllers[key] = controller
        markRecent(key)
        if recentKeys.count > Self.capacity {
            controllers[recentKeys.removeFirst()] = nil
        }
        return controller
    }

    private func markRecent(_ key: String) {
        recentKeys.removeAll(where: { $0 == key })
        recentKeys.append(key)
    }

    func removeAll() {
        controllers.removeAll()
        recentKeys.removeAll()
    }
}

/// Keeps loaded comments and collapse state stable while SwiftUI reevaluates the detail
/// column through an iPhone Duo fold. Without this cache, `CommentsView.init` constructed
/// throwaway models for every intermediate width even though `@State` retained only one.
@MainActor
private final class CommentsViewModelCache {
    private static let capacity = 8
    private var models: [Int: CommentsViewModel] = [:]
    private var recentPostIDs: [Int] = []

    func viewModel(postID: Int, initialPost: Post?) -> CommentsViewModel {
        if let model = models[postID] {
            markRecent(postID)
            return model
        }
        let model = CommentsViewModel(postID: postID, initialPost: initialPost)
        models[postID] = model
        markRecent(postID)
        if recentPostIDs.count > Self.capacity {
            models[recentPostIDs.removeFirst()] = nil
        }
        return model
    }

    private func markRecent(_ postID: Int) {
        recentPostIDs.removeAll(where: { $0 == postID })
        recentPostIDs.append(postID)
    }

    func removeAll() {
        models.removeAll()
        recentPostIDs.removeAll()
    }
}

struct EmptyDetailView: View {
    var body: some View {
        ContentUnavailableView {
            Label("Select a Post", systemImage: "doc.text")
        } description: {
            Text("Choose a post from the sidebar to view its comments and details")
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}
