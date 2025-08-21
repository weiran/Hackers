import Foundation
import UIKit
import Domain

// Placeholder services that will be migrated later

@MainActor
public enum LinkOpener {
    public static func openURL(_ url: URL, with post: Post? = nil) {
        UIApplication.shared.open(url)
    }
}

@MainActor
public final class ShareService: Sendable {
    public static let shared = ShareService()
    
    private init() {}
    
    public func shareURL(_ url: URL, title: String) {
        // Placeholder implementation
    }
    
    public func shareComment(_ comment: Comment) {
        // Placeholder implementation
    }
}

@MainActor
public final class PresentationService: Sendable {
    public static let shared = PresentationService()
    
    public var windowScene: UIWindowScene? {
        UIApplication.shared.connectedScenes.first as? UIWindowScene
    }
    
    private init() {}
}

public struct AppTheme: Sendable {
    public static let `default` = AppTheme()
    
    public var appTintColor: UIColor {
        UIColor.systemBlue
    }
}