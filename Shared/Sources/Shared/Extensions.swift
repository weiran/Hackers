//
//  Extensions.swift
//  Shared
//
//  Copyright © 2025 Weiran Zhang. All rights reserved.
//

import Domain
import Foundation
import SwiftUI

public extension Collection where Indices.Iterator.Element == Index {
    subscript(safe index: Index) -> Iterator.Element? {
        indices.contains(index) ? self[index] : nil
    }
}

public extension NotificationCenter {
    func observe(
        name: NSNotification.Name?,
        object obj: Any?,
        queue: OperationQueue?,
        using block: @escaping (Notification) -> Void,
    ) -> NotificationToken {
        let token = addObserver(forName: name, object: obj, queue: queue, using: block)
        return NotificationToken(notificationCenter: self, token: token)
    }
}

public extension Notification.Name {
    static let refreshRequired = NSNotification.Name(rawValue: "RefreshRequiredNotification")
    static let userDidLogout = NSNotification.Name(rawValue: "UserDidLogoutNotification")
}

public extension PostType {
    var displayName: String {
        switch self {
        case .news: "Top"
        case .ask: "Ask"
        case .show: "Show"
        case .jobs: "Jobs"
        case .newest: "New"
        case .best: "Best"
        case .active: "Active"
        }
    }

    var iconName: String {
        switch self {
        case .news: "flame"
        case .ask: "bubble.left.and.bubble.right"
        case .show: "eye"
        case .jobs: "briefcase"
        case .newest: "clock"
        case .best: "star"
        case .active: "bolt"
        }
    }
}

public extension String {
    func strippingHTML() -> String {
        let pattern = "<[^>]+>"
        return replacingOccurrences(of: pattern, with: "", options: .regularExpression)
            .replacingOccurrences(of: "\t", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
    subscript(value: PartialRangeUpTo<Int>) -> Substring {
        self[..<index(startIndex, offsetBy: value.upperBound)]
    }

    subscript(value: PartialRangeThrough<Int>) -> Substring {
        self[...index(startIndex, offsetBy: value.upperBound)]
    }

    subscript(value: PartialRangeFrom<Int>) -> Substring {
        self[index(startIndex, offsetBy: value.lowerBound)...]
    }
}

// MARK: - View helpers

public extension View {
    @ViewBuilder
    func `if`(_ condition: Bool, transform: (Self) -> some View) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}
