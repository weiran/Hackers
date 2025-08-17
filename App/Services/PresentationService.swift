import UIKit
import SwiftUI

/// Service that provides a centralized way to present view controllers
/// and access the current window scene, eliminating duplicate UIApplication.shared access
@MainActor
class PresentationService: ObservableObject {
    static let shared = PresentationService()
    
    private init() {}
    
    /// Gets the current window scene
    var windowScene: UIWindowScene? {
        UIApplication.shared.connectedScenes
            .first { $0.activationState == .foregroundActive } as? UIWindowScene
    }
    
    /// Gets the root view controller of the current window
    var rootViewController: UIViewController? {
        windowScene?.windows.first?.rootViewController
    }
    
    /// Presents a view controller from the root view controller
    /// - Parameters:
    ///   - viewController: The view controller to present
    ///   - animated: Whether to animate the presentation
    ///   - completion: Optional completion handler
    func present(
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
    
    /// Configures a popover presentation controller for iPad
    /// - Parameters:
    ///   - popover: The popover presentation controller to configure
    ///   - sourceView: Optional source view for the popover. If nil, centers on screen
    ///   - sourceRect: Optional source rect for the popover
    func configurePopover(
        _ popover: UIPopoverPresentationController,
        sourceView: UIView? = nil,
        sourceRect: CGRect? = nil
    ) {
        let view = sourceView ?? rootViewController?.view
        guard let presentingView = view else { return }
        
        popover.sourceView = presentingView
        
        if let rect = sourceRect {
            popover.sourceRect = rect
        } else {
            // Center the popover if no source rect provided
            popover.sourceRect = CGRect(
                x: presentingView.bounds.midX,
                y: presentingView.bounds.midY,
                width: 0,
                height: 0
            )
            popover.permittedArrowDirections = []
        }
    }
}