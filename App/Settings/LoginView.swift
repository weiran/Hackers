//
//  LoginView.swift
//  Hackers
//
//  Created by Weiran Zhang on 04/04/2022.
//  Copyright © 2022 Weiran Zhang. All rights reserved.
//

import SwiftUI
import Swinject
import SwinjectStoryboard

struct LoginView: View {
    @State var isAuthenticated: Bool
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var isAuthenticating = false
    @State private var showAlert = false

    private var sessionService: SessionService

    @Environment(\.dismiss) var dismiss

    init() {
        // can't use @Inject for SessionService here as it runs after init
        sessionService = SwinjectStoryboard.defaultContainer.resolve(SessionService.self)!
        _isAuthenticated = State(
            initialValue: sessionService.authenticationState == .authenticated
        )
    }

    @ViewBuilder
    var body: some View {
        NavigationStack {
            if isAuthenticated == false {
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
                                _ = try await sessionService.authenticate(username: username, password: password)
                                await MainActor.run {
                                    isAuthenticated = true
                                    UINotifications.showSuccess("Logged in as \(username)")
                                    dismiss()
                                    NotificationCenter.default.post(name: Notification.Name.refreshRequired,
                                                                    object: nil)
                                    isAuthenticating = false
                                }
                            } catch {
                                await MainActor.run {
                                    showAlert = true
                                    password = ""
                                    isAuthenticating = false
                                }
                            }
                        }
                    }.buttonStyle(FilledButton())
                        .padding(.top, 30)
                        .disabled(isAuthenticating)
                        .alert(isPresented: $showAlert) {
                            Alert(
                                title: Text("Login Failed"),
                                message:
                                    Text(
                                        "Failed logging into Hacker News, check your username or password."
                                    )
                            )
                        }
                }
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            dismiss()
                        } label: {
                            Text("Done")
                                .bold()
                        }
                    }
                }
            } else {
                VStack {
                    Text("Logged in as")
                        .font(.title)
                    Text(sessionService.username ?? "")
                        .font(.title)
                        .bold()
                        .padding(.bottom, 30)

                    Button("Log out") {
                        sessionService.unauthenticate()
                        isAuthenticated = false
                        NotificationCenter.default.post(name: Notification.Name.refreshRequired, object: nil)
                    }.buttonStyle(FilledButton())
                }
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            dismiss()
                        } label: {
                            Text("Done")
                                .bold()
                        }
                    }
                }
            }
        }
    }
}

struct RoundedTextField: TextFieldStyle {
    // swiftlint:disable:next identifier_name
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(.all, 10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.secondary, lineWidth: 0.5)
            )
            .padding(.horizontal, 20)
    }
}

struct FilledButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
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

struct LabelledDivider: View {
    let label: String
    let horizontalPadding: CGFloat
    let color: Color

    init(label: String, horizontalPadding: CGFloat = 20, color: Color = .secondary) {
        self.label = label
        self.horizontalPadding = horizontalPadding
        self.color = color
    }

    var body: some View {
        HStack {
            line
            Text(label).foregroundColor(color)
            line
        }
    }

    var line: some View {
        VStack { Divider().background(color) }.padding(horizontalPadding)
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        let view = LoginView()
        view.isAuthenticated = true
        return view
    }
}
