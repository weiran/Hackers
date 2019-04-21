//
//  SubscribableValue.swift
//  Night Mode
//
//  Created by Michael on 01/04/2018.
//  Copyright © 2018 Late Night Swift. All rights reserved.
//

import Foundation

/// Stores a value of type T, and allows objects to subscribe to
/// be notified with this value is changed.
struct SubscribableValue<T> {
	private typealias Subscription = (object: Weak<AnyObject>, handler: (T) -> Void)

	private var subscriptions: [Subscription] = []

	var value: T {
		didSet {
			for (object, handler) in subscriptions where object.value != nil {
				handler(value)
			}
		}
	}

	init(value: T) {
		self.value = value
	}

	mutating func subscribe(_ object: AnyObject, using handler: @escaping (T) -> Void) {
		subscriptions.append((Weak(value: object), handler))
		cleanupSubscriptions()
	}

	/// Removes any subscriptions where the object has been deallocated
	/// and no longer exists
	private mutating func cleanupSubscriptions() {
		subscriptions = subscriptions.filter({ entry in
			return entry.object.value != nil
		})
	}
}
