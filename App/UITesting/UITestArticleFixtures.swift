#if DEBUG
import Domain
import Foundation
import Shared
import SwiftUI

struct UITestArticleContent: Equatable {
    let title: String
    let body: String
}

enum UITestArticleFixtures {
    static func article(for url: URL) -> UITestArticleContent? {
        switch url.absoluteString {
        case "https://hacktivis.me/articles/cloudflare-turnstile-webgl-fingerprinting":
            return UITestArticleContent(
                title: "Cloudflare Turnstile requiring fingerprintable WebGL",
                body: "Fixture article loaded from the UI-test Hacker News Active snapshot."
            )
        case "https://www.swift.org/blog/swift-6.2-released/":
            return UITestArticleContent(
                title: "Swift 6.2 Released",
                body: "Fixture article loaded from the UI-test Hacker News Active snapshot."
            )
        case "https://www.swift.org/documentation/migration-guide/":
            return UITestArticleContent(
                title: "Swift 6.2 Migration Guide",
                body: "Deterministic local migration guidance for the UI-test search result."
            )
        case "https://simpleflying.com/united-airlines-767-returns-newark-bluetooth-name-alert/":
            return UITestArticleContent(
                title: "United Airlines 767 returns to Newark",
                body: "Fixture article for a current Active thread with a lively comment discussion."
            )
        case "https://example.com/ui-test-large-comments":
            return UITestArticleContent(
                title: "Large comments stress fixture",
                body: "Deterministic local article content for the large comments UI-test discussion."
            )
        default:
            return nil
        }
    }
}
#endif
