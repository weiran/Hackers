//
//  NotificationName+AppEvents.swift
//  Shared
//
//  Defines app-specific notification names.
//

import Foundation

public extension Notification.Name {
    static let refreshRequired = NSNotification.Name(rawValue: "RefreshRequiredNotification")
    static let userDidLogout = NSNotification.Name(rawValue: "UserDidLogoutNotification")
}
