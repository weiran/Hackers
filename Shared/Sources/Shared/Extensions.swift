import Foundation
import Domain

extension Post {
    public var hackerNewsURL: URL {
        URL(string: "\(HackerNewsConstants.baseURL)/item?id=\(id)")!
    }
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
}