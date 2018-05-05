//
//  ArrayExtensions.swift
//  Night Mode
//
//  Created by Michael on 01/04/2018.
//  Copyright © 2018 Late Night Swift. All rights reserved.
//

import Foundation

extension Array {
	/// Move the last element of the array to the beginning
	///  - Returns: The element that was moved
	mutating func rotate() -> Element? {
		guard let lastElement = popLast() else {
			return nil
		}
		insert(lastElement, at: 0)
		return lastElement
	}
}
