//
//  LoginView.swift
//  Authentication
//
//  Copyright © 2025 Weiran Zhang. All rights reserved.
//

import DesignSystem
import Domain
import Shared
import SwiftUI

public struct LoginView: View {
    @State private var viewModel: LoginViewModel
    @FocusState private var focusedField: Field?
    @Environment(\.dismiss) private var dismiss
    @Environment(ToastPresenter.self) private var toastPresenter

    private enum Field {
        case username, password
    }

    public init(
        isAuthenticated: Bool,
        currentUsername: String?,
        onLogin: @escaping (String, String) async throws -> Void,
        onLogout: @escaping () -> Void,
        textSize: TextSize = .medium
    ) {
        let viewModel = LoginViewModel(
            isAuthenticated: isAuthenticated,
            currentUsername: currentUsername,
            onLogin: onLogin,
            onLogout: onLogout,
            textSize: textSize
        )
        _viewModel = State(initialValue: viewModel)
    }

    public init(viewModel: LoginViewModel) {
        _viewModel = State(wrappedValue: viewModel)
    }

    public var body: some View {
        NavigationStack {
            if !viewModel.isAuthenticated {
                loginView
            } else {
                loggedInView
            }
        }
        .textScaling(for: viewModel.textSize)
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
                Button(action: dismiss.callAsFunction) {
                    Image(systemName: "xmark")
                }
                .accessibilityLabel("Close")
            }
        }
        .alert("Login Failed", isPresented: Binding(
            get: { viewModel.showAlert },
            set: { viewModel.showAlert = $0 }
        )) {
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
                    .foregroundStyle(AppGradients.brandSymbol())
                    .symbolRenderingMode(.hierarchical)
                    .accessibilityHidden(true)

                VStack(spacing: 8) {
                    Text("Welcome to")
                        .font(.title2)
                        .foregroundStyle(.secondary)

                    Text("Hacker News")
                        .font(.largeTitle)
                        .bold()
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
                    text: $viewModel.username,
                    isSecure: false
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
                    text: $viewModel.password,
                    isSecure: true
                )
                .textContentType(.password)
                .focused($focusedField, equals: .password)
                .onSubmit {
                    if viewModel.isLoginEnabled {
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

                Button(action: performLogin) {
                    HStack {
                        if viewModel.isAuthenticating {
                            ProgressView()
                                .controlSize(.small)
                                .tint(.white)
                        } else {
                            Image(systemName: "person.badge.key.fill")
                                .font(.callout)
                                .accessibilityHidden(true)
                        }

                        Text(viewModel.isAuthenticating ? "Signing in..." : "Sign In")
                            .font(.headline)
                            .bold()
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .foregroundStyle(.white)
                    .background(AppGradients.primaryButton(isEnabled: viewModel.isLoginEnabled))
                    .clipShape(.rect(cornerRadius: 16))
                    .scaleEffect(viewModel.isAuthenticating ? 0.95 : 1.0)
                    .animation(.easeInOut(duration: 0.1), value: viewModel.isAuthenticating)
                }
                .disabled(!viewModel.isLoginEnabled)
                .padding(.horizontal, 20)
            }

            Spacer(minLength: 40)
        }
        .padding(.top, 32)
    }

    private var loggedInView: some View {
        VStack(spacing: 40) {
            Spacer()

            VStack(spacing: 24) {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(AppGradients.successSymbol())
                    .symbolRenderingMode(.hierarchical)
                    .accessibilityHidden(true)

                VStack(spacing: 12) {
                    Text("Welcome back!")
                        .font(.title2)
                        .foregroundStyle(.secondary)

                    Text(viewModel.currentUsername ?? "")
                        .font(.largeTitle)
                        .bold()
                        .foregroundStyle(.primary)
                }
            }

            VStack(spacing: 20) {
                Button {
                    viewModel.logout()
                    toastPresenter.show(text: "Signed out", kind: .success)
                } label: {
                    HStack {
                        Image(systemName: "person.badge.minus")
                            .font(.callout)
                            .accessibilityHidden(true)

                        Text("Sign Out")
                            .font(.headline)
                            .bold()
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .foregroundStyle(.white)
                    .background(AppGradients.destructiveButton())
                    .clipShape(.rect(cornerRadius: 16))
                }
                .padding(.horizontal, 20)
            }

            Spacer()
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: dismiss.callAsFunction) {
                    Image(systemName: "xmark")
                }
                .accessibilityLabel("Close")
            }
        }
    }

    private func performLogin() {
        focusedField = nil
        Task { @MainActor in
            let enteredUsername = viewModel.username
            let success = await viewModel.performLogin()
            if success {
                toastPresenter.show(text: "Welcome back, \(enteredUsername)", kind: .success)
                dismiss()
            } else {
                focusedField = .password
            }
        }
    }
}

// Removed unused RoundedTextField to avoid identifier_name warning on _body(protocol requirement)
