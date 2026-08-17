//
//  DeviceLayout.swift
//  Shared
//
//  Centralises device-class detection so adaptive layout and Mac-specific behavior
//  don't get re-implemented (and drift) across the app, feature views, and services.
//

import Domain
import UIKit

@MainActor
public enum DeviceLayout {
    /// True when the interface should use the iPad/Mac split-view layout.
    ///
    /// Covers iPad idiom, iOS apps running on macOS, and Mac Catalyst builds. Previously
    /// this check was duplicated in ContentView, EmbeddedWebView, and NavigationStore with
    /// subtly different forms; route them all through here so the definition stays single.
    public static var usesPadLayout: Bool {
        #if targetEnvironment(macCatalyst)
        return true
        #else
        return UIDevice.current.userInterfaceIdiom == .pad
            || ProcessInfo.processInfo.isiOSAppOnMac
        #endif
    }

    /// True when the app is running on macOS (iOS-on-mac or Mac Catalyst), used for
    /// Mac-specific behavior that is independent of the iPad split-view layout.
    public static var isRunningOnMac: Bool {
        #if targetEnvironment(macCatalyst)
        return true
        #else
        return ProcessInfo.processInfo.isiOSAppOnMac
        #endif
    }
}

public extension DeviceLayout {
    /// Decides whether tapping an external link should open it in the custom in-app browser
    /// as an inline presentation, rather than the system browser / primary split-view pane.
    ///
    /// Centralises the `linkBrowserMode == .customBrowser` + device-class check that was
    /// duplicated (with drifting device predicates) across FeedView, CommentsView, and
    /// NavigationStore. On iPad/Mac the link opens in the primary split-view context, so
    /// the inline custom browser is only used on iPhone.
    static func prefersInlineCustomBrowser(mode: LinkBrowserMode) -> Bool {
        guard mode == .customBrowser else { return false }
        return !usesPadLayout
    }
}
