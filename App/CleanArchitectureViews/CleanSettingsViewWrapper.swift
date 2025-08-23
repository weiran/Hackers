//
//  CleanSettingsViewWrapper.swift
//  Hackers
//
//  Wrapper to integrate the clean architecture Settings module
//

import SwiftUI
import Settings

struct CleanSettingsViewWrapper: View {
    @EnvironmentObject private var navigationStore: NavigationStore

    var body: some View {
        // Using the new clean architecture CleanSettingsView from the Settings module
        CleanSettingsView<NavigationStore>(
            isAuthenticated: SessionService.shared.authenticationState == .authenticated,
            currentUsername: SessionService.shared.username,
            onLogin: { username, password in
                _ = try await SessionService.shared.authenticate(username: username, password: password)
            },
            onLogout: {
                SessionService.shared.unauthenticate()
            }
        )
        .environmentObject(navigationStore)
    }
}
