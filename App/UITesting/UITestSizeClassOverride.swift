#if DEBUG
import Foundation
import Observation
import Shared
import SwiftUI
import UIKit

/// Simulates the horizontal size-class change of folding or unfolding an iPhone Duo when a
/// UI test posts a `UITestSizeClassNotification`. Neither XCUITest nor `simctl` can fold the
/// simulator, so the root view applies the override and the adaptive split view responds
/// exactly as it does to a real size-class change.
@MainActor
@Observable
final class UITestSizeClassOverride {
    static let shared = UITestSizeClassOverride()

    private(set) var horizontalSizeClass: UserInterfaceSizeClass?
    @ObservationIgnored private var isListening = false

    func startListeningIfNeeded() {
        guard UITestingBootstrap.isEnabled, !isListening else { return }
        isListening = true
        let center = CFNotificationCenterGetDarwinNotifyCenter()
        for name in [UITestSizeClassNotification.regular, UITestSizeClassNotification.compact] {
            CFNotificationCenterAddObserver(
                center,
                nil,
                { _, _, name, _, _ in
                    let isRegular = name?.rawValue as String? == UITestSizeClassNotification.regular
                    Task { @MainActor in
                        UITestSizeClassOverride.shared.apply(isRegular ? .regular : .compact)
                    }
                },
                name as CFString,
                nil,
                .deliverImmediately
            )
        }
    }

    private func apply(_ sizeClass: UserInterfaceSizeClass) {
        horizontalSizeClass = sizeClass
        let traitSizeClass: UIUserInterfaceSizeClass = sizeClass == .regular ? .regular : .compact
        for scene in UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }) {
            scene.traitOverrides.horizontalSizeClass = traitSizeClass
            for window in scene.windows {
                window.rootViewController?.traitOverrides.horizontalSizeClass = traitSizeClass
            }
        }
    }
}
#endif
