//
//  NotificationCenterExtensions.swift
//  Hackers
//
//  Created by Weiran Zhang on 01/06/2019.
//  Copyright © 2019 Glass Umbrella. All rights reserved.
//

import Foundation

extension NotificationCenter {
    func observe(name: NSNotification.Name?, object obj: Any?,
                 queue: OperationQueue?,
                 using block: @escaping (Notification) -> Void) -> NotificationToken {
        let token = addObserver(forName: name, object: obj, queue: queue, using: block)
        return NotificationToken(notificationCenter: self, token: token)
    }
}
