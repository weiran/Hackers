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
import WhatsNew

public struct SettingsView: View {
    @Environment(ToastPresenter.self) private var toastPresenter
    @Environment(\.dismiss) private var dismiss
    let isAuthenticated: Bool
    let currentUsername: String?
    let onLogin: (String, String) async throws -> Void
    let onLogout: () -> Void
    let onWhatsNewDismiss: () -> Void
    @State private var viewModel: SettingsViewModel
    @State private var mailResult: Result<MFMailComposeResult, Error>?
    @State private var showMailView = false
    @State private var showLogin = false
    @State private var showWhatsNew = false
    @State private var showClearCacheAlert = false
#if DEBUG
    @AppStorage("devThumbnailProvider") private var devThumbnailProvider = "weiranzhang"
#endif

    public init(
        viewModel: SettingsViewModel = SettingsViewModel(),
        isAuthenticated: Bool = false,
        currentUsername: String? = nil,
        onLogin: @escaping (String, String) async throws -> Void = { _, _ in },
        onLogout: @escaping () -> Void = {},
        onWhatsNewDismiss: @escaping () -> Void = {}
    ) {
        _viewModel = State(initialValue: viewModel)
        self.isAuthenticated = isAuthenticated
        self.currentUsername = currentUsername
        self.onLogin = onLogin
        self.onLogout = onLogout
        self.onWhatsNewDismiss = onWhatsNewDismiss
    }

    public var body: some View {
        NavigationStack {
            Form {
                Section(footer: versionLabel) {
                    SettingsTopActionsSection(
                        canSendFeedback: MFMailComposeViewController.canSendMail(),
                        openGitHub: openGitHub,
                        sendFeedback: { showMailView = true },
                        showWhatsNew: { showWhatsNew = true }
                    )
                    .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
                    .listRowSeparator(.hidden)
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
                    .accessibilityIdentifier("settings.showThumbnails")

                    Toggle(isOn: $viewModel.compactFeedDesign) {
                        Label("Compact Feed Design", systemImage: "list.bullet.rectangle")
                    }
                    .accessibilityIdentifier("settings.compactFeed")
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
                        Text("Embedded Browser").tag(LinkBrowserMode.customBrowser)
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

                    Toggle(isOn: $viewModel.dimReadPosts) {
                        Label("Dim Read Posts", systemImage: "circle.lefthalf.filled")
                    }
                    .accessibilityIdentifier("settings.dimReadPosts")
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
            .accessibilityIdentifier("settings.form")
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
                .accessibilityLabel("Close")
                .accessibilityIdentifier("settings.close"))
            .sheet(isPresented: $showMailView) {
                feedbackMailView
            }
            .sheet(isPresented: $showWhatsNew) {
                WhatsNewService.createWhatsNewView {
                    onWhatsNewDismiss()
                    showWhatsNew = false
                }
                .textScaling(for: viewModel.textSize)
                .toastOverlay(toastPresenter)
            }
        }
        .textScaling(for: viewModel.textSize)
    }

    private func openGitHub() {
        if let url = URL(string: "https://github.com/weiran/hackers") {
            UIApplication.shared.open(url)
        }
    }

    private var feedbackMailView: some View {
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

        return MailView(
            result: $mailResult,
            recipients: ["weiran@zhang.me.uk"],
            subject: "Hackers App Feedback",
            messageBody: bodyLines.joined(separator: "\n"),
        )
    }

    private var versionLabel: some View {
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String
        let versionText = [appVersion, buildNumber.map { "(\($0))" }]
            .compactMap(\.self)
            .joined(separator: " ")

        return HStack {
            Spacer()
            Text("Version \(versionText.isEmpty ? "1.0" : versionText)")
                .foregroundStyle(.gray)
            Spacer()
        }
    }

}

private struct SettingsTopActionsSection: View {
    let canSendFeedback: Bool
    let openGitHub: () -> Void
    let sendFeedback: () -> Void
    let showWhatsNew: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            NavigationLink {
                SupportView()
            } label: {
                SettingsSupportActionLabel()
            }
            .buttonStyle(.plain)

            HStack(spacing: 10) {
                SettingsActionTile(
                    title: "GitHub",
                    systemImage: "link",
                    action: openGitHub
                )
                .accessibilityLabel("Hackers on GitHub")

                SettingsActionTile(
                    title: "Feedback",
                    systemImage: "paperplane",
                    action: sendFeedback
                )
                .disabled(!canSendFeedback)
                .opacity(canSendFeedback ? 1 : 0.45)
                .accessibilityLabel("Send Feedback")

                SettingsActionTile(
                    title: "What's New",
                    systemImage: "sparkles",
                    action: showWhatsNew
                )
                .accessibilityLabel("Show What's New")
            }
        }
        .padding(.vertical, 4)
    }
}

private struct SettingsSupportActionLabel: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "heart.fill")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(AppColors.appTintColor, in: Circle())
                .accessibilityHidden(true)

            Text("Support the App")
                .font(.headline)
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Spacer(minLength: 8)

            Image(systemName: "chevron.right")
                .font(.callout.weight(.semibold))
                .foregroundStyle(.tertiary)
                .accessibilityHidden(true)
        }
        .padding(16)
        .frame(minHeight: 76)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(AppColors.appTintColor.opacity(colorScheme == .dark ? 0.2 : 0.12))
        )
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(AppColors.appTintColor.opacity(colorScheme == .dark ? 0.28 : 0.16), lineWidth: 1)
        }
        .contentShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}

private struct SettingsActionTile: View {
    @Environment(\.colorScheme) private var colorScheme
    let title: String
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: systemImage)
                    .font(.title2.weight(.medium))
                    .frame(height: 28)
                    .accessibilityHidden(true)

                Text(title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.74)
                    .allowsTightening(true)

                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.tertiary)
                    .accessibilityHidden(true)
            }
            .foregroundStyle(AppColors.appTintColor)
            .frame(maxWidth: .infinity, minHeight: 112)
            .padding(.horizontal, 8)
            .background(AppColors.background, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(AppColors.separator(for: colorScheme), lineWidth: 1)
            }
            .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
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
