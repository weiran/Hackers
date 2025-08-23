//
//  SettingsUseCase.swift
//  Domain
//
//  Copyright © 2025 Weiran Zhang. All rights reserved.
//

import Foundation

public protocol SettingsUseCase: Sendable {
    var safariReaderMode: Bool { get set }
    var showComments: Bool { get set }
    var openInDefaultBrowser: Bool { get set }
}
