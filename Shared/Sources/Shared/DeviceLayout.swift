//
//  DeviceLayout.swift
//  Shared
//
//  Centralises device-class detection so adaptive layout and Mac-specific behavior
//  don't get re-implemented (and drift) across the app, feature views, and services.
//

import UIKit

@MainActor
public enum DeviceLayout {
    /// True when the window currently has a regular horizontal size class, so the root
    /// split view shows feed and detail side by side (iPad, iPhone Duo inner display, Mac).
    ///
    /// Layout decisions in views should read `horizontalSizeClass` directly; this mirror
    /// exists for UIKit code that has no SwiftUI environment. The root view keeps it in sync.
    public static var usesRegularWidthLayout: Bool {
        isRunningOnMac || hasRegularWidthWindow
    }

    /// Updated by the root view from its horizontal size class.
    public static var hasRegularWidthWindow = false

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
