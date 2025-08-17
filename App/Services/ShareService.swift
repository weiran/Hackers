import UIKit
import SwiftUI

/// Service that provides centralized sharing functionality
/// Eliminates duplicate share sheet presentation code across views
@MainActor
class ShareService: ObservableObject {
    static let shared = ShareService()
    private let presentationService = PresentationService.shared
    
    private init() {}
    
    /// Shares items using the system share sheet
    /// - Parameters:
    ///   - items: Array of items to share (URLs, strings, images, etc.)
    ///   - subject: Optional subject for the share (used in email)
    ///   - sourceView: Optional source view for iPad popover
    ///   - sourceRect: Optional source rect for iPad popover
    func share(
        items: [Any],
        subject: String? = nil,
        sourceView: UIView? = nil,
        sourceRect: CGRect? = nil
    ) {
        let activityVC = UIActivityViewController(
            activityItems: items,
            applicationActivities: nil
        )
        
        // Set subject if provided (for email sharing)
        if let subject = subject {
            activityVC.setValue(subject, forKey: "subject")
        }
        
        // Configure popover for iPad
        if let popover = activityVC.popoverPresentationController {
            presentationService.configurePopover(
                popover,
                sourceView: sourceView,
                sourceRect: sourceRect
            )
        }
        
        presentationService.present(activityVC)
    }
    
    /// Shares a URL with an optional title
    /// - Parameters:
    ///   - url: The URL to share
    ///   - title: Optional title for the share (used as subject in email)
    func shareURL(_ url: URL, title: String? = nil) {
        share(items: [url], subject: title)
    }
    
    /// Shares a post from the feed
    /// - Parameter post: The post to share
    func sharePost(_ post: Post) {
        let url = post.url.host != nil ? post.url : post.hackerNewsURL
        shareURL(url, title: post.title)
    }
    
    /// Shares a comment
    /// - Parameter comment: The comment to share
    func shareComment(_ comment: Comment) {
        shareURL(comment.hackerNewsURL, title: "Comment by \(comment.by)")
    }
}

// MARK: - SwiftUI View Modifier for Easy Sharing

struct ShareableModifier: ViewModifier {
    let items: [Any]
    let subject: String?
    @State private var isPresented = false
    
    func body(content: Content) -> some View {
        content
            .onTapGesture {
                ShareService.shared.share(items: items, subject: subject)
            }
    }
}

extension View {
    /// Makes a view shareable with tap gesture
    /// - Parameters:
    ///   - items: Items to share when tapped
    ///   - subject: Optional subject for email sharing
    func shareable(items: [Any], subject: String? = nil) -> some View {
        modifier(ShareableModifier(items: items, subject: subject))
    }
}
