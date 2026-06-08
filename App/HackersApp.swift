//
//  HackersApp.swift
//  Hackers
//
//  Copyright © 2025 Weiran Zhang. All rights reserved.
//

import Shared
import SwiftUI

@main
struct HackersApp: App {
    @State private var navigationStore: NavigationStore
    @State private var sessionService: SessionService
    @State private var toastPresenter: ToastPresenter
    @State private var handledInitialUITestingRoute = false

    // Keep AppDelegate for legacy services and setup
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    init() {
        #if DEBUG
        UITestingBootstrap.configureIfNeeded()
        #endif
        _navigationStore = State(initialValue: NavigationStore())
        _sessionService = State(initialValue: DependencyContainer.shared.makeSessionService())
        _toastPresenter = State(initialValue: DependencyContainer.shared.makeToastPresenter())
    }

    var body: some Scene {
        WindowGroup {
            MainContentView()
                .environment(navigationStore)
                .environment(sessionService)
                .environment(toastPresenter)
                .onAppear {
                    setupAppearance()
                    handleInitialUITestingRouteIfNeeded()
                }
                .onOpenURL { url in
                    handleOpenURL(url)
                }
        }
    }

    private func setupAppearance() {
        // Apply app-wide appearance settings
        if let appTintColor = UIColor(named: "appTintColor") {
            UIView.appearance().tintColor = appTintColor
        }
    }

    private func handleOpenURL(_ url: URL) {
        navigationStore.handleOpenURL(url)
    }

    private func handleInitialUITestingRouteIfNeeded() {
        guard !handledInitialUITestingRoute else { return }
        guard ProcessInfo.processInfo.environment["HACKERS_SCREENSHOTS"] == "1" else { return }

        if let linkPostID = ProcessInfo.processInfo.environment["HACKERS_UI_INITIAL_LINK_POST_ID"].flatMap(Int.init) {
            handledInitialUITestingRoute = true
            Task {
                guard let post = try? await DependencyContainer.shared.getPostUseCase().getPost(id: linkPostID) else {
                    return
                }
                await MainActor.run {
                    navigationStore.showPostLink(post, presentation: .collapsedBrowser)
                }
            }
            return
        }

        if let postID = ProcessInfo.processInfo.environment["HACKERS_UI_INITIAL_POST_ID"].flatMap(Int.init) {
            handledInitialUITestingRoute = true
            navigationStore.showPost(withId: postID)
        }
    }
}
