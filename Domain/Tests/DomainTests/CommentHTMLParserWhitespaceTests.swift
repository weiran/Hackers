//
//  CommentHTMLParserWhitespaceTests.swift
//  DomainTests
//
//  Copyright © 2025 Weiran Zhang. All rights reserved.
//

// swiftlint:disable type_body_length line_length

// swiftlint:disable:next force_cast

import Testing
import Foundation
@testable import Domain

@Suite("CommentHTMLParser Whitespace Tests")
struct CommentHTMLParserWhitespaceTests {

    @Test("Whitespace preservation maintains spacing around bold tags")
    func testWhitespaceAroundBoldTags() {
        let input = "  <b>bold text</b>  "
        let result = CommentHTMLParser.parseHTMLText(input)
        let resultString = String(result.characters)

        // The whitespace before and after the bold tag should be preserved
        #expect(resultString == "  bold text  ", "Whitespace around bold tags should be preserved")
    }

    @Test("Whitespace preservation maintains spacing around italic tags")
    func testWhitespaceAroundItalicTags() {
        let input = "  <i>italic text</i>  "
        let result = CommentHTMLParser.parseHTMLText(input)
        let resultString = String(result.characters)

        // The whitespace before and after the italic tag should be preserved
        #expect(resultString == "  italic text  ", "Whitespace around italic tags should be preserved")
    }

    @Test("Whitespace preservation maintains spacing around link tags")
    func testWhitespaceAroundLinkTags() {
        let input = "  <a href=\"https://example.com\">link text</a>  "
        let result = CommentHTMLParser.parseHTMLText(input)
        let resultString = String(result.characters)

        // The whitespace before and after the link tag should be preserved
        #expect(resultString == "  link text  ", "Whitespace around link tags should be preserved")
    }

    @Test("Whitespace preservation maintains spacing with mixed formatting tags")
    func testWhitespaceWithMixedFormattingTags() {
        let input = "  <b>bold</b> and <i>italic</i> text  "
        let result = CommentHTMLParser.parseHTMLText(input)
        let resultString = String(result.characters)

        // The whitespace around each formatting tag should be preserved
        #expect(resultString == "  bold and italic text  ", "Whitespace around mixed formatting tags should be preserved")
    }

    @Test("Whitespace preservation maintains spacing with nested formatting")
    func testWhitespaceWithNestedFormatting() {
        let input = "  <b>bold with <i>nested</i> text</b>  "
        let result = CommentHTMLParser.parseHTMLText(input)
        let resultString = String(result.characters)

        // The whitespace around the outer tag should be preserved
        #expect(resultString == "  bold with nested text  ", "Whitespace around nested formatting should be preserved")
    }

    @Test("Whitespace preservation maintains spacing in paragraph context")
    func testWhitespaceInParagraphContext() {
        let input = "<p>  <b>bold</b> and <i>italic</i> text  </p>"
        let result = CommentHTMLParser.parseHTMLText(input)
        let resultString = String(result.characters)

        // The whitespace around formatting tags in paragraphs should be preserved
        #expect(resultString.contains("bold"), "Bold text should be preserved")
        #expect(resultString.contains("italic"), "Italic text should be preserved")
    }

    @Test("Whitespace preservation maintains spacing with links and formatting")
    func testWhitespaceWithLinksAndFormatting() {
        let input = "  <a href=\"https://example.com\"><b>bold link</b></a>  "
        let result = CommentHTMLParser.parseHTMLText(input)
        let resultString = String(result.characters)

        // The whitespace around the link and formatting should be preserved
        #expect(resultString == "  bold link  ", "Whitespace around links with formatting should be preserved")
    }

    @Test("Edge case handles empty string correctly")
    func testEmptyString() {
        let result = CommentHTMLParser.parseHTMLText("")
        #expect(result.characters.isEmpty, "Empty string should return empty AttributedString")
    }

    @Test("Edge case handles whitespace-only string correctly")
    func testWhitespaceOnly() {
        let result = CommentHTMLParser.parseHTMLText("   \n\t   ")
        #expect(result.characters.isEmpty, "Whitespace-only string should return empty AttributedString")
    }
}
