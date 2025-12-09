//
//  AppTextField.swift
//  DesignSystem
//
//  Copyright © 2025 Weiran Zhang. All rights reserved.
//

import SwiftUI

public struct AppTextField: View {
    private let title: String
    @Binding private var text: String
    private let isSecure: Bool
    @Environment(\.colorScheme) private var colorScheme
    @FocusState private var isFocused: Bool

    public init(title: String, text: Binding<String>, isSecure: Bool) {
        self.title = title
        _text = text
        self.isSecure = isSecure
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .bold()
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
            .background(AppFieldTheme.background(for: colorScheme))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(
                        AppFieldTheme.borderColor(for: colorScheme, isFocused: isFocused),
                        lineWidth: AppFieldTheme.borderWidth(isFocused: isFocused)
                    )
            )
            .clipShape(.rect(cornerRadius: 12))
            .focused($isFocused)
        }
        .padding(.horizontal, 20)
        .animation(.easeInOut(duration: 0.2), value: isFocused)
    }
}
