import Foundation
import UIKit
import SafariServices
import WebKit
import Domain

// Placeholder services that will be migrated later

@MainActor
public enum LinkOpener {
    public static func openURL(_ url: URL, with post: Post? = nil) {
        guard !url.absoluteString.starts(with: "item?id=") else { return }

        if UserDefaults.standard.bool(forKey: "openInDefaultBrowser") {
            // Open in system default browser
            UIApplication.shared.open(url)
        } else {
            // Open in internal Safari view controller
            if let svc = createSafariViewController(for: url) {
                PresentationService.shared.present(svc)
            } else {
                // Fallback to system browser if Safari view controller cannot be created
                UIApplication.shared.open(url)
            }
        }
    }
    
    private static func createSafariViewController(for url: URL) -> SFSafariViewController? {
        // Check if the URL scheme can be handled by WebKit
        guard WKWebView.handlesURLScheme(url.scheme ?? "") else {
            return nil
        }
        
        let configuration = SFSafariViewController.Configuration()
        // Note: Reader mode setting not available in Shared module
        // This would require accessing UserDefaults extensions from main app
        configuration.entersReaderIfAvailable = false
        
        return SFSafariViewController(url: url, configuration: configuration)
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
        UIApplication.shared.connectedScenes
            .first { $0.activationState == .foregroundActive } as? UIWindowScene
    }
    
    /// Gets the root view controller of the current window
    public var rootViewController: UIViewController? {
        windowScene?.windows.first?.rootViewController
    }
    
    /// Presents a view controller from the root view controller
    /// - Parameters:
    ///   - viewController: The view controller to present
    ///   - animated: Whether to animate the presentation
    ///   - completion: Optional completion handler
    public func present(
        _ viewController: UIViewController,
        animated: Bool = true,
        completion: (() -> Void)? = nil
    ) {
        guard let rootVC = rootViewController else {
            print("Warning: No root view controller available for presentation")
            return
        }
        
        rootVC.present(viewController, animated: animated, completion: completion)
    }
    
    private init() {}
}

public struct AppTheme: Sendable {
    public static let `default` = AppTheme()
    
    public var appTintColor: UIColor {
        UIColor.systemBlue
    }
}