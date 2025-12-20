//
//  SettingsView.swift
//  Settings
//
//  Copyright © 2025 Weiran Zhang. All rights reserved.
//

import Authentication
import DesignSystem
import Domain
import MessageUI
import Shared
import SwiftUI

public struct SettingsView: View {
    @State private var viewModel: SettingsViewModel
    @Environment(ToastPresenter.self) private var toastPresenter
    @Environment(\.dismiss) private var dismiss
    @State private var mailResult: Result<MFMailComposeResult, Error>?
    @State private var showMailView = false
    @State private var showLogin = false
    @State private var showClearCacheAlert = false
#if DEBUG
    @AppStorage("devThumbnailProvider") private var devThumbnailProvider = "weiranzhang"
#endif

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
        onShowOnboarding: @escaping () -> Void = {}
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
                    NavigationLink {
                        SupportView()
                    } label: {
                        Label("Support the App", systemImage: "heart.circle.fill")
                    }
                    Button(action: {
                        if let url = URL(string: "https://github.com/weiran/hackers") {
                            UIApplication.shared.open(url)
                        }
                    }, label: {
                        Label("Hackers on GitHub", systemImage: "link")
                    })
                    Button(action: {
                        showMailView.toggle()
                    }, label: {
                        Label("Send Feedback", systemImage: "paperplane")
                    })
                    .disabled(!MFMailComposeViewController.canSendMail())
                    .sheet(isPresented: $showMailView) {
                        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
                        let deviceIdentifier = UIDevice.current.modelIdentifier
                        let systemVersion = UIDevice.current.systemVersion
                        let bodyLines = [
                            "",
                            "",
                            "",
                            "---",
                            "App Version: \(version)",
                            "Device Model: \(deviceIdentifier)",
                            "iOS Version: \(systemVersion)"
                        ]

                        MailView(
                            result: $mailResult,
                            recipients: ["weiran@zhang.me.uk"],
                            subject: "Hackers App Feedback",
                            messageBody: bodyLines.joined(separator: "\n"),
                        )
                    }
                    Button(action: { onShowOnboarding() }, label: {
                        Label("Show What's New", systemImage: "sparkles")
                    })
                }

                Section(header: Text("Account")) {
                    Button(
                        action: {
                            showLogin = true
                        },
                        label: {
                            HStack(spacing: 12) {
                                Label(isAuthenticated ? "Logged in as \(currentUsername ?? "")" : "Login",
                                      systemImage: "person.crop.circle"
                                )
                                Spacer()
                                if isAuthenticated {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(AppColors.success)
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
                            textSize: viewModel.textSize
                        )
                        .textScaling(for: viewModel.textSize)
                    }
                }

                Section(header: Text("Appearance")) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Label("Text Size", systemImage: "textformat.size")
                            Spacer()
                            Text(viewModel.textSize.displayName)
                                .foregroundStyle(.secondary)
                        }

                        HStack {
                            Text("A")
                                .scaledFont(.caption2)
                                .foregroundStyle(.secondary)

                            Slider(
                                value: Binding(
                                    get: { Double(viewModel.textSize.rawValue) },
                                    set: { newValue in
                                        Task { @MainActor in
                                            viewModel.textSize = TextSize(rawValue: Int(newValue)) ?? .medium
                                        }
                                    }
                                ),
                                in: 0 ... 4,
                                step: 1,
                            )
                            .accessibilityLabel("Text Size")

                            Text("A")
                                .scaledFont(.title2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)

                    Toggle(isOn: $viewModel.showThumbnails) {
                        Label("Show Thumbnails", systemImage: "photo.on.rectangle")
                    }

                    Toggle(isOn: $viewModel.compactFeedDesign) {
                        Label("Compact Feed Design", systemImage: "list.bullet.rectangle")
                    }
                }

#if DEBUG
                Section(header: Text("Developer")) {
                    Picker(selection: $devThumbnailProvider) {
                        Text("Weiranzhang.com").tag("weiranzhang")
                        Text("Google").tag("google")
                        Text("DuckDuckGo").tag("duckduckgo")
                    } label: {
                        Label("Thumbnail Provider", systemImage: "photo.on.rectangle.angled")
                    }
                    .pickerStyle(.menu)
                    .disabled(!viewModel.showThumbnails)
                }
#endif

                Section(header: Text("Browser")) {
                    Picker(selection: $viewModel.linkBrowserMode) {
                        Text("In-App Browser").tag(LinkBrowserMode.inAppBrowser)
                        Text("Custom Browser").tag(LinkBrowserMode.customBrowser)
                        Text("System Browser").tag(LinkBrowserMode.systemBrowser)
                    } label: {
                        Label("Open Links Using", systemImage: "safari")
                    }
                    .pickerStyle(.menu)

                    Toggle(isOn: $viewModel.safariReaderMode) {
                        Label("Open Safari in Reader Mode", systemImage: "doc.text.magnifyingglass")
                    }
                }

                Section(header: Text("Feed")) {
                    Toggle(isOn: $viewModel.rememberFeedCategory) {
                        Label("Remember Feed Category", systemImage: "list.bullet")
                    }
                }

                Section(header: Text("Storage")) {
                    HStack(spacing: 12) {
                        Label("Storage Used", systemImage: "externaldrive")
                        Spacer()
                        Text(viewModel.cacheUsageText)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                    Button(role: .destructive) {
                        showClearCacheAlert = true
                    } label: {
                        Label("Clear Cache", systemImage: "trash")
                    }
                    .alert("Clear Cache?", isPresented: $showClearCacheAlert) {
                        Button("Clear", role: .destructive) {
                            viewModel.clearCache()
                            toastPresenter.show(text: "Cache cleared", kind: .success)
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
        .textScaling(for: viewModel.textSize)
    }

    private var versionLabel: some View {
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        return HStack {
            Spacer()
            Text("Version \(appVersion ?? "1.0")")
                .foregroundStyle(.gray)
            Spacer()
        }
    }

}

private extension UIDevice {
    var modelIdentifier: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        // Mirror lets us turn the C char tuple into a Swift String.
        let identifier = Mirror(reflecting: systemInfo.machine).children.reduce(into: "") { result, element in
            guard let value = element.value as? Int8, value != 0 else { return }
            result.append(Character(UnicodeScalar(UInt8(value))))
        }
        return identifier.isEmpty ? "Unknown" : identifier
    }
}

public extension Bundle {
    var icon: UIImage? {
        if let icons = infoDictionary?["CFBundleIcons"] as? [String: Any],
           let primaryIcon = icons["CFBundlePrimaryIcon"] as? [String: Any],
           let iconFiles = primaryIcon["CFBundleIconFiles"] as? [String],
           let lastIcon = iconFiles.last {
            return UIImage(named: lastIcon)
        }
        return nil
    }
}
