//
//  CommentHTMLParser.swift
//  Domain
//
//  Copyright © 2025 Weiran Zhang. All rights reserved.
//

import Foundation
import SwiftUI

/// High-performance HTML parser optimized for comment content
public enum CommentHTMLParser {
    // MARK: - Static Properties

    static let htmlEntityMap: [String: String] = [
        "&amp;": "&",
        "&lt;": "<",
        "&gt;": ">",
        "&quot;": "\"",
        "&#x27;": "'",
        "&#39;": "'",
        "&nbsp;": " ",
    ]
    static let linkRegex: NSRegularExpression = {
        let pattern = #"<a\s+[^>]*href=(['"])(.*?)\1[^>]*>(.*?)</a>"#
        do {
            return try NSRegularExpression(pattern: pattern, options: [.caseInsensitive])
        } catch {
            fatalError("Invalid regex pattern: \(error)")
        }
    }()

    static let htmlTagRegex: NSRegularExpression = {
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

    static let boldRegex: NSRegularExpression = {
        let pattern = "<b\\b[^>]*>(.*?)</b>"
        do {
            return try NSRegularExpression(pattern: pattern, options: [.caseInsensitive, .dotMatchesLineSeparators])
        } catch {
            fatalError("Invalid regex pattern: \(error)")
        }
    }()

    static let italicRegex: NSRegularExpression = {
        let pattern = "<i\\b[^>]*>(.*?)</i>"
        do {
            return try NSRegularExpression(pattern: pattern, options: [.caseInsensitive, .dotMatchesLineSeparators])
        } catch {
            fatalError("Invalid regex pattern: \(error)")
        }
    }()

    static let paragraphRegex: NSRegularExpression = {
        let pattern = #"<p\b[^>]*>(.*?)</p>"#
        do {
            return try NSRegularExpression(pattern: pattern, options: [.caseInsensitive, .dotMatchesLineSeparators])
        } catch {
            fatalError("Invalid regex pattern: \(error)")
        }
    }()

    static let codeBlockRegex: NSRegularExpression = {
        let pattern = #"<pre>\s*<code>(.*?)</code>\s*</pre>"#
        do {
            return try NSRegularExpression(pattern: pattern, options: [.caseInsensitive, .dotMatchesLineSeparators])
        } catch {
            fatalError("Invalid regex pattern: \(error)")
        }
    }()

    static let inlineCodeRegex: NSRegularExpression = {
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

    // Efficiently decodes HTML entities using a single pass
    // moved to extension in CommentHTMLParser+Entities.swift

    // moved to extension in CommentHTMLParser+Blocks.swift

    // moved to extension in CommentHTMLParser+Blocks.swift

    // Processes content with paragraph tags, creating proper spacing between paragraphs
    // moved to extension in CommentHTMLParser+Blocks.swift

    // Creates proper paragraph spacing with larger line height
    // moved to extension in CommentHTMLParser+Blocks.swift

    // Processes links and formatting within a text block
    // moved to extension in CommentHTMLParser+Blocks.swift

    // Applies paragraph styling with proper line height
    // moved to extension in CommentHTMLParser+Blocks.swift

    // Extracts and creates an attributed link component
    // moved to extension in CommentHTMLParser+Blocks.swift

    // Extracts and creates an attributed link component with formatting support
    // moved to extension in CommentHTMLParser+Blocks.swift

    // moved to extension in CommentHTMLParser+Stripping.swift

    /// Processes formatting tags (bold, italic, and inline code) and returns an AttributedString
    static func processFormattingTags(_ text: String) -> AttributedString {
        let cleanedText = removeEmptyFormattingTags(text)
        return processFormattingTagsTogether(cleanedText)
    }

    /// Removes empty formatting tags that would otherwise leave extra spaces
    static func removeEmptyFormattingTags(_ text: String) -> String {
        var result = text
        result = result.replacingOccurrences(
            of: "<b\\b[^>]*>\\s*</b>",
            with: "",
            options: .regularExpression,
        )
        result = result.replacingOccurrences(
            of: "<i\\b[^>]*>\\s*</i>",
            with: "",
            options: .regularExpression,
        )
        return result
    }
}

// MARK: - String Extensions

public extension String {
    /// Strips HTML tags and decodes entities for plain text output
    func strippingHTML() -> String {
        let decodedHTML = CommentHTMLParser.decodeHTMLEntities(self)
        return CommentHTMLParser.stripHTMLTags(decodedHTML)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
