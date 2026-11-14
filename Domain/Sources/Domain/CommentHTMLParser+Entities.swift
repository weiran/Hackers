//
//  CommentHTMLParser+Entities.swift
//  Domain
//
//  Split entity decoding from CommentHTMLParser to reduce file length
//

import Foundation

extension CommentHTMLParser {
    /// Efficiently decodes HTML entities using a single pass
    static func decodeHTMLEntities(_ html: String) -> String {
        var result = String()
        result.reserveCapacity(html.count)

        var index = html.startIndex
        while index < html.endIndex {
            guard html[index] == "&" else {
                result.append(html[index])
                index = html.index(after: index)
                continue
            }

            // A candidate entity cannot cross whitespace or another ampersand;
            // otherwise a plain ampersand (for example in "AT&T &amp;") would
            // swallow the later valid entity while searching for its semicolon.
            var cursor = html.index(after: index)
            var semicolon: String.Index?
            while cursor < html.endIndex {
                let character = html[cursor]
                if character == ";" {
                    semicolon = cursor
                    break
                }
                if character == "&" || character.isWhitespace {
                    break
                }
                cursor = html.index(after: cursor)
            }
            guard let semicolon else {
                result.append(html[index])
                index = html.index(after: index)
                continue
            }

            let token = String(html[index ... semicolon])
            if token == "&nbsp;" {
                // Preserve the historical whitespace behavior around nbsp.
                let hasRawLeadingSpace = index > html.startIndex &&
                    html[html.index(before: index)] == " "
                if !hasRawLeadingSpace { result.append(" ") }
                let afterSemicolon = html.index(after: semicolon)
                if !hasRawLeadingSpace, afterSemicolon < html.endIndex, html[afterSemicolon] == " " {
                    index = html.index(after: afterSemicolon)
                } else {
                    index = afterSemicolon
                }
                continue
            }

            if let replacement = htmlEntityMap[token] {
                result.append(contentsOf: replacement)
                index = html.index(after: semicolon)
                continue
            }

            if let scalar = numericScalar(for: token) {
                result.unicodeScalars.append(scalar)
                index = html.index(after: semicolon)
                continue
            }

            // Unknown entities and invalid Unicode scalars remain literal.
            result.append(contentsOf: token)
            index = html.index(after: semicolon)
        }

        return result
    }

    private static func numericScalar(for entity: String) -> Unicode.Scalar? {
        let digits: String
        let radix: Int
        if entity.hasPrefix("&#x") || entity.hasPrefix("&#X") {
            digits = String(entity.dropFirst(3).dropLast())
            radix = 16
        } else if entity.hasPrefix("&#") {
            digits = String(entity.dropFirst(2).dropLast())
            radix = 10
        } else {
            return nil
        }

        guard !digits.isEmpty, let value = UInt32(digits, radix: radix) else { return nil }
        return Unicode.Scalar(value)
    }
}
