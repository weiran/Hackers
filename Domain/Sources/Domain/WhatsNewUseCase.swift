//
//  WhatsNewUseCase.swift
//  Domain
//
//  Copyright © 2025 Weiran Zhang. All rights reserved.
//

import Foundation

public protocol WhatsNewUseCase: Sendable {
    func shouldShowWhatsNew(currentVersion: String, forceShow: Bool) -> Bool
    func markWhatsNewShown(for version: String)
}
