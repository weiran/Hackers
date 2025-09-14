//
//  CommentHTMLParser+Entities.swift
//  Domain
//
//  Split entity decoding from CommentHTMLParser to reduce file length
//

import Foundation

extension CommentHTMLParser {
    /// Efficiently decodes HTML entities using a single pass
    static func decodeHTMLEntities(_ html: String) -> String {
        var result = html
        result = result.replacingOccurrences(of: " &nbsp;", with: " ")
        result = result.replacingOccurrences(of: "&nbsp; ", with: " ")
        result = result.replacingOccurrences(of: "&nbsp;", with: " ")

        let orderedEntities = ["&lt;", "&gt;", "&quot;", "&#x27;", "&#39;", "&amp;"]
        for entity in orderedEntities {
            guard let replacement = htmlEntityMap[entity] else { continue }
            result = result.replacingOccurrences(of: entity, with: replacement)
        }
        return result
    }
}
