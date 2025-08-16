//
//  CommentHTMLParserTests.swift
//  HackersTests
//
//  Created by Weiran Zhang on SwiftUI Migration.
//  Copyright © 2024 Glass Umbrella. All rights reserved.
//

import Testing
import Foundation
@testable import Hackers

@Suite("CommentHTMLParser Tests")
struct CommentHTMLParserTests {

    // MARK: - HTML Entity Decoding Tests

    @Test("HTML entity decoding - basic entities")
    func testHTMLEntityDecoding() {
        let input = "This &amp; that &lt;tag&gt; &quot;quoted&quot; &#x27;apostrophe&#39; &nbsp;space"
        let expected = "This & that <tag> \"quoted\" 'apostrophe' space"
        let result = CommentHTMLParser.decodeHTMLEntities(input)
        #expect(result == expected, "Basic HTML entities should be decoded correctly")
    }

    @Test("HTML entity decoding - no entities")
    func testHTMLEntityDecodingNoEntities() {
        let input = "This is plain text with no entities"
        let result = CommentHTMLParser.decodeHTMLEntities(input)
        #expect(result == input, "Text without entities should remain unchanged")
    }

    @Test("HTML entity decoding - mixed content")
    func testHTMLEntityDecodingMixedContent() {
        let input = "Code: if (x &lt; y &amp;&amp; z &gt; w) { return &quot;success&quot;; }"
        let expected = "Code: if (x < y && z > w) { return \"success\"; }"
        let result = CommentHTMLParser.decodeHTMLEntities(input)
        #expect(result == expected, "Mixed content with multiple entities should be decoded correctly")
    }

    // MARK: - HTML Tag Stripping Tests

    @Test("HTML tag stripping - basic tags")
    func testHTMLTagStripping() {
        let input = "<p>Hello <b>world</b> <i>test</i></p>"
        let expected = "Hello world test"
        let result = CommentHTMLParser.stripHTMLTags(input)
        #expect(result == expected, "HTML tags should be stripped correctly")
    }

    @Test("HTML tag stripping - complex tags with attributes")
    func testHTMLTagStrippingWithAttributes() {
        let input = "<div class=\"test\" id=\"example\">Content <span style=\"color: red\">here</span></div>"
        let expected = "Content here"
        let result = CommentHTMLParser.stripHTMLTags(input)
        #expect(result == expected, "HTML tags with attributes should be stripped correctly")
    }

    @Test("HTML tag stripping - no tags")
    func testHTMLTagStrippingNoTags() {
        let input = "Plain text without any tags"
        let result = CommentHTMLParser.stripHTMLTags(input)
        #expect(result == input, "Text without HTML tags should remain unchanged")
    }

    // MARK: - Link Parsing Tests

    @Test("Link parsing - basic link")
    func testBasicLinkParsing() {
        let input = "Check out <a href=\"https://example.com\">this link</a> for more info."
        let result = CommentHTMLParser.parseHTMLText(input)
        let resultString = String(result.characters)
        #expect(resultString.contains("this link"), "Link text should be preserved")
        #expect(!resultString.contains("<a"), "HTML tags should be removed")
        #expect(!resultString.contains("href"), "HTML attributes should be removed")
    }

    @Test("Link parsing - multiple links")
    func testMultipleLinkParsing() {
        let input = "Visit <a href=\"https://site1.com\">Site 1</a> and <a href=\"https://site2.com\">Site 2</a> today."
        let result = CommentHTMLParser.parseHTMLText(input)
        let resultString = String(result.characters)
        #expect(resultString.contains("Site 1"), "First link text should be preserved")
        #expect(resultString.contains("Site 2"), "Second link text should be preserved")
        #expect(resultString.contains("and"), "Text between links should be preserved")
    }

    @Test("Link parsing - link with single quotes")
    func testLinkParsingWithSingleQuotes() {
        let input = "Check <a href='https://example.com'>this site</a> out."
        let result = CommentHTMLParser.parseHTMLText(input)
        let resultString = String(result.characters)
        #expect(resultString.contains("this site"), "Link text should be preserved")
        #expect(!resultString.contains("href"), "HTML attributes should be removed")
    }

    @Test("Link parsing - link with additional attributes")
    func testLinkParsingWithAttributes() {
        let input = "Visit <a href=\"https://example.com\" target=\"_blank\" class=\"link\">Example</a> now."
        let result = CommentHTMLParser.parseHTMLText(input)
        let resultString = String(result.characters)
        #expect(resultString.contains("Example"), "Link text should be preserved")
        #expect(!resultString.contains("target"), "Additional attributes should be removed")
    }

    @Test("Link parsing - preserves whitespace around links")
    func testLinkParsingPreservesWhitespace() {
        let input = "Text before <a href=\"https://example.com\">link</a> text after"
        let result = CommentHTMLParser.parseHTMLText(input)
        let resultString = String(result.characters)
        #expect(resultString == "Text before link text after", "Whitespace around links should be preserved")
    }

    // MARK: - Paragraph Handling Tests

    @Test("Paragraph parsing - single paragraph")
    func testSingleParagraphParsing() {
        let input = "<p>This is a paragraph with some content.</p>"
        let result = CommentHTMLParser.parseHTMLText(input)
        let resultString = String(result.characters)
        #expect(resultString.contains("This is a paragraph"), "Paragraph content should be preserved")
        #expect(!resultString.contains("<p>"), "Paragraph tags should be removed")
    }

    @Test("Paragraph parsing - multiple paragraphs")
    func testMultipleParagraphParsing() {
        let input = "<p>First paragraph content.</p><p>Second paragraph content.</p>"
        let result = CommentHTMLParser.parseHTMLText(input)
        let resultString = String(result.characters)
        #expect(resultString.contains("First paragraph"), "First paragraph should be preserved")
        #expect(resultString.contains("Second paragraph"), "Second paragraph should be preserved")
        #expect(resultString.contains("\n\n"), "Paragraphs should be separated by double newlines")
    }

    @Test("Paragraph parsing - paragraph with link")
    func testParagraphWithLinkParsing() {
        let input = "<p>Check out <a href=\"https://example.com\">this link</a> in paragraph.</p>"
        let result = CommentHTMLParser.parseHTMLText(input)
        let resultString = String(result.characters)
        #expect(resultString.contains("Check out"), "Paragraph text should be preserved")
        #expect(resultString.contains("this link"), "Link text should be preserved")
        #expect(resultString.contains("in paragraph"), "Text after link should be preserved")
    }

    @Test("Paragraph parsing - text before first paragraph")
    func testTextBeforeFirstParagraph() {
        let input = "Text before paragraph <p>This is the paragraph content.</p>"
        let result = CommentHTMLParser.parseHTMLText(input)
        let resultString = String(result.characters)
        #expect(resultString.contains("Text before paragraph"), "Text before paragraph should be preserved")
        #expect(resultString.contains("This is the paragraph"), "Paragraph content should be preserved")
        #expect(resultString.contains("\n\n"), "Text and paragraph should be separated")
    }

    @Test("Paragraph parsing - text after last paragraph")
    func testTextAfterLastParagraph() {
        let input = "<p>This is the paragraph content.</p>Text after paragraph"
        let result = CommentHTMLParser.parseHTMLText(input)
        let resultString = String(result.characters)
        #expect(resultString.contains("This is the paragraph"), "Paragraph content should be preserved")
        #expect(resultString.contains("Text after paragraph"), "Text after paragraph should be preserved")
        #expect(resultString.contains("\n\n"), "Paragraph and text should be separated")
    }

    @Test("Paragraph parsing - link in text before paragraph")
    func testLinkInTextBeforeParagraph() {
        let input = "Check <a href=\"https://example.com\">this link</a> before paragraph <p>Paragraph content.</p>"
        let result = CommentHTMLParser.parseHTMLText(input)
        let resultString = String(result.characters)
        #expect(resultString.contains("this link"), "Link in text before paragraph should be processed")
        #expect(resultString.contains("before paragraph"), "Text around link should be preserved")
        #expect(resultString.contains("Paragraph content"), "Paragraph content should be preserved")
    }

    // MARK: - Complex Content Tests

    @Test("Complex content - mixed paragraphs and links")
    func testComplexMixedContent() {
        let input = """
        Introduction text with <a href="https://intro.com">intro link</a>.
        <p>First paragraph with <a href="https://first.com">first link</a> and more content.</p>
        <p>Second paragraph has <a href="https://second.com">second link</a> here.</p>
        Conclusion text with <a href="https://conclusion.com">conclusion link</a>.
        """
        let result = CommentHTMLParser.parseHTMLText(input)
        let resultString = String(result.characters)

        #expect(resultString.contains("intro link"), "Intro link should be processed")
        #expect(resultString.contains("first link"), "First paragraph link should be processed")
        #expect(resultString.contains("second link"), "Second paragraph link should be processed")
        #expect(resultString.contains("conclusion link"), "Conclusion link should be processed")
        #expect(!resultString.contains("<"), "No HTML tags should remain")
    }

    @Test("Complex content - nested HTML with entities")
    func testComplexNestedHTMLWithEntities() {
        let input = "<p>Code example: <code>if (x &lt; y &amp;&amp; z &gt; 0) { return true; }</code></p>"
        let result = CommentHTMLParser.parseHTMLText(input)
        let resultString = String(result.characters)
        #expect(resultString.contains("if (x < y && z > 0)"), "HTML entities should be decoded")
        #expect(!resultString.contains("<code>"), "Nested HTML tags should be removed")
    }

    // MARK: - Edge Cases

    @Test("Edge case - empty string")
    func testEmptyString() {
        let result = CommentHTMLParser.parseHTMLText("")
        #expect(result.characters.isEmpty, "Empty string should return empty AttributedString")
    }

    @Test("Edge case - whitespace only")
    func testWhitespaceOnly() {
        let result = CommentHTMLParser.parseHTMLText("   \n\t   ")
        #expect(result.characters.isEmpty, "Whitespace-only string should return empty AttributedString")
    }

    @Test("Edge case - HTML tags only")
    func testHTMLTagsOnly() {
        let result = CommentHTMLParser.parseHTMLText("<p></p><div></div>")
        #expect(result.characters.isEmpty, "Empty HTML tags should return empty AttributedString")
    }

    @Test("Edge case - malformed link")
    func testMalformedLink() {
        let input = "Check <a href=\"https://example.com\">incomplete link"
        let result = CommentHTMLParser.parseHTMLText(input)
        let resultString = String(result.characters)
        #expect(resultString.contains("Check"), "Text before malformed link should be preserved")
        #expect(resultString.contains("incomplete link"), "Malformed link content should be preserved as text")
    }

    @Test("Edge case - link without href")
    func testLinkWithoutHref() {
        let input = "Check <a>link without href</a> here"
        let result = CommentHTMLParser.parseHTMLText(input)
        let resultString = String(result.characters)
        #expect(resultString.contains("link without href"), "Link text should be preserved even without href")
    }

    @Test("Edge case - empty paragraph")
    func testEmptyParagraph() {
        let input = "Before <p></p> after"
        let result = CommentHTMLParser.parseHTMLText(input)
        let resultString = String(result.characters)
        #expect(resultString.contains("Before"), "Text before empty paragraph should be preserved")
        #expect(resultString.contains("after"), "Text after empty paragraph should be preserved")
    }

    // MARK: - Newline Handling Tests

    @Test("Newline handling - text with newlines but no paragraphs")
    func testNewlineHandlingWithoutParagraphs() {
        let input = "Line one\nLine two\nLine three"
        let result = CommentHTMLParser.parseHTMLText(input)
        let resultString = String(result.characters)
        #expect(resultString == "Line one Line two Line three", "Newlines should be converted to spaces when no paragraph tags are present")
    }

    @Test("Newline handling - links with newlines")
    func testNewlineHandlingInLinks() {
        let input = "Check out <a href=\"https://example.com\">this\nlink\ntext</a> here"
        let result = CommentHTMLParser.parseHTMLText(input)
        let resultString = String(result.characters)
        #expect(resultString == "Check out this link text here", "Newlines in link text should be converted to spaces")
    }

    @Test("Newline handling - text before and after links")
    func testNewlineHandlingAroundLinks() {
        let input = "Text\nwith\nnewlines <a href=\"https://example.com\">link</a> more\ntext\nhere"
        let result = CommentHTMLParser.parseHTMLText(input)
        let resultString = String(result.characters)
        #expect(resultString == "Text with newlines link more text here", "Newlines around links should be converted to spaces")
    }

    @Test("Newline handling - only paragraphs should create newlines")
    func testOnlyParagraphsCreateNewlines() {
        let input = "Text\nbefore\n<p>Paragraph\ncontent\nhere</p>\nText\nafter"
        let result = CommentHTMLParser.parseHTMLText(input)
        let resultString = String(result.characters)
        #expect(resultString.contains("Text before"), "Text before paragraph should normalize newlines")
        #expect(resultString.contains("Text after"), "Text after paragraph should normalize newlines")
        #expect(resultString.contains("\n\n"), "Only paragraph spacing should create newlines")
        // The paragraph content itself may preserve some formatting, but the spacing around it should be normalized
    }

    @Test("Newline handling - complex HTML with multiple elements")
    func testComplexHTMLNewlineHandling() {
        let input = "Start\ntext\n<div>Some\ndiv\ncontent</div>\nMiddle\ntext\n<span>span\ncontent</span>\nEnd\ntext"
        let result = CommentHTMLParser.parseHTMLText(input)
        let resultString = String(result.characters)
        let expected = "Start text Some div content Middle text span content End text"
        #expect(resultString == expected, "All newlines should be normalized to spaces when no paragraph tags are present")
    }

    // MARK: - String Extension Tests

    @Test("String extension - strippingHTML")
    func testStringExtensionStrippingHTML() {
        let input = "<p>Hello &amp; <a href=\"https://example.com\">world</a>!</p>"
        let result = input.strippingHTML()
        let expected = "Hello & world!"
        #expect(result == expected, "String extension should strip HTML and decode entities")
    }

    @Test("String extension - strippingHTML with whitespace")
    func testStringExtensionStrippingHTMLWithWhitespace() {
        let input = "  <p>  Content  </p>  "
        let result = input.strippingHTML()
        #expect(result == "Content", "String extension should trim whitespace")
    }
}
