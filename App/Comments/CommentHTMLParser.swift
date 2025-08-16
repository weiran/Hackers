//
//  CommentHTMLParser.swift
//  Hackers
//
//  Created by Weiran Zhang on SwiftUI Migration.
//  Copyright © 2024 Glass Umbrella. All rights reserved.
//

import Foundation
import SwiftUI

/// High-performance HTML parser optimized for comment content
enum CommentHTMLParser {

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
            return try NSRegularExpression(pattern: "<[^>]+>", options: [])
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

    // MARK: - Public Interface

    /// Parses HTML text into an AttributedString with optimized performance
    /// - Parameter htmlString: The raw HTML string to parse
    /// - Returns: An AttributedString with parsed content
    static func parseHTMLText(_ htmlString: String) -> AttributedString {
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

        // Use single pass replacement for better performance
        for (entity, replacement) in htmlEntityMap {
            result = result.replacingOccurrences(of: entity, with: replacement)
        }

        return result
    }

    /// Processes HTML content to extract paragraphs and links with proper formatting
    private static func processHTMLContent(_ html: String) -> AttributedString {
        let trimmedHTML = html.trimmingCharacters(in: .whitespacesAndNewlines)

        // Check if there are paragraph tags
        let paragraphMatches = paragraphRegex.matches(
            in: trimmedHTML,
            range: NSRange(location: 0, length: trimmedHTML.utf16.count)
        )

        if !paragraphMatches.isEmpty {
            // Process content with paragraph tags - each paragraph gets separate spacing
            return processParagraphsWithSpacing(trimmedHTML, paragraphMatches: paragraphMatches)
        } else {
            // Process as single block content (no paragraph tags)
            return processLinksInText(trimmedHTML)
        }
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

    /// Processes links within a text block
    private static func processLinksInText(_ text: String) -> AttributedString {
        var result = AttributedString()
        let range = NSRange(location: 0, length: text.utf16.count)
        let matches = linkRegex.matches(in: text, range: range)
        guard !matches.isEmpty else {
            // No links found
            return AttributedString(stripHTMLTags(text))
        }

        var lastEnd = 0
        let nsString = text as NSString
        for match in matches {
            // Add text before the link
            if match.range.location > lastEnd {
                let beforeRange = NSRange(location: lastEnd, length: match.range.location - lastEnd)
                let beforeText = nsString.substring(with: beforeRange)
                let cleanText = stripHTMLTags(beforeText)
                result += AttributedString(cleanText)
            }

            // Extract and process link
            if let linkComponent = extractLinkComponent(from: match, in: nsString) {
                result += linkComponent
            }

            lastEnd = NSMaxRange(match.range)
        }

        // Add remaining text after last link
        if lastEnd < nsString.length {
            let remainingText = nsString.substring(from: lastEnd)
            let cleanText = stripHTMLTags(remainingText)
            result += AttributedString(cleanText)
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
        let cleanLinkText = stripHTMLTags(linkText)

        guard !cleanLinkText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }

        var linkAttributedString = AttributedString(cleanLinkText)

        if let url = URL(string: urlString) {
            linkAttributedString.link = url
            linkAttributedString.foregroundColor = AppTheme.default.appTintColor
            linkAttributedString.underlineStyle = .single
        }

        return linkAttributedString
    }

    /// Strips HTML tags using pre-compiled regex for better performance
    static func stripHTMLTags(_ text: String) -> String {
        let range = NSRange(location: 0, length: text.utf16.count)
        return htmlTagRegex.stringByReplacingMatches(in: text, range: range, withTemplate: "")
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
