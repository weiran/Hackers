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
    @State private var handlingInitialUITestingRoute = false

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
        guard !handledInitialUITestingRoute, !handlingInitialUITestingRoute else { return }
        #if DEBUG
        guard let route = UITestingBootstrap.configuration?.route else { return }

        switch route {
        case .feed:
            handledInitialUITestingRoute = true
        case let .story(postID, presentation):
            handlingInitialUITestingRoute = true
            Task {
                do {
                    let post = try await DependencyContainer.shared.getPostUseCase().getPost(id: postID)
                    await MainActor.run {
                        navigationStore.showPostLinkForUITesting(post, presentation: presentation)
                        handledInitialUITestingRoute = true
                        handlingInitialUITestingRoute = false
                    }
                } catch {
                    preconditionFailure("Validated UI-test story route failed to load post \(postID): \(error)")
                }
            }
        case let .comments(postID):
            navigationStore.showPost(withId: postID)
            handledInitialUITestingRoute = true
        }
        #endif
    }
}
