//
//  CommentHTMLParser+Blocks.swift
//  Domain
//
//  Split block/paragraph/link processing from CommentHTMLParser to reduce file length
//

import Foundation
import SwiftUI

extension CommentHTMLParser {
    /// Processes HTML content to extract paragraphs and links with proper formatting
    static func processHTMLContent(_ html: String) -> AttributedString {
        let workingHTML = html
        let codeBlockRange = NSRange(location: 0, length: workingHTML.utf16.count)
        let codeBlockMatches = codeBlockRegex.matches(in: workingHTML, range: codeBlockRange)
        if !codeBlockMatches.isEmpty { return processCodeBlocks(workingHTML) }

        let paragraphMatches = paragraphRegex.matches(
            in: workingHTML,
            range: NSRange(location: 0, length: workingHTML.utf16.count),
        )
        if !paragraphMatches.isEmpty {
            return processParagraphsWithSpacing(workingHTML, paragraphMatches: paragraphMatches)
        } else {
            let result = processLinksInText(workingHTML)
            if String(result.characters).trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return AttributedString("")
            }
            return result
        }
    }

    /// Processes code blocks (pre/code tags) and returns an AttributedString with the code blocks already formatted
    static func processCodeBlocks(_ html: String) -> AttributedString {
        var result = AttributedString()
        let nsString = html as NSString
        let range = NSRange(location: 0, length: html.utf16.count)

        let codeBlockMatches = codeBlockRegex.matches(in: html, range: range)
        guard !codeBlockMatches.isEmpty else { return processLinksInText(html) }

        var lastEnd = 0
        for match in codeBlockMatches {
            if match.range.location > lastEnd {
                let beforeRange = NSRange(location: lastEnd, length: match.range.location - lastEnd)
                let beforeText = nsString.substring(with: beforeRange)
                let processedText = processLinksInText(beforeText)
                if !String(processedText.characters).trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    result += processedText
                }
            }

            let codeContentRange = match.range(at: 1)
            if codeContentRange.location != NSNotFound {
                let codeContent = nsString.substring(with: codeContentRange)
                let decodedCode = decodeHTMLEntities(codeContent)

                var codeAttributedString = AttributedString(decodedCode)
                let fullRange = codeAttributedString.startIndex ..< codeAttributedString.endIndex
                codeAttributedString[fullRange].inlinePresentationIntent = .code

                if !result.characters.isEmpty { result += createParagraphSpacing() }
                result += codeAttributedString
                result += AttributedString("\n")
            }

            lastEnd = NSMaxRange(match.range)
        }

        if lastEnd < nsString.length {
            let remainingText = nsString.substring(from: lastEnd)
            let processedText = processLinksInText(remainingText)
            result += processedText
        }

        return result
    }

    /// Processes content with paragraph tags, creating proper spacing between paragraphs
    static func processParagraphsWithSpacing(
        _ html: String,
        paragraphMatches: [NSTextCheckingResult],
    ) -> AttributedString {
        var result = AttributedString()
        let nsString = html as NSString
        var lastEnd = 0

        for match in paragraphMatches {
            if match.range.location > lastEnd {
                let beforeRange = NSRange(location: lastEnd, length: match.range.location - lastEnd)
                let beforeText = nsString.substring(with: beforeRange)
                let trimmedBeforeText = beforeText.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmedBeforeText.isEmpty {
                    if !result.characters.isEmpty { result += createParagraphSpacing() }
                    let beforeAttributedText = processLinksInText(trimmedBeforeText)
                    result += beforeAttributedText
                }
            }

            let paragraphContentRange = match.range(at: 1)
            if paragraphContentRange.location != NSNotFound {
                let paragraphContent = nsString.substring(with: paragraphContentRange)
                let processedParagraph = processLinksInText(paragraphContent)
                if !result.characters.isEmpty { result += createParagraphSpacing() }
                result += processedParagraph
            }

            lastEnd = NSMaxRange(match.range)
        }

        if lastEnd < nsString.length {
            let remainingText = nsString.substring(from: lastEnd)
            let trimmed = remainingText.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                if !result.characters.isEmpty { result += createParagraphSpacing() }
                result += processLinksInText(trimmed)
            }
        }

        return applyParagraphStyling(result)
    }

    /// Creates double newline for paragraph spacing
    static func createParagraphSpacing() -> AttributedString {
        AttributedString("\n\n")
    }

    /// Processes links and formatting within a block of text
    static func processLinksInText(_ text: String) -> AttributedString {
        var result = AttributedString()
        let range = NSRange(location: 0, length: text.utf16.count)
        let matches = linkRegex.matches(in: text, range: range)
        guard !matches.isEmpty else { return processFormattingTags(text) }

        var lastEnd = 0
        let nsString = text as NSString
        for match in matches {
            if match.range.location > lastEnd {
                let beforeRange = NSRange(location: lastEnd, length: match.range.location - lastEnd)
                let beforeText = nsString.substring(with: beforeRange)
                let formattedBeforeText = processFormattingTags(beforeText)
                result += formattedBeforeText
            }

            if let linkComponent = extractLinkComponentWithFormatting(from: match, in: nsString) {
                result += linkComponent
            }
            lastEnd = NSMaxRange(match.range)
        }

        if lastEnd < nsString.length {
            let remainingText = nsString.substring(from: lastEnd)
            let formattedRemainingText = processFormattingTags(remainingText)
            result += formattedRemainingText
        }

        return result
    }

    /// Applies paragraph styling with proper line height
    static func applyParagraphStyling(_ attributedString: AttributedString) -> AttributedString {
        var styled = attributedString
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1.5
        paragraphStyle.paragraphSpacing = 20.0
        let fullRange = styled.startIndex ..< styled.endIndex
        styled[fullRange].paragraphStyle = paragraphStyle
        return styled
    }

    /// Extracts and creates an attributed link component
    static func extractLinkComponent(from match: NSTextCheckingResult, in nsString: NSString) -> AttributedString? {
        guard match.numberOfRanges >= 4 else { return nil }
        let urlRange = match.range(at: 2)
        let textRange = match.range(at: 3)
        guard urlRange.location != NSNotFound, textRange.location != NSNotFound else { return nil }

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
            linkAttributedString.underlineStyle = .single
        }
        return linkAttributedString
    }

    /// Extracts and creates an attributed link component with formatting support
    static func extractLinkComponentWithFormatting(
        from match: NSTextCheckingResult,
        in nsString: NSString,
    ) -> AttributedString? {
        guard match.numberOfRanges >= 4 else { return nil }

        let urlRange = match.range(at: 2)
        let textRange = match.range(at: 3)
        guard urlRange.location != NSNotFound, textRange.location != NSNotFound else { return nil }

        let urlString = nsString.substring(with: urlRange)
        let linkText = nsString.substring(with: textRange)
        guard !linkText.isEmpty else { return nil }

        var linkAttributedString = processFormattingTags(linkText)
        var resolvedURL = URL(string: urlString)
        if resolvedURL?.scheme == nil, let base = URL(string: "https://news.ycombinator.com") {
            resolvedURL = URL(string: urlString, relativeTo: base)?.absoluteURL
        }
        if let url = resolvedURL {
            let fullRange = linkAttributedString.startIndex ..< linkAttributedString.endIndex
            linkAttributedString[fullRange].link = url
            linkAttributedString[fullRange].underlineStyle = .single
        }
        return linkAttributedString
    }
}
