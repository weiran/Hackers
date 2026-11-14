//
//  CommentHTMLParser+Stripping.swift
//  Domain
//
//  Split stripping helpers from CommentHTMLParser to reduce file length
//

import Foundation

extension CommentHTMLParser {
    /// Converts Hacker News comment HTML to plain text for copy/share surfaces.
    public static func plainText(fromHTML html: String) -> String {
        // Strip structural tags before decoding so escaped markup remains text.
        return decodeHTMLEntities(stripHTMLTags(html))
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Strips HTML tags using pre-compiled regex for better performance
    static func stripHTMLTags(_ text: String) -> String {
        let range = NSRange(location: 0, length: text.utf16.count)
        return htmlTagRegex.stringByReplacingMatches(in: text, range: range, withTemplate: "")
    }

    /// Removes raw tags, decodes entities once, and optionally normalizes the
    /// resulting display whitespace. Keeping this order prevents decoded
    /// entities from being parsed as markup or reintroducing newlines.
    static func cleanDisplayText(_ text: String, preservingWhitespace: Bool) -> String {
        let decoded = decodeHTMLEntities(stripHTMLTags(text))
        guard !preservingWhitespace else { return decoded }
        return decoded.replacingOccurrences(
            of: "\\s+",
            with: " ",
            options: .regularExpression,
        )
    }

    /// Trims only outer display whitespace while preserving all attributes on
    /// the remaining attributed characters.
    static func trimDisplayWhitespace(_ value: AttributedString) -> AttributedString {
        var start = value.startIndex
        var end = value.endIndex
        while start < end, value.characters[start].isWhitespace {
            start = value.characters.index(after: start)
        }
        while start < end {
            let previous = value.characters.index(before: end)
            guard value.characters[previous].isWhitespace else { break }
            end = previous
        }
        return AttributedString(value[start ..< end])
    }

    /// Strips HTML tags and normalizes whitespace (converts newlines to spaces)
    /// Use this for non-paragraph content where newlines should not be preserved
    static func stripHTMLTagsAndNormalizeWhitespace(_ text: String) -> String {
        cleanDisplayText(text, preservingWhitespace: false)
    }

    /// Strips HTML tags but preserves whitespace structure
    /// Use this when whitespace around formatting tags needs to be preserved
    static func stripHTMLTagsPreservingWhitespace(_ text: String) -> String {
        stripHTMLTags(text)
    }
}
