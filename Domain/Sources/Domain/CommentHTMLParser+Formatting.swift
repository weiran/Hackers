//
//  CommentHTMLParser+Formatting.swift
//  Domain
//
//  Split formatting-related parsing from CommentHTMLParser to reduce file length
//

import Foundation
import SwiftUI

extension CommentHTMLParser {
    // Processes bold, italic, and inline code tags together to preserve all formatting
    // swiftlint:disable:next cyclomatic_complexity function_body_length
    static func processFormattingTagsTogether(_ text: String) -> AttributedString {
        let preserveWhitespace = shouldPreserveWhitespace(text)
        if hasNestedFormattingTags(text) {
            return processNestedFormattingTags(text, preserveWhitespace: preserveWhitespace)
        }

        var formatSegments: [FormatSegment] = []
        let nsString = text as NSString
        let fullRange = NSRange(location: 0, length: text.utf16.count)

        let boldMatches = boldRegex.matches(in: text, range: fullRange)
        for match in boldMatches {
            let contentRange = match.range(at: 1)
            if contentRange.location != NSNotFound {
                let content = nsString.substring(with: contentRange)
                formatSegments.append(FormatSegment(range: match.range, type: .bold, content: content))
            }
        }

        let italicMatches = italicRegex.matches(in: text, range: fullRange)
        for match in italicMatches {
            let contentRange = match.range(at: 1)
            if contentRange.location != NSNotFound {
                let content = nsString.substring(with: contentRange)
                formatSegments.append(FormatSegment(range: match.range, type: .italic, content: content))
            }
        }

        let inlineCodeMatches = inlineCodeRegex.matches(in: text, range: fullRange)
        for match in inlineCodeMatches {
            let contentRange = match.range(at: 1)
            if contentRange.location != NSNotFound {
                let content = nsString.substring(with: contentRange)
                formatSegments.append(FormatSegment(range: match.range, type: .code, content: content))
            }
        }

        formatSegments.sort { $0.range.location < $1.range.location }

        guard !formatSegments.isEmpty else {
            let stripped = preserveWhitespace
                ? stripHTMLTagsPreservingWhitespace(text)
                : stripHTMLTagsAndNormalizeWhitespace(text)
            return AttributedString(stripped)
        }

        var result = AttributedString()
        var lastEnd = 0

        for segment in formatSegments {
            if segment.range.location > lastEnd {
                let beforeRange = NSRange(location: lastEnd, length: segment.range.location - lastEnd)
                let beforeText = nsString.substring(with: beforeRange)
                let cleanText = preserveWhitespace
                    ? stripHTMLTagsPreservingWhitespace(beforeText)
                    : stripHTMLTagsAndNormalizeWhitespace(beforeText)
                if !cleanText.isEmpty { result += AttributedString(cleanText) }
            }

            let cleanContent = stripHTMLTagsPreservingWhitespace(segment.content)
            if !cleanContent.isEmpty {
                var formattedString = AttributedString(cleanContent)
                switch segment.type {
                case .bold:
                    formattedString.inlinePresentationIntent = .stronglyEmphasized
                    formattedString.font = .body.bold()
                case .italic:
                    formattedString.inlinePresentationIntent = .emphasized
                    formattedString.font = .body.italic()
                case .code:
                    formattedString.font = .body.monospaced()
                }
                result += formattedString
            }

            lastEnd = NSMaxRange(segment.range)
        }

        if lastEnd < nsString.length {
            let remainingText = nsString.substring(from: lastEnd)
            let cleanText = preserveWhitespace
                ? stripHTMLTagsPreservingWhitespace(remainingText)
                : stripHTMLTagsAndNormalizeWhitespace(remainingText)
            if !cleanText.isEmpty { result += AttributedString(cleanText) }
        }

        return result
    }

    /// Checks if text contains nested formatting tags
    static func hasNestedFormattingTags(_ text: String) -> Bool {
        let boldMatches = boldRegex.matches(in: text, range: NSRange(location: 0, length: text.utf16.count))
        let italicMatches = italicRegex.matches(in: text, range: NSRange(location: 0, length: text.utf16.count))

        for boldMatch in boldMatches {
            for italicMatch in italicMatches where NSIntersectionRange(boldMatch.range, italicMatch.range).length > 0 {
                return true
            }
        }
        return false
    }

    /// Processes nested formatting tags by stripping all tags and rebuilding the content
    static func processNestedFormattingTags(_ text: String, preserveWhitespace: Bool) -> AttributedString {
        let cleanText = preserveWhitespace
            ? stripHTMLTagsPreservingWhitespace(text)
            : stripHTMLTagsAndNormalizeWhitespace(text)
        return AttributedString(cleanText)
    }

    /// Determines if whitespace should be preserved based on text structure
    static func shouldPreserveWhitespace(_ text: String) -> Bool {
        if text.contains("\n") { return false }

        let hasLeadingOrTrailingWhitespace = text.hasPrefix(" ") || text.hasSuffix(" ") ||
                                           text.hasPrefix("\t") || text.hasSuffix("\t")
        let hasParagraphTags = text.contains("<p") || text.contains("<div") || text.contains("<br")
        return hasLeadingOrTrailingWhitespace && !hasParagraphTags
    }

    /// Helper enum for formatting types
    enum FormattingType {
        case bold
        case italic
        case code
    }

    /// Struct to represent formatting segments to avoid large tuples
    struct FormatSegment {
        let range: NSRange
        let type: FormattingType
        let content: String
    }
}
