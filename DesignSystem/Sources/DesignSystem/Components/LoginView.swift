//
//  LoginView.swift
//  DesignSystem
//
//  Copyright © 2025 Weiran Zhang. All rights reserved.
//

import SwiftUI
import Domain
import Shared

public struct LoginView: View {
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var isAuthenticating = false
    @State private var showAlert = false
    @Environment(\.dismiss) var dismiss

    let isAuthenticated: Bool
    let currentUsername: String?
    let onLogin: (String, String) async throws -> Void
    let onLogout: () -> Void

    public init(
        isAuthenticated: Bool,
        currentUsername: String?,
        onLogin: @escaping (String, String) async throws -> Void,
        onLogout: @escaping () -> Void
    ) {
        self.isAuthenticated = isAuthenticated
        self.currentUsername = currentUsername
        self.onLogin = onLogin
        self.onLogout = onLogout
    }

    public var body: some View {
        NavigationStack {
            if !isAuthenticated {
                VStack {
                    Text("Login to Hacker News")
                        .font(.largeTitle)
                        .padding(.bottom, 30)

                    TextField("Username", text: $username)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .textFieldStyle(RoundedTextField())
                        .textContentType(.username)

                    SecureField("Password", text: $password)
                        .textFieldStyle(RoundedTextField())
                        .textContentType(.password)

                    Text("Hackers never stores your password")
                        .foregroundColor(Color.secondary)
                        .font(.footnote)

                    Button("Login") {
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
                                }
                            }
                        }
                    }
                    .buttonStyle(FilledButton())
                    .padding(.top, 30)
                    .disabled(isAuthenticating)
                    .alert(isPresented: $showAlert) {
                        Alert(
                            title: Text("Login Failed"),
                            message: Text("Failed logging into Hacker News, check your username or password.")
                        )
                    }
                }
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                        }
                    }
                }
            } else {
                VStack {
                    Text("Logged in as")
                        .font(.title)
                    Text(currentUsername ?? "")
                        .font(.title)
                        .bold()
                        .padding(.bottom, 30)

                    Button("Log out") {
                        onLogout()
                        dismiss()
                    }
                    .buttonStyle(FilledButton())
                }
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                        }
                    }
                }
            }
        }
    }
}

public struct RoundedTextField: TextFieldStyle {
    // swiftlint:disable:next identifier_name
    public func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(.all, 10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.secondary, lineWidth: 0.5)
            )
            .padding(.horizontal, 20)
    }
}

public struct FilledButton: ButtonStyle {
    public func makeBody(configuration: Configuration) -> some View {
        configuration
            .label
            .font(.headline)
            .padding()
            .padding(.horizontal, 50)
            .frame(maxWidth: .infinity)
            .foregroundColor(Color.white)
            .background(Color.accentColor)
            .cornerRadius(15)
            .padding(.horizontal, 20)
    }
}
