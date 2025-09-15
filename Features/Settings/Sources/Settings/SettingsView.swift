//
//  SettingsView.swift
//  Settings
//
//  Copyright © 2025 Weiran Zhang. All rights reserved.
//

import DesignSystem
import Domain
import MessageUI
import Onboarding
import Shared
import SwiftUI
import Drops

public struct SettingsView<NavigationStore: NavigationStoreProtocol>: View {
    @State private var viewModel: SettingsViewModel
    @EnvironmentObject private var navigationStore: NavigationStore
    @Environment(\.dismiss) private var dismiss
    @State private var showOnboarding = false
    @State private var mailResult: Result<MFMailComposeResult, Error>?
    @State private var showMailView = false
    @State private var showLogin = false
    @State private var showClearCacheAlert = false

    let isAuthenticated: Bool
    let currentUsername: String?
    let onLogin: (String, String) async throws -> Void
    let onLogout: () -> Void
    let onShowOnboarding: () -> Void

    public init(
        viewModel: SettingsViewModel = SettingsViewModel(),
        isAuthenticated: Bool = false,
        currentUsername: String? = nil,
        onLogin: @escaping (String, String) async throws -> Void = { _, _ in },
        onLogout: @escaping () -> Void = {},
        onShowOnboarding: @escaping () -> Void = {},
    ) {
        _viewModel = State(initialValue: viewModel)
        self.isAuthenticated = isAuthenticated
        self.currentUsername = currentUsername
        self.onLogin = onLogin
        self.onLogout = onLogout
        self.onShowOnboarding = onShowOnboarding
    }

    public var body: some View {
        NavigationStack {
            Form {
                Section(footer: versionLabel) {
                    HStack {
                        Image(uiImage: Bundle.main.icon ?? UIImage())
                            .resizable()
                            .scaledToFill()
                            .frame(width: 80, height: 80)
                        VStack(alignment: .leading) {
                            Text("Hackers")
                                .scaledFont(.title)
                            Text("By Weiran Zhang")
                                .scaledFont(.body)
                        }
                    }
                    Button(action: {
                        if let url = URL(string: "https://github.com/weiran/hackers") {
                            UIApplication.shared.open(url)
                        }
                    }, label: {
                        Text("Hackers on GitHub")
                    })
                    Button(action: {
                        showMailView.toggle()
                    }, label: {
                        Text("Send Feedback")
                    })
                    .disabled(!MFMailComposeViewController.canSendMail())
                    .sheet(isPresented: $showMailView) {
                        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
                        MailView(
                            result: $mailResult,
                            recipients: ["me@weiran.co"],
                            subject: "Hackers App Feedback",
                            messageBody: "\n\n\n---\nApp Version: \(version)",
                        )
                    }
                    Button(action: { showOnboarding = true }, label: {
                        Text("Show What's New")
                    })
                    .sheet(isPresented: $showOnboarding) {
                        Onboarding.OnboardingService.createOnboardingView {
                            Onboarding.OnboardingService.markOnboardingShown()
                            showOnboarding = false
                        }
                    }
                }

                Section(header: Text("Account")) {
                    Button(
                        action: {
                            showLogin = true
                        },
                        label: {
                            HStack {
                                Text(isAuthenticated ? "Logged in as \(currentUsername ?? "")" : "Login")
                                Spacer()
                                if isAuthenticated {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                        .accessibilityHidden(true)
                                }
                            }
                        },
                    )
                    .sheet(isPresented: $showLogin) {
                        LoginView(
                            isAuthenticated: isAuthenticated,
                            currentUsername: currentUsername,
                            onLogin: onLogin,
                            onLogout: onLogout,
                        )
                    }
                }

                Section(header: Text("Appearance")) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Text Size")
                            Spacer()
                            Text(viewModel.textSize.displayName)
                                .foregroundColor(.secondary)
                        }

                        HStack {
                            Text("A")
                                .scaledFont(.caption2)
                                .foregroundColor(.secondary)

                            Slider(
                                value: Binding(
                                    get: { Double(viewModel.textSize.rawValue) },
                                    set: { viewModel.textSize = TextSize(rawValue: Int($0)) ?? .medium },
                                ),
                                in: 0 ... 4,
                                step: 1,
                            )
                            .accessibilityLabel("Text Size")

                            Text("A")
                                .scaledFont(.title2)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section(header: Text("Browser")) {
                    // Place Safari default browser setting first
                    Toggle(isOn: $viewModel.openInDefaultBrowser) {
                        Text("Open Links in Safari")
                    }

                    Toggle(isOn: $viewModel.safariReaderMode) {
                        Text("Open Safari in Reader Mode")
                    }
                }

                Section(header: Text("Storage")) {
                    HStack {
                        Text("Storage Used")
                        Spacer()
                        Text(viewModel.cacheUsageText)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                    Button(role: .destructive) {
                        showClearCacheAlert = true
                    } label: {
                        Text("Clear Cache")
                    }
                    .alert("Clear Cache?", isPresented: $showClearCacheAlert) {
                        Button("Clear", role: .destructive) {
                            viewModel.clearCache()
                            Drops.show(Drop(title: "Cache cleared"))
                        }
                        Button("Cancel", role: .cancel) {}
                    } message: {
                        Text("This removes cached images and network responses to reduce storage.")
                    }
                }
            }
            .listStyle(GroupedListStyle())
            .navigationBarTitle(Text("Settings"))
            .navigationBarItems(trailing:
                Button(
                    action: {
                        dismiss()
                    },
                    label: {
                        Image(systemName: "xmark")
                    },
                )
                .accessibilityLabel("Close"))
        }
    }

    private var versionLabel: some View {
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        return HStack {
            Spacer()
            Text("Version \(appVersion ?? "1.0")")
                .foregroundColor(.gray)
            Spacer()
        }
    }
}

public extension Bundle {
    var icon: UIImage? {
        if let icons = infoDictionary?["CFBundleIcons"] as? [String: Any],
           let primaryIcon = icons["CFBundlePrimaryIcon"] as? [String: Any],
           let iconFiles = primaryIcon["CFBundleIconFiles"] as? [String],
           let lastIcon = iconFiles.last
        {
            return UIImage(named: lastIcon)
        }
        return nil
    }
}
