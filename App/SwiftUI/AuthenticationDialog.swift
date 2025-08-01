//
//  AuthenticationDialog.swift
//  Hackers
//
//  Created by Weiran Zhang on 01/08/2025.
//  Copyright © 2025 Glass Umbrella. All rights reserved.
//

import SwiftUI

struct AuthenticationDialog: ViewModifier {
    @Binding var isPresented: Bool
    let onLogin: () -> Void
    
    func body(content: Content) -> some View {
        content
            .confirmationDialog(
                "Not logged in",
                isPresented: $isPresented,
                titleVisibility: .visible
            ) {
                Button("Login") {
                    onLogin()
                }
                
                Button("Not Now", role: .cancel) {
                    // Dialog will dismiss automatically
                }
            } message: {
                Text("You're not logged into Hacker News. Do you want to login now?")
            }
    }
}

extension View {
    func authenticationDialog(
        isPresented: Binding<Bool>,
        onLogin: @escaping () -> Void
    ) -> some View {
        self.modifier(AuthenticationDialog(isPresented: isPresented, onLogin: onLogin))
    }
}