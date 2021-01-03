//
//  NotificationToken.swift
//  Hackers
//
//  Created by Weiran Zhang on 01/06/2019.
//  Copyright © 2019 Weiran Zhang. All rights reserved.
//

import Foundation

final class NotificationToken: NSObject {
    let notificationCenter: NotificationCenter
    let token: Any

    init(notificationCenter: NotificationCenter = .default, token: Any) {
        self.notificationCenter = notificationCenter
        self.token = token
    }

    deinit {
        // unregister automatically when set to nil
        notificationCenter.removeObserver(token)
    }
}

extension Notification.Name {
    static let refreshRequired = NSNotification.Name(rawValue: "RefreshRequiredNotification")
}
