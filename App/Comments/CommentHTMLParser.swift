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

        if let url = URL(string: urlString) {
            linkAttributedString.link = url
            linkAttributedString.foregroundColor = AppTheme.default.appTintColor
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

        if let url = URL(string: urlString) {
            // Apply link attributes to the entire range
            let fullRange = linkAttributedString.startIndex..<linkAttributedString.endIndex
            linkAttributedString[fullRange].link = url
            linkAttributedString[fullRange].foregroundColor = AppTheme.default.appTintColor
            linkAttributedString[fullRange].underlineStyle = .single
        }

        return linkAttributedString
    }

    /// Strips HTML tags using pre-compiled regex for better performance
    static func stripHTMLTags(_ text: String) -> String {
        let range = NSRange(location: 0, length: text.utf16.count)
        return htmlTagRegex.stringByReplacingMatches(in: text, range: range, withTemplate: "")
    }
    
    /// Processes formatting tags (bold and italic) and returns an AttributedString
    private static func processFormattingTags(_ text: String) -> AttributedString {
        // Process both bold and italic tags together to preserve formatting
        return processFormattingTagsTogether(text)
    }
    
    
    /// Processes both bold and italic tags together to preserve all formatting
    private static func processFormattingTagsTogether(_ text: String) -> AttributedString {
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
        
        // Sort segments by location
        formatSegments.sort { $0.range.location < $1.range.location }
        
        // If no formatting tags found, return clean text
        guard !formatSegments.isEmpty else {
            return AttributedString(stripHTMLTagsAndNormalizeWhitespace(text))
        }
        
        var result = AttributedString()
        var lastEnd = 0
        
        for segment in formatSegments {
            // Add text before the formatting tag
            if segment.range.location > lastEnd {
                let beforeRange = NSRange(location: lastEnd, length: segment.range.location - lastEnd)
                let beforeText = nsString.substring(with: beforeRange)
                let cleanText = stripHTMLTagsAndNormalizeWhitespace(beforeText)
                if !cleanText.isEmpty {
                    result += AttributedString(cleanText)
                }
            }
            
            // Add formatted content
            let cleanContent = stripHTMLTagsAndNormalizeWhitespace(segment.content)
            if !cleanContent.isEmpty {
                var formattedString = AttributedString(cleanContent)
                
                switch segment.type {
                case .bold:
                    formattedString.inlinePresentationIntent = .stronglyEmphasized
                    formattedString.font = .body.bold()
                case .italic:
                    formattedString.inlinePresentationIntent = .emphasized
                    formattedString.font = .body.italic()
                }
                
                result += formattedString
            }
            
            lastEnd = NSMaxRange(segment.range)
        }
        
        // Add remaining text after last formatting tag
        if lastEnd < nsString.length {
            let remainingText = nsString.substring(from: lastEnd)
            let cleanText = stripHTMLTagsAndNormalizeWhitespace(remainingText)
            if !cleanText.isEmpty {
                result += AttributedString(cleanText)
            }
        }
        
        return result
    }
    
    /// Helper enum for formatting types
    private enum FormattingType {
        case bold
        case italic
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
