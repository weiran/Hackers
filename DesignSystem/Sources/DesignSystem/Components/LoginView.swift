//
//  LoginView.swift
//  DesignSystem
//
//  Copyright © 2025 Weiran Zhang. All rights reserved.
//

import Domain
import Shared
import SwiftUI

public struct LoginView: View {
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var isAuthenticating = false
    @State private var showAlert = false
    @FocusState private var focusedField: Field?
    @Environment(\.dismiss) var dismiss

    let isAuthenticated: Bool
    let currentUsername: String?
    let onLogin: (String, String) async throws -> Void
    let onLogout: () -> Void

    private enum Field {
        case username, password
    }

    public init(
        isAuthenticated: Bool,
        currentUsername: String?,
        onLogin: @escaping (String, String) async throws -> Void,
        onLogout: @escaping () -> Void,
    ) {
        self.isAuthenticated = isAuthenticated
        self.currentUsername = currentUsername
        self.onLogin = onLogin
        self.onLogout = onLogout
    }

    public var body: some View {
        NavigationStack {
            if !isAuthenticated {
                loginView
            } else {
                loggedInView
            }
        }
    }

    private var loginView: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 0) {
                    headerSection
                        .frame(minHeight: geometry.size.height * 0.4)

                    formSection
                        .frame(minHeight: geometry.size.height * 0.6)
                }
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .background(AppGradients.screenBackground())
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                }
                .accessibilityLabel("Close")
            }
        }
        .alert("Login Failed", isPresented: $showAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Please check your username and password and try again.")
        }
    }

    private var headerSection: some View {
        VStack(spacing: 24) {
            Spacer()

            VStack(spacing: 16) {
                Image(systemName: "newspaper.circle.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(.orange.gradient)
                    .symbolRenderingMode(.hierarchical)
                    .accessibilityHidden(true)

                VStack(spacing: 8) {
                    Text("Welcome to")
                        .font(.title2)
                        .foregroundStyle(.secondary)

                    Text("Hacker News")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)
                }
            }

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private var formSection: some View {
        VStack(spacing: 32) {
            VStack(spacing: 20) {
                AppTextField(
                    title: "Username",
                    text: $username,
                    isSecure: false,
                )
                .textContentType(.username)
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .focused($focusedField, equals: .username)
                .onSubmit {
                    focusedField = .password
                }

                AppTextField(
                    title: "Password",
                    text: $password,
                    isSecure: true,
                )
                .textContentType(.password)
                .focused($focusedField, equals: .password)
                .onSubmit {
                    if !username.isEmpty, !password.isEmpty {
                        performLogin()
                    }
                }
            }

            VStack(spacing: 24) {
                HStack(spacing: 8) {
                    Image(systemName: "lock.shield")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .accessibilityHidden(true)

                    Text("Your password is never stored on this device")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Button {
                    performLogin()
                } label: {
                    HStack {
                        if isAuthenticating {
                            ProgressView()
                                .controlSize(.small)
                                .tint(.white)
                        } else {
                            Image(systemName: "person.badge.key.fill")
                                .font(.callout)
                                .accessibilityHidden(true)
                        }

                        Text(isAuthenticating ? "Signing in..." : "Sign In")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .foregroundColor(.white)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(AppGradients.primaryButton(isEnabled: isLoginEnabled)),
                    )
                    .scaleEffect(isAuthenticating ? 0.95 : 1.0)
                    .animation(.easeInOut(duration: 0.1), value: isAuthenticating)
                }
                .disabled(!isLoginEnabled)
                .padding(.horizontal, 20)
            }

            Spacer(minLength: 40)
        }
        .padding(.top, 32)
    }

    private var isLoginEnabled: Bool {
        !isAuthenticating && !username.isEmpty && !password.isEmpty
    }

    private var loggedInView: some View {
        VStack(spacing: 40) {
            Spacer()

            VStack(spacing: 24) {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(.green.gradient)
                    .symbolRenderingMode(.hierarchical)
                    .accessibilityHidden(true)

                VStack(spacing: 12) {
                    Text("Welcome back!")
                        .font(.title2)
                        .foregroundStyle(.secondary)

                    Text(currentUsername ?? "")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)
                }
            }

            VStack(spacing: 20) {
                Button {
                    onLogout()
                } label: {
                    HStack {
                        Image(systemName: "person.badge.minus")
                            .font(.callout)
                            .accessibilityHidden(true)

                        Text("Sign Out")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .foregroundColor(.white)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(AppGradients.destructiveButton()),
                    )
                }
                .padding(.horizontal, 20)
            }

            Spacer()
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                }
                .accessibilityLabel("Close")
            }
        }
    }

    private func performLogin() {
        focusedField = nil
        isAuthenticating = true

        Task {
            do {
                try await onLogin(username, password)
                await MainActor.run {
                    isAuthenticating = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    showAlert = true
                    password = ""
                    isAuthenticating = false
                    focusedField = .password
                }
            }
        }
    }
}

public struct AppTextField: View {
    private let title: String
    @Binding private var text: String
    private let isSecure: Bool
    @Environment(\.colorScheme) private var colorScheme
    @FocusState private var isFocused: Bool

    public init(title: String, text: Binding<String>, isSecure: Bool) {
        self.title = title
        self._text = text
        self.isSecure = isSecure
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
                .padding(.leading, 4)

            Group {
                if isSecure {
                    SecureField("", text: $text)
                } else {
                    TextField("", text: $text)
                }
            }
            .font(.body)
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(fieldBackgroundColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(borderColor, lineWidth: AppFieldTheme.borderWidth(isFocused: isFocused)),
                    ),
            )
            .focused($isFocused)
        }
        .padding(.horizontal, 20)
        .animation(.easeInOut(duration: 0.2), value: isFocused)
    }

    private var fieldBackgroundColor: Color {
        AppFieldTheme.background(for: colorScheme)
    }

    private var borderColor: Color {
        AppFieldTheme.borderColor(for: colorScheme, isFocused: isFocused)
    }
}

// Removed unused RoundedTextField to avoid identifier_name warning on _body(protocol requirement)

public struct FilledButton: ButtonStyle {
    public func makeBody(configuration: Configuration) -> some View {
        configuration
            .label
            .scaledFont(.headline)
            .padding()
            .padding(.horizontal, 50)
            .frame(maxWidth: .infinity)
            .foregroundColor(Color.white)
            .background(Color.accentColor)
            .cornerRadius(15)
            .padding(.horizontal, 20)
    }
}
