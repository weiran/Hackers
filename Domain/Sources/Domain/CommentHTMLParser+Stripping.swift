//
//  CommentHTMLParser+Stripping.swift
//  Domain
//
//  Split stripping helpers from CommentHTMLParser to reduce file length
//

import Foundation

extension CommentHTMLParser {
    /// Strips HTML tags using pre-compiled regex for better performance
    static func stripHTMLTags(_ text: String) -> String {
        let range = NSRange(location: 0, length: text.utf16.count)
        return htmlTagRegex.stringByReplacingMatches(in: text, range: range, withTemplate: "")
    }
    /// Strips HTML tags and normalizes whitespace (converts newlines to spaces)
    /// Use this for non-paragraph content where newlines should not be preserved
    static func stripHTMLTagsAndNormalizeWhitespace(_ text: String) -> String {
        let tagsRemoved = stripHTMLTags(text)
        let normalized = tagsRemoved.replacingOccurrences(
            of: "\\s+",
            with: " ",
            options: .regularExpression
        )
        return normalized
    }

    /// Strips HTML tags but preserves whitespace structure
    /// Use this when whitespace around formatting tags needs to be preserved
    static func stripHTMLTagsPreservingWhitespace(_ text: String) -> String {
        return stripHTMLTags(text)
    }
}
