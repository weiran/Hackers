//
//  SettingsUseCase.swift
//  Domain
//
//  Copyright © 2025 Weiran Zhang. All rights reserved.
//

import Foundation

public enum TextSize: Int, CaseIterable, Sendable {
    case extraSmall = 0
    case small = 1
    case medium = 2
    case large = 3
    case extraLarge = 4

    public var displayName: String {
        switch self {
        case .extraSmall: "Extra Small"
        case .small: "Small"
        case .medium: "Medium"
        case .large: "Large"
        case .extraLarge: "Extra Large"
        }
    }

    public var scaleFactor: CGFloat {
        switch self {
        case .extraSmall: 0.8
        case .small: 0.9
        case .medium: 1.0
        case .large: 1.1
        case .extraLarge: 1.2
        }
    }
}

public protocol SettingsUseCase: Sendable {
    var safariReaderMode: Bool { get set }
    var openInDefaultBrowser: Bool { get set }
    var textSize: TextSize { get set }
    func clearCache()
    func cacheUsageBytes() async -> Int64
}
