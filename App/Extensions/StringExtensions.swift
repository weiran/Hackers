//
//  StringExtensions.swift
//  Hackers
//
//  Created by Weiran Zhang on 17/10/2017.
//  Copyright © 2017 Weiran Zhang. All rights reserved.
//

import Foundation
import SwiftSoup

extension String {
    subscript(value: PartialRangeUpTo<Int>) -> Substring {
        return self[..<index(startIndex, offsetBy: value.upperBound)]
    }

    subscript(value: PartialRangeThrough<Int>) -> Substring {
        return self[...index(startIndex, offsetBy: value.upperBound)]
    }

    subscript(value: PartialRangeFrom<Int>) -> Substring {
        return self[index(startIndex, offsetBy: value.lowerBound)...]
    }

    func parseToAttributedString() -> NSMutableAttributedString {
		let paragraphIdentifier = "PARAGRAPH_NEED_NEW_LINES_HERE"

		// swiftlint:disable unused_optional_binding
		guard let document = try? SwiftSoup.parse(self),
			let _ = try? document.select("p").before(paragraphIdentifier),
			let text = try? document.text() else {
			return NSMutableAttributedString()
		}
		// swiftlint:enable unused_optional_binding

		return NSMutableAttributedString(string: text.replacingOccurrences(of: paragraphIdentifier + " ", with: "\n\n"))
	}
}
