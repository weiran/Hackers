//
//  HackersApp.swift
//  Hackers
//
//  Copyright © 2025 Weiran Zhang. All rights reserved.
//

import SwiftUI

@main
struct HackersApp: App {
    @StateObject private var navigationStore = NavigationStore()

    // Keep AppDelegate for legacy services and setup
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            MainContentView()
                .environmentObject(navigationStore)
                .onAppear {
                    setupAppearance()
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
}
