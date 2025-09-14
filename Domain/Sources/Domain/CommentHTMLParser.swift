//
//  CommentHTMLParser.swift
//  Domain
//
//  Copyright © 2025 Weiran Zhang. All rights reserved.
//

import Foundation
import SwiftUI

// swiftlint:disable type_body_length

/// High-performance HTML parser optimized for comment content
public enum CommentHTMLParser {

    // MARK: - Static Properties
    private static let htmlEntityMap: [String: String] = [
        "&amp;": "&",
        "&lt;": "<",
        "&gt;": ">",
        "&quot;": "\"",
        "&#x27;": "'",
        "&#39;": "'",
        "&nbsp;": " "
    ]
    private static let linkRegex: NSRegularExpression = {
        let pattern = #"<a\s+[^>]*href=(['"])(.*?)\1[^>]*>(.*?)</a>"#
        do {
            return try NSRegularExpression(pattern: pattern, options: [.caseInsensitive])
        } catch {
            fatalError("Invalid regex pattern: \(error)")
        }
    }()

    private static let htmlTagRegex: NSRegularExpression = {
        do {
            // More specific regex that matches actual HTML tags:
            // - Opening tags: <tagname> or <tagname attributes>
            // - Closing tags: </tagname>
            // - Self-closing tags: <tagname/> or <tagname attributes/>
            return try NSRegularExpression(pattern: "</?[a-zA-Z][a-zA-Z0-9]*[^<>]*>", options: [])
        } catch {
            fatalError("Invalid regex pattern: \(error)")
        }
    }()

    private static let boldRegex: NSRegularExpression = {
        let pattern = "<b\\b[^>]*>(.*?)</b>"
        do {
            return try NSRegularExpression(pattern: pattern, options: [.caseInsensitive, .dotMatchesLineSeparators])
        } catch {
            fatalError("Invalid regex pattern: \(error)")
        }
    }()

    private static let italicRegex: NSRegularExpression = {
        let pattern = "<i\\b[^>]*>(.*?)</i>"
        do {
            return try NSRegularExpression(pattern: pattern, options: [.caseInsensitive, .dotMatchesLineSeparators])
        } catch {
            fatalError("Invalid regex pattern: \(error)")
        }
    }()
    private static let paragraphRegex: NSRegularExpression = {
        let pattern = #"<p\b[^>]*>(.*?)</p>"#
        do {
            return try NSRegularExpression(pattern: pattern, options: [.caseInsensitive, .dotMatchesLineSeparators])
        } catch {
            fatalError("Invalid regex pattern: \(error)")
        }
    }()

    private static let codeBlockRegex: NSRegularExpression = {
        let pattern = #"<pre>\s*<code>(.*?)</code>\s*</pre>"#
        do {
            return try NSRegularExpression(pattern: pattern, options: [.caseInsensitive, .dotMatchesLineSeparators])
        } catch {
            fatalError("Invalid regex pattern: \(error)")
        }
    }()

    private static let inlineCodeRegex: NSRegularExpression = {
        let pattern = #"<code\b[^>]*>(.*?)</code>"#
        do {
            return try NSRegularExpression(pattern: pattern, options: [.caseInsensitive, .dotMatchesLineSeparators])
        } catch {
            fatalError("Invalid regex pattern: \(error)")
        }
    }()

    // MARK: - Public Interface

    /// Parses HTML text into an AttributedString with optimized performance
    /// - Parameter htmlString: The raw HTML string to parse
    /// - Returns: An AttributedString with parsed content
    public static func parseHTMLText(_ htmlString: String) -> AttributedString {
        guard !htmlString.isEmpty else {
            return AttributedString("")
        }

        let decodedHTML = decodeHTMLEntities(htmlString)
        return processHTMLContent(decodedHTML)
    }

    // MARK: - Private Implementation
    /// Efficiently decodes HTML entities using a single pass
    static func decodeHTMLEntities(_ html: String) -> String {
        var result = html

        // Handle &nbsp; specially to avoid creating double spaces
        result = result.replacingOccurrences(of: " &nbsp;", with: " ")
        result = result.replacingOccurrences(of: "&nbsp; ", with: " ")
        result = result.replacingOccurrences(of: "&nbsp;", with: " ")

        // Decode entities in deterministic order; decode &amp; last to avoid premature short-circuiting
        let orderedEntities = ["&lt;", "&gt;", "&quot;", "&#x27;", "&#39;", "&amp;"]
        for entity in orderedEntities {
            guard let replacement = htmlEntityMap[entity] else { continue }
            result = result.replacingOccurrences(of: entity, with: replacement)
        }

        return result
    }

    /// Processes HTML content to extract paragraphs and links with proper formatting
    private static func processHTMLContent(_ html: String) -> AttributedString {
        // Don't trim to preserve whitespace around formatting tags
        let workingHTML = html

        // Check if there are code blocks that need processing
        let codeBlockRange = NSRange(location: 0, length: workingHTML.utf16.count)
        let codeBlockMatches = codeBlockRegex.matches(in: workingHTML, range: codeBlockRange)

        if !codeBlockMatches.isEmpty {
            // Process code blocks and return the result
            return processCodeBlocks(workingHTML)
        }

        // Check if there are paragraph tags
        let paragraphMatches = paragraphRegex.matches(
            in: workingHTML,
            range: NSRange(location: 0, length: workingHTML.utf16.count)
        )

        if !paragraphMatches.isEmpty {
            // Process content with paragraph tags - each paragraph gets separate spacing
            return processParagraphsWithSpacing(workingHTML, paragraphMatches: paragraphMatches)
        } else {
            // Process as single block content (no paragraph tags)
            let result = processLinksInText(workingHTML)
            // Only trim if the result is empty or only whitespace
            if String(result.characters).trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return AttributedString("")
            }
            return result
        }
    }

    /// Processes code blocks (pre/code tags) and returns an AttributedString with the code blocks already formatted
    private static func processCodeBlocks(_ html: String) -> AttributedString {
        var result = AttributedString()
        let nsString = html as NSString
        let range = NSRange(location: 0, length: html.utf16.count)

        // Find all code blocks
        let codeBlockMatches = codeBlockRegex.matches(in: html, range: range)

        guard !codeBlockMatches.isEmpty else {
            // No code blocks, process normally
            return processLinksInText(html)
        }

        var lastEnd = 0

        for (index, match) in codeBlockMatches.enumerated() {
            // Add and process text before the code block
            if match.range.location > lastEnd {
                let beforeRange = NSRange(location: lastEnd, length: match.range.location - lastEnd)
                let beforeText = nsString.substring(with: beforeRange)
                // Process links and formatting in text before code block
                let processedText = processLinksInText(beforeText)
                if !String(processedText.characters).trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    result += processedText
                }
            }

            // Extract and format the code block content
            let codeContentRange = match.range(at: 1)
            if codeContentRange.location != NSNotFound {
                let codeContent = nsString.substring(with: codeContentRange)
                // Decode HTML entities in the code content
                let decodedCode = decodeHTMLEntities(codeContent)

                // Create formatted code block
                var codeAttributedString = AttributedString(decodedCode)

                // Apply monospace font
                let fullRange = codeAttributedString.startIndex..<codeAttributedString.endIndex
                codeAttributedString[fullRange].font = .body.monospaced()

                // Add paragraph spacing before code block (like <p> tags)
                // Only add spacing if there's content before this code block
                if !result.characters.isEmpty {
                    result += createParagraphSpacing()
                }

                result += codeAttributedString

                // Add single line spacing after code block (not double)
                result += AttributedString("\n")
            }

            lastEnd = NSMaxRange(match.range)
        }

        // Add and process remaining text after last code block
        if lastEnd < nsString.length {
            let remainingText = nsString.substring(from: lastEnd)
            let processedText = processLinksInText(remainingText)
            // Always add remaining text, even if it starts with whitespace
            result += processedText
        }

        return result
    }

    /// Processes content with paragraph tags, creating proper spacing between paragraphs
    private static func processParagraphsWithSpacing(
        _ html: String,
        paragraphMatches: [NSTextCheckingResult]
    ) -> AttributedString {
        var result = AttributedString()
        let nsString = html as NSString
        var lastEnd = 0

        for (index, match) in paragraphMatches.enumerated() {
            // Add text before the paragraph (if any)
            if match.range.location > lastEnd {
                let beforeRange = NSRange(location: lastEnd, length: match.range.location - lastEnd)
                let beforeText = nsString.substring(with: beforeRange)
                let trimmedBeforeText = beforeText.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmedBeforeText.isEmpty {
                    if !result.characters.isEmpty {
                        // Add double newline for paragraph spacing
                        result += createParagraphSpacing()
                    }
                    // Process links in the text before the paragraph
                    let beforeAttributedText = processLinksInText(trimmedBeforeText)
                    result += beforeAttributedText
                }
            }

            // Process paragraph content
            let paragraphContentRange = match.range(at: 1)
            if paragraphContentRange.location != NSNotFound {
                let paragraphContent = nsString.substring(with: paragraphContentRange)
                var paragraphAttributedString = processLinksInText(paragraphContent)

                // Apply paragraph styling
                paragraphAttributedString = applyParagraphStyling(paragraphAttributedString)

                // Add spacing between paragraphs (except for the first one)
                if index > 0 || !result.characters.isEmpty {
                    result += createParagraphSpacing()
                }

                result += paragraphAttributedString
            }

            lastEnd = NSMaxRange(match.range)
        }

        // Add remaining text after last paragraph (if any)
        if lastEnd < nsString.length {
            let remainingText = nsString.substring(from: lastEnd)
            let trimmedRemainingText = remainingText.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmedRemainingText.isEmpty {
                if !result.characters.isEmpty {
                    result += createParagraphSpacing()
                }
                // Process links in the remaining text
                let remainingAttributedText = processLinksInText(trimmedRemainingText)
                result += remainingAttributedText
            }
        }

        return result
    }

    /// Creates proper paragraph spacing with larger line height
    private static func createParagraphSpacing() -> AttributedString {
        var spacing = AttributedString("\n\n")

        // Apply larger line height to the spacing to create more visual separation
        let spacingStyle = NSMutableParagraphStyle()
        spacingStyle.lineHeightMultiple = 1.0 // Normal line height but double newlines create the space
        let fullRange = spacing.startIndex..<spacing.endIndex
        spacing[fullRange].paragraphStyle = spacingStyle

        return spacing
    }

    /// Processes links and formatting within a text block
    private static func processLinksInText(_ text: String) -> AttributedString {
        var result = AttributedString()
        let range = NSRange(location: 0, length: text.utf16.count)
        let matches = linkRegex.matches(in: text, range: range)
        guard !matches.isEmpty else {
            // No links found - process formatting tags and return
            return processFormattingTags(text)
        }

        var lastEnd = 0
        let nsString = text as NSString
        for match in matches {
            // Add text before the link (with formatting processing)
            if match.range.location > lastEnd {
                let beforeRange = NSRange(location: lastEnd, length: match.range.location - lastEnd)
                let beforeText = nsString.substring(with: beforeRange)
                let formattedBeforeText = processFormattingTags(beforeText)
                result += formattedBeforeText
            }

            // Extract and process link (the link text itself may contain formatting)
            if let linkComponent = extractLinkComponentWithFormatting(from: match, in: nsString) {
                result += linkComponent
            }

            lastEnd = NSMaxRange(match.range)
        }

        // Add remaining text after last link (with formatting processing)
        if lastEnd < nsString.length {
            let remainingText = nsString.substring(from: lastEnd)
            let formattedRemainingText = processFormattingTags(remainingText)
            result += formattedRemainingText
        }

        return result
    }

    /// Applies paragraph styling with proper line height
    private static func applyParagraphStyling(_ attributedString: AttributedString) -> AttributedString {
        var styled = attributedString

        // Create paragraph style with line height and larger paragraph spacing
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1.5
        paragraphStyle.paragraphSpacing = 20.0 // Larger spacing after paragraph for visual separation

        // Apply the paragraph style to the entire attributed string
        let fullRange = styled.startIndex..<styled.endIndex
        styled[fullRange].paragraphStyle = paragraphStyle

        return styled
    }

    /// Extracts and creates an attributed link component
    private static func extractLinkComponent(from match: NSTextCheckingResult,
                                             in nsString: NSString) -> AttributedString? {
        guard match.numberOfRanges >= 4 else { return nil }

        let urlRange = match.range(at: 2)
        let textRange = match.range(at: 3)

        guard urlRange.location != NSNotFound,
              textRange.location != NSNotFound else { return nil }

        let urlString = nsString.substring(with: urlRange)
        let linkText = nsString.substring(with: textRange)
        let cleanLinkText = stripHTMLTagsAndNormalizeWhitespace(linkText)

        guard !cleanLinkText.isEmpty else { return nil }

        var linkAttributedString = AttributedString(cleanLinkText)

        var resolvedURL = URL(string: urlString)
        if resolvedURL?.scheme == nil, let base = URL(string: "https://news.ycombinator.com") {
            resolvedURL = URL(string: urlString, relativeTo: base)?.absoluteURL
        }
        if let url = resolvedURL {
            linkAttributedString.link = url
            // Use Color directly instead of AppTheme
            linkAttributedString.foregroundColor = Color("appTintColor")
            linkAttributedString.underlineStyle = .single
        }

        return linkAttributedString
    }

    /// Extracts and creates an attributed link component with formatting support
    private static func extractLinkComponentWithFormatting(from match: NSTextCheckingResult,
                                                           in nsString: NSString) -> AttributedString? {
        guard match.numberOfRanges >= 4 else { return nil }

        let urlRange = match.range(at: 2)
        let textRange = match.range(at: 3)

        guard urlRange.location != NSNotFound,
              textRange.location != NSNotFound else { return nil }

        let urlString = nsString.substring(with: urlRange)
        let linkText = nsString.substring(with: textRange)

        guard !linkText.isEmpty else { return nil }

        // Process formatting within the link text
        var linkAttributedString = processFormattingTags(linkText)

        // Resolve relative URLs
        var resolvedURL = URL(string: urlString)
        if resolvedURL?.scheme == nil, let base = URL(string: "https://news.ycombinator.com") {
            resolvedURL = URL(string: urlString, relativeTo: base)?.absoluteURL
        }
        if let url = resolvedURL {
            // Apply link attributes to the entire range
            let fullRange = linkAttributedString.startIndex..<linkAttributedString.endIndex
            linkAttributedString[fullRange].link = url
            // Use Color directly instead of AppTheme
            linkAttributedString[fullRange].foregroundColor = Color("appTintColor")
            linkAttributedString[fullRange].underlineStyle = .single
        }

        return linkAttributedString
    }

    /// Strips HTML tags using pre-compiled regex for better performance
    static func stripHTMLTags(_ text: String) -> String {
        let range = NSRange(location: 0, length: text.utf16.count)
        return htmlTagRegex.stringByReplacingMatches(in: text, range: range, withTemplate: "")
    }

    /// Processes formatting tags (bold, italic, and inline code) and returns an AttributedString
    private static func processFormattingTags(_ text: String) -> AttributedString {
        // First remove empty formatting tags to prevent extra spaces
        let cleanedText = removeEmptyFormattingTags(text)
        // Process bold, italic, and inline code tags together to preserve formatting
        return processFormattingTagsTogether(cleanedText)
    }

    /// Removes empty formatting tags that would otherwise leave extra spaces
    private static func removeEmptyFormattingTags(_ text: String) -> String {
        var result = text

        // Remove empty bold tags
        result = result.replacingOccurrences(
            of: "<b\\b[^>]*>\\s*</b>",
            with: "",
            options: .regularExpression
        )

        // Remove empty italic tags
        result = result.replacingOccurrences(
            of: "<i\\b[^>]*>\\s*</i>",
            with: "",
            options: .regularExpression
        )

        return result
    }

    /// Processes bold, italic, and inline code tags together to preserve all formatting
    private static func processFormattingTagsTogether(_ text: String) -> AttributedString {
        // For nested formatting, we need to strip all HTML tags first, then process the clean text
        // This prevents duplicate content from overlapping tags

        let preserveWhitespace = shouldPreserveWhitespace(text)

        // First, try to handle nested tags by processing them recursively
        if hasNestedFormattingTags(text) {
            return processNestedFormattingTags(text, preserveWhitespace: preserveWhitespace)
        }

        // Find all formatting tags and their positions
        var formatSegments: [(range: NSRange, type: FormattingType, content: String)] = []

        let nsString = text as NSString
        let fullRange = NSRange(location: 0, length: text.utf16.count)

        // Find bold tags
        let boldMatches = boldRegex.matches(in: text, range: fullRange)
        for match in boldMatches {
            let contentRange = match.range(at: 1)
            if contentRange.location != NSNotFound {
                let content = nsString.substring(with: contentRange)
                formatSegments.append((range: match.range, type: .bold, content: content))
            }
        }

        // Find italic tags
        let italicMatches = italicRegex.matches(in: text, range: fullRange)
        for match in italicMatches {
            let contentRange = match.range(at: 1)
            if contentRange.location != NSNotFound {
                let content = nsString.substring(with: contentRange)
                formatSegments.append((range: match.range, type: .italic, content: content))
            }
        }

        // Find inline code tags (not within pre tags)
        let inlineCodeMatches = inlineCodeRegex.matches(in: text, range: fullRange)
        for match in inlineCodeMatches {
            let contentRange = match.range(at: 1)
            if contentRange.location != NSNotFound {
                let content = nsString.substring(with: contentRange)
                formatSegments.append((range: match.range, type: .code, content: content))
            }
        }

        // Sort segments by location
        formatSegments.sort { $0.range.location < $1.range.location }

        // If no formatting tags found, check if we should preserve whitespace
        guard !formatSegments.isEmpty else {
            let stripped = preserveWhitespace
                ? stripHTMLTagsPreservingWhitespace(text)
                : stripHTMLTagsAndNormalizeWhitespace(text)
            return AttributedString(stripped)
        }

        var result = AttributedString()
        var lastEnd = 0

        for segment in formatSegments {
            // Add text before the formatting tag
            if segment.range.location > lastEnd {
                let beforeRange = NSRange(location: lastEnd, length: segment.range.location - lastEnd)
                let beforeText = nsString.substring(with: beforeRange)
                let cleanText = preserveWhitespace
                    ? stripHTMLTagsPreservingWhitespace(beforeText)
                    : stripHTMLTagsAndNormalizeWhitespace(beforeText)
                if !cleanText.isEmpty {
                    result += AttributedString(cleanText)
                }
            }

            // Add formatted content - always preserve whitespace within formatting tags
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

        // Add remaining text after last formatting tag
        if lastEnd < nsString.length {
            let remainingText = nsString.substring(from: lastEnd)
            let cleanText = preserveWhitespace
                ? stripHTMLTagsPreservingWhitespace(remainingText)
                : stripHTMLTagsAndNormalizeWhitespace(remainingText)
            if !cleanText.isEmpty {
                result += AttributedString(cleanText)
            }
        }

        return result
    }

    /// Checks if text contains nested formatting tags
    private static func hasNestedFormattingTags(_ text: String) -> Bool {
        // Check if bold tags contain italic tags or vice versa
        let boldMatches = boldRegex.matches(in: text, range: NSRange(location: 0, length: text.utf16.count))
        let italicMatches = italicRegex.matches(in: text, range: NSRange(location: 0, length: text.utf16.count))

        // Check for overlapping ranges
        for boldMatch in boldMatches {
            for italicMatch in italicMatches {
                if NSIntersectionRange(boldMatch.range, italicMatch.range).length > 0 {
                    return true
                }
            }
        }

        return false
    }

    /// Processes nested formatting tags by stripping all tags and rebuilding the content
    private static func processNestedFormattingTags(_ text: String, preserveWhitespace: Bool) -> AttributedString {
        // For nested tags, strip all HTML and just preserve the text content
        let cleanText = preserveWhitespace
            ? stripHTMLTagsPreservingWhitespace(text)
            : stripHTMLTagsAndNormalizeWhitespace(text)
        return AttributedString(cleanText)
    }

    /// Determines if whitespace should be preserved based on text structure
    private static func shouldPreserveWhitespace(_ text: String) -> Bool {
        // Only preserve whitespace for simple cases like "  <b>text</b>  " where
        // the entire input is just formatting tags with significant whitespace around them

        // Don't preserve if there are newlines (should be normalized)
        if text.contains("\n") {
            return false
        }

        // Preserve whitespace if:
        // 1. Text starts or ends with whitespace (but not newlines) AND
        // 2. Text contains only simple formatting tags (b, i, a) AND
        // 3. Text doesn't contain paragraph tags
        let hasLeadingOrTrailingWhitespace = text.hasPrefix(" ") || text.hasSuffix(" ") ||
                                           text.hasPrefix("\t") || text.hasSuffix("\t")

        let hasParagraphTags = text.contains("<p") || text.contains("<div") || text.contains("<br")

        return hasLeadingOrTrailingWhitespace && !hasParagraphTags
    }

    /// Helper enum for formatting types
    private enum FormattingType {
        case bold
        case italic
        case code
    }

    /// Strips HTML tags and normalizes whitespace (converts newlines to spaces)
    /// Use this for non-paragraph content where newlines should not be preserved
    private static func stripHTMLTagsAndNormalizeWhitespace(_ text: String) -> String {
        let tagsRemoved = stripHTMLTags(text)
        // Replace any sequence of whitespace characters (including newlines) with single spaces
        let normalized = tagsRemoved.replacingOccurrences(
            of: "\\s+",
            with: " ",
            options: .regularExpression
        )
        return normalized
    }

    /// Strips HTML tags but preserves whitespace structure
    /// Use this when whitespace around formatting tags needs to be preserved
    private static func stripHTMLTagsPreservingWhitespace(_ text: String) -> String {
        return stripHTMLTags(text)
    }

}

// MARK: - String Extensions
extension String {
    /// Strips HTML tags and decodes entities for plain text output
    func strippingHTML() -> String {
        let decodedHTML = CommentHTMLParser.decodeHTMLEntities(self)
        return CommentHTMLParser.stripHTMLTags(decodedHTML)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
