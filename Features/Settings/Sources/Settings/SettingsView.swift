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
    @State private var showSupport = false
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
                    SettingsHeroSection(
                        canSendFeedback: MFMailComposeViewController.canSendMail(),
                        donate: { showSupport = true },
                        openGitHub: openGitHub,
                        sendFeedback: { showMailView = true },
                        showWhatsNew: { showWhatsNew = true }
                    )
                    .listRowInsets(EdgeInsets())
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
            .navigationDestination(isPresented: $showSupport) {
                SupportView()
            }
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

    private var feedbackBodyLines: [String] {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        let deviceIdentifier = UIDevice.current.modelIdentifier
        let systemVersion = UIDevice.current.systemVersion
        return [
            "",
            "",
            "",
            "---",
            "App Version: \(version)",
            "Device Model: \(deviceIdentifier)",
            "iOS Version: \(systemVersion)"
        ]
    }

    private var feedbackMailView: some View {
        return MailView(
            result: $mailResult,
            recipients: ["weiran@zhang.me.uk"],
            subject: "Hackers App Feedback",
            messageBody: feedbackBodyLines.joined(separator: "\n"),
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

private struct SettingsHeroSection: View {
    let canSendFeedback: Bool
    let donate: () -> Void
    let openGitHub: () -> Void
    let sendFeedback: () -> Void
    let showWhatsNew: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .center, spacing: 14) {
                AppIconView()

                VStack(alignment: .leading, spacing: 4) {
                    Text("Hackers")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.primary)

                    authorLine
                }
            }

            Divider()

            Grid(horizontalSpacing: 10, verticalSpacing: 10) {
                GridRow {
                    SettingsHeroButton(
                        title: "Donate",
                        systemImage: "heart",
                        style: .primary,
                        action: donate
                    )

                    SettingsHeroButton(
                        title: "GitHub",
                        systemImage: "link",
                        action: openGitHub
                    )
                }

                GridRow {
                    SettingsHeroButton(
                        title: "Feedback",
                        systemImage: "paperplane",
                        isEnabled: canSendFeedback,
                        action: sendFeedback
                    )

                    SettingsHeroButton(
                        title: "What's New",
                        systemImage: "sparkles",
                        action: showWhatsNew
                    )
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    private var authorLine: some View {
        HStack(spacing: 0) {
            Text("By ")
                .foregroundStyle(.secondary)

            if let url = URL(string: "https://weiranzhang.com") {
                Link("Weiran Zhang", destination: url)
                    .foregroundStyle(AppColors.appTintColor)
            } else {
                Text("Weiran Zhang")
                    .foregroundStyle(.secondary)
            }
        }
        .font(.subheadline)
        .fixedSize(horizontal: false, vertical: true)
    }
}

private struct AppIconView: View {
    var body: some View {
        Group {
            if let icon = Bundle.main.icon {
                Image(uiImage: icon)
                    .resizable()
            } else {
                Image(systemName: "h.square.fill")
                    .resizable()
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(AppColors.appTintColor, AppColors.background)
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .frame(width: 72, height: 72)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: .black.opacity(0.12), radius: 10, x: 0, y: 5)
        .accessibilityHidden(true)
    }
}

private struct SettingsHeroButton: View {
    let title: String
    let systemImage: String
    var style: SettingsHeroAction.Style = .secondary
    var isEnabled = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            SettingsHeroAction(title: title, systemImage: systemImage, style: style)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.45)
        .accessibilityLabel(accessibilityLabel)
    }

    private var accessibilityLabel: String {
        switch title {
        case "Donate": "Donate"
        case "GitHub": "Hackers on GitHub"
        case "Feedback": "Send Feedback"
        case "What's New": "Show What's New"
        default: title
        }
    }
}

private struct SettingsHeroAction: View {
    enum Style {
        case primary
        case secondary
    }

    let title: String
    let systemImage: String
    let style: Style

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: systemImage)
                .font(.headline.weight(.semibold))
                .frame(width: 20)
                .accessibilityHidden(true)

            Text(title)
                .font(.subheadline.weight(.semibold))
                .lineLimit(1)
                .allowsTightening(true)
                .layoutPriority(1)

            Spacer(minLength: 3)

            Image(systemName: "chevron.right")
                .font(.caption2.weight(.bold))
                .frame(width: 7)
                .accessibilityHidden(true)
        }
        .foregroundStyle(foregroundStyle)
        .frame(maxWidth: .infinity, minHeight: 48, alignment: .leading)
        .padding(.horizontal, 12)
        .background(backgroundStyle, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var foregroundStyle: Color {
        switch style {
        case .primary: .white
        case .secondary: AppColors.appTintColor
        }
    }

    private var backgroundStyle: Color {
        switch style {
        case .primary: AppColors.appTintColor
        case .secondary: AppColors.appTintColor.opacity(0.1)
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
