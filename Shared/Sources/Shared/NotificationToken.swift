//
//  NotificationToken.swift
//  Shared
//
//  Automatic notification observer cleanup
//

import Foundation

public final class NotificationToken: NSObject {
    let notificationCenter: NotificationCenter
    let token: Any

    public init(notificationCenter: NotificationCenter = .default, token: Any) {
        self.notificationCenter = notificationCenter
        self.token = token
    }

    deinit {
        // unregister automatically when set to nil
        notificationCenter.removeObserver(token)
    }
}