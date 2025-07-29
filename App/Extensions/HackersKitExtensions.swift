//
//  HackersKitExtensions.swift
//  Hackers
//
//  Created by Weiran Zhang on 21/09/2019.
//  Copyright © 2019 Weiran Zhang. All rights reserved.
//

import Foundation

extension Post {
    var hackerNewsURL: URL {
        return URL(string: "https://news.ycombinator.com/item?id=\(id)")!
    }
}

extension PostType {
    var title: String {
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

    var iconName: String {
        switch self {
        case .news: return "globe"
        case .ask: return "bubble.left"
        case .show: return "eye"
        case .jobs: return "briefcase"
        case .newest: return "clock"
        case .best: return "rosette"
        case .active: return "bolt"
        }
    }
}

extension Comment {
    var hackerNewsURL: URL {
        return URL(string: "https://news.ycombinator.com/item?id=\(id)")!
    }
}
