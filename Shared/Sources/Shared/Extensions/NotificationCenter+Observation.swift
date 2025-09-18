//
//  NotificationCenter+Observation.swift
//  Shared
//
//  Simplifies observing notifications with automatic cleanup tokens.
//

import Foundation

public extension NotificationCenter {
    func observe(
        name: NSNotification.Name?,
        object obj: Any?,
        queue: OperationQueue?,
        using block: @escaping (Notification) -> Void,
    ) -> NotificationObservationToken {
        let token = addObserver(forName: name, object: obj, queue: queue, using: block)
        return NotificationObservationToken(notificationCenter: self, token: token)
    }
}
