//
//  CommentHTMLParser+Formatting.swift
//  Domain
//
//  Split formatting-related parsing from CommentHTMLParser to reduce file length
//

import Foundation
import SwiftUI

extension CommentHTMLParser {
    // MARK: - Types

    private enum FormattingType {
        case bold
        case italic
        case code
    }

    private struct FormatSegment {
        let range: NSRange
        let type: FormattingType
        let content: String
    }

    // Processes bold, italic, and inline code tags together to preserve all formatting
    static func processFormattingTagsTogether(_ text: String) -> AttributedString {
        let preserveWhitespace = shouldPreserveWhitespace(text)
        if hasNestedFormattingTags(text) {
            return processNestedFormattingTags(text, preserveWhitespace: preserveWhitespace)
        }

        let nsString = text as NSString
        var segments = buildFormatSegments(text)
        segments.sort { $0.range.location < $1.range.location }

        guard !segments.isEmpty else {
            let stripped = preserveWhitespace
                ? stripHTMLTagsPreservingWhitespace(text)
                : stripHTMLTagsAndNormalizeWhitespace(text)
            return AttributedString(stripped)
        }

        var result = AttributedString()
        var lastEnd = 0
        for segment in segments {
            appendTextBeforeSegment(
                nsString: nsString,
                segment: segment,
                lastEnd: lastEnd,
                preserveWhitespace: preserveWhitespace,
                into: &result,
            )
            appendFormattedSegment(segment, into: &result)
            lastEnd = NSMaxRange(segment.range)
        }
        appendRemainingText(
            nsString: nsString,
            lastEnd: lastEnd,
            preserveWhitespace: preserveWhitespace,
            into: &result,
        )
        return result
    }

    // MARK: - Helpers to reduce complexity/length

    private static func buildFormatSegments(_ text: String) -> [FormatSegment] {
        var segments: [FormatSegment] = []
        let nsString = text as NSString
        let fullRange = NSRange(location: 0, length: text.utf16.count)

        for match in boldRegex.matches(in: text, range: fullRange) {
            let contentRange = match.range(at: 1)
            if contentRange.location != NSNotFound {
                let content = nsString.substring(with: contentRange)
                segments.append(FormatSegment(range: match.range, type: .bold, content: content))
            }
        }
        for match in italicRegex.matches(in: text, range: fullRange) {
            let contentRange = match.range(at: 1)
            if contentRange.location != NSNotFound {
                let content = nsString.substring(with: contentRange)
                segments.append(FormatSegment(range: match.range, type: .italic, content: content))
            }
        }
        for match in inlineCodeRegex.matches(in: text, range: fullRange) {
            let contentRange = match.range(at: 1)
            if contentRange.location != NSNotFound {
                let content = nsString.substring(with: contentRange)
                segments.append(FormatSegment(range: match.range, type: .code, content: content))
            }
        }
        return segments
    }

    private static func appendTextBeforeSegment(
        nsString: NSString,
        segment: FormatSegment,
        lastEnd: Int,
        preserveWhitespace: Bool,
        into result: inout AttributedString,
    ) {
        if segment.range.location > lastEnd {
            let beforeRange = NSRange(location: lastEnd, length: segment.range.location - lastEnd)
            let beforeText = nsString.substring(with: beforeRange)
            let cleanText = preserveWhitespace
                ? stripHTMLTagsPreservingWhitespace(beforeText)
                : stripHTMLTagsAndNormalizeWhitespace(beforeText)
            if !cleanText.isEmpty { result += AttributedString(cleanText) }
        }
    }

    private static func appendFormattedSegment(_ segment: FormatSegment, into result: inout AttributedString) {
        let cleanContent = stripHTMLTagsPreservingWhitespace(segment.content)
        guard !cleanContent.isEmpty else { return }
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

    private static func appendRemainingText(
        nsString: NSString,
        lastEnd: Int,
        preserveWhitespace: Bool,
        into result: inout AttributedString,
    ) {
        if lastEnd < nsString.length {
            let remainingText = nsString.substring(from: lastEnd)
            let cleanText = preserveWhitespace
                ? stripHTMLTagsPreservingWhitespace(remainingText)
                : stripHTMLTagsAndNormalizeWhitespace(remainingText)
            if !cleanText.isEmpty { result += AttributedString(cleanText) }
        }
    }

    // Determine if formatting tags overlap
    private static func hasNestedFormattingTags(_ text: String) -> Bool {
        let boldMatches = boldRegex.matches(in: text, range: NSRange(location: 0, length: text.utf16.count))
        let italicMatches = italicRegex.matches(in: text, range: NSRange(location: 0, length: text.utf16.count))
        for boldMatch in boldMatches {
            for italicMatch in italicMatches where NSIntersectionRange(boldMatch.range, italicMatch.range).length > 0 {
                return true
            }
        }
        return false
    }

    // For nested tags, strip all HTML and rebuild clean text
    private static func processNestedFormattingTags(_ text: String, preserveWhitespace: Bool) -> AttributedString {
        let cleanText = preserveWhitespace
            ? stripHTMLTagsPreservingWhitespace(text)
            : stripHTMLTagsAndNormalizeWhitespace(text)
        return AttributedString(cleanText)
    }

    // Heuristic to decide when to preserve surrounding whitespace
    private static func shouldPreserveWhitespace(_ text: String) -> Bool {
        if text.contains("\n") { return false }
        let hasLeadingOrTrailingWhitespace = text.hasPrefix(" ") || text.hasSuffix(" ") ||
            text.hasPrefix("\t") || text.hasSuffix("\t")
        let hasParagraphTags = text.contains("<p") || text.contains("<div") || text.contains("<br")
        return hasLeadingOrTrailingWhitespace && !hasParagraphTags
    }
}
