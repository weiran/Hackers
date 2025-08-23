//
//  Extensions.swift
//  Shared
//
//  Copyright © 2025 Weiran Zhang. All rights reserved.
//

import Foundation
import Domain

extension Collection where Indices.Iterator.Element == Index {
    public subscript (safe index: Index) -> Iterator.Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

extension NotificationCenter {
    public func observe(name: NSNotification.Name?, object obj: Any?,
                       queue: OperationQueue?,
                       using block: @escaping (Notification) -> Void) -> NotificationToken {
        let token = addObserver(forName: name, object: obj, queue: queue, using: block)
        return NotificationToken(notificationCenter: self, token: token)
    }
}

extension Notification.Name {
    public static let refreshRequired = NSNotification.Name(rawValue: "RefreshRequiredNotification")
}

extension PostType {
    public var displayName: String {
        switch self {
        case .news: return "Top"
        case .ask: return "Ask"
        case .show: return "Show"
        case .jobs: return "Jobs"
        case .newest: return "New"
        case .best: return "Best"
        case .active: return "Active"
        }
    }

    public var iconName: String {
        switch self {
        case .news: return "flame"
        case .ask: return "bubble.left.and.bubble.right"
        case .show: return "eye"
        case .jobs: return "briefcase"
        case .newest: return "clock"
        case .best: return "star"
        case .active: return "bolt"
        }
    }
}

extension String {
    public func strippingHTML() -> String {
        let pattern = "<[^>]+>"
        return self.replacingOccurrences(of: pattern, with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    public subscript(value: PartialRangeUpTo<Int>) -> Substring {
        return self[..<index(startIndex, offsetBy: value.upperBound)]
    }

    public subscript(value: PartialRangeThrough<Int>) -> Substring {
        return self[...index(startIndex, offsetBy: value.upperBound)]
    }

    public subscript(value: PartialRangeFrom<Int>) -> Substring {
        return self[index(startIndex, offsetBy: value.lowerBound)...]
    }

}
