//
//  FormEncoder.swift
//  Networking
//
//  Copyright © 2025 Weiran Zhang. All rights reserved.
//

import Foundation

/// An ordered `application/x-www-form-urlencoded` field.
public struct FormField: Sendable, Equatable {
    public let name: String
    public let value: String

    public init(name: String, value: String) {
        self.name = name
        self.value = value
    }
}

/// Encodes ordered form fields as `application/x-www-form-urlencoded`.
///
/// Used for Hacker News login and comment submission bodies. Fields are ordered
/// (and may repeat) because server-provided forms must be echoed back verbatim.
public enum FormEncoder {
    private static let allowedCharacters = CharacterSet(
        charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._*"
    )

    public static func encode(_ fields: [FormField]) -> String {
        fields
            .map { "\(encodeValue($0.name))=\(encodeValue($0.value))" }
            .joined(separator: "&")
    }

    public static func encodeValue(_ value: String) -> String {
        guard let encoded = value.addingPercentEncoding(withAllowedCharacters: allowedCharacters) else {
            return ""
        }
        // application/x-www-form-urlencoded encodes spaces as "+", not "%20".
        return encoded.replacingOccurrences(of: "%20", with: "+")
    }
}
