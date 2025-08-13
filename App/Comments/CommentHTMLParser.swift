//
//  CommentHTMLParser.swift
//  Hackers
//
//  Created by Weiran Zhang on SwiftUI Migration.
//  Copyright © 2024 Glass Umbrella. All rights reserved.
//

import Foundation
import SwiftUI

/// A class responsible for parsing HTML content in comments
class CommentHTMLParser {
    
    /// Parses HTML text into an AttributedString
    /// - Parameter htmlString: The raw HTML string to parse
    /// - Returns: An AttributedString with parsed content, or nil if parsing fails
    static func parseHTMLText(_ htmlString: String) -> AttributedString? {
        guard !htmlString.isEmpty else {
            return AttributedString("")
        }
        
        let processedHTML = htmlString
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&#x27;", with: "'")
            .replacingOccurrences(of: "&#39;", with: "'")
            .replacingOccurrences(of: "&nbsp;", with: " ")
        
        // Extract links and create attributed string
        var result = AttributedString()
        let linkPattern = "<a\\\\s+(?:[^>]*?\\\\s+)?href=([\\\"'])(.*?)\\\\1[^>]*?>(.*?)</a>"
        guard let regex = try? NSRegularExpression(pattern: linkPattern,
                                                  options: [.caseInsensitive, .dotMatchesLineSeparators]) else {
            let trimmedText = processedHTML.strippingHTML().addingParagraphBreaks()
            return AttributedString(trimmedText)
        }
        
        let nsString = processedHTML as NSString
        let matches = regex.matches(in: processedHTML, options: [],
                                    range: NSRange(location: 0, length: nsString.length))
        
        var lastEnd = 0
        
        for match in matches {
            // Add text before the link
            if match.range.location > lastEnd {
                let beforeRange = NSRange(location: lastEnd, length: match.range.location - lastEnd)
                let beforeText = nsString.substring(with: beforeRange).strippingHTML().addingParagraphBreaks()
                result += AttributedString(beforeText)
            }
            
            // Extract URL and link text
            let urlRange = match.range(at: 2)
            let textRange = match.range(at: 3)
            
            if urlRange.location != NSNotFound && textRange.location != NSNotFound {
                let urlString = nsString.substring(with: urlRange)
                let linkText = nsString.substring(with: textRange).strippingHTML()
                
                var linkAttributedString = AttributedString(linkText)
                if let url = URL(string: urlString) {
                    linkAttributedString.link = url
                    linkAttributedString.foregroundColor = .blue
                    linkAttributedString.underlineStyle = .single
                }
                result += linkAttributedString
            }
            
            lastEnd = match.range.location + match.range.length
        }
        
        // Add remaining text after last link
        if lastEnd < nsString.length {
            let remainingRange = NSRange(location: lastEnd, length: nsString.length - lastEnd)
            let remainingText = nsString.substring(with: remainingRange).strippingHTML().addingParagraphBreaks()
            result += AttributedString(remainingText)
        }
        
        // If no links were found, just strip HTML and add paragraph breaks
        if matches.isEmpty {
            let trimmedText = processedHTML.strippingHTML().addingParagraphBreaks()
            result = AttributedString(trimmedText)
        }
        
        return result
    }
}

extension String {
    func strippingHTML() -> String {
        return self.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression, range: nil)
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&#x27;", with: "'")
            .replacingOccurrences(of: "&#39;", with: "'")
            .replacingOccurrences(of: "&nbsp;", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    func addingParagraphBreaks() -> String {
        return self.replacingOccurrences(of: "\n", with: "\n\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}