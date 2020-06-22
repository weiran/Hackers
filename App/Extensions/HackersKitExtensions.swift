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
        case .jobs: return "Jobs"
        case .newest: return "New"
        case .best: return "Best"
        }
    }

    var iconName: String {
        switch self {
        case .news: return "globe"
        case .ask: return "bubble.left"
        case .jobs: return "briefcase"
        case .newest: return "clock"
        case .best: return "rosette"
        }
    }
}
