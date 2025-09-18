//
//  PostType+DisplayProperties.swift
//  Shared
//
//  Provides display metadata for Hacker News post categories.
//

import Domain

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
