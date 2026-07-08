//
//  String+HTMLUtilities.swift
//  Shared
//
//  Removes HTML markup and exposes convenience substring helpers.
//

import Foundation

public extension String {
    func strippingHTML() -> String {
        let pattern = "<[^>]+>"
        return replacingOccurrences(of: pattern, with: "", options: .regularExpression)
            .replacingOccurrences(of: "\t", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
