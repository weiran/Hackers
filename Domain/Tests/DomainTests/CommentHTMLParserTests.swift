//
//  CommentHTMLParserTests.swift
//  DomainTests
//
//  Copyright © 2025 Weiran Zhang. All rights reserved.
//

// swiftlint:disable file_length type_body_length line_length force_cast

@testable import Domain
import Foundation
import Testing

@Suite("CommentHTMLParser Tests")
struct CommentHTMLParserTests {
    // MARK: - HTML Entity Decoding Tests

    @Test("HTML entity decoding handles basic entities")
    func hTMLEntityDecoding() {
        let input = "This &amp; that &lt;tag&gt; &quot;quoted&quot; &#x27;apostrophe&#39; &nbsp;space"
        let expected = "This & that <tag> \"quoted\" 'apostrophe' space"
        let result = CommentHTMLParser.decodeHTMLEntities(input)
        #expect(result == expected, "Basic HTML entities should be decoded correctly")
    }

    @Test("HTML entity decoding preserves text without entities")
    func hTMLEntityDecodingNoEntities() {
        let input = "This is plain text with no entities"
        let result = CommentHTMLParser.decodeHTMLEntities(input)
        #expect(result == input, "Text without entities should remain unchanged")
    }

    @Test("HTML entity decoding handles mixed content correctly")
    func hTMLEntityDecodingMixedContent() {
        let input = "Code: if (x &lt; y &amp;&amp; z &gt; w) { return &quot;success&quot;; }"
        let expected = "Code: if (x < y && z > w) { return \"success\"; }"
        let result = CommentHTMLParser.decodeHTMLEntities(input)
        #expect(result == expected, "Mixed content with multiple entities should be decoded correctly")
    }

    // MARK: - HTML Tag Stripping Tests

    @Test("HTML tag stripping removes basic tags")
    func hTMLTagStripping() {
        let input = "<p>Hello <b>world</b> <i>test</i></p>"
        let expected = "Hello world test"
        let result = CommentHTMLParser.stripHTMLTags(input)
        #expect(result == expected, "HTML tags should be stripped correctly")
    }

    @Test("HTML tag stripping removes complex tags with attributes")
    func hTMLTagStrippingWithAttributes() {
        let input = "<div class=\"test\" id=\"example\">Content <span style=\"color: red\">here</span></div>"
        let expected = "Content here"
        let result = CommentHTMLParser.stripHTMLTags(input)
        #expect(result == expected, "HTML tags with attributes should be stripped correctly")
    }

    @Test("HTML tag stripping preserves text without tags")
    func hTMLTagStrippingNoTags() {
        let input = "Plain text without any tags"
        let result = CommentHTMLParser.stripHTMLTags(input)
        #expect(result == input, "Text without HTML tags should remain unchanged")
    }

    // MARK: - Link Parsing Tests

    @Test("Link parsing handles basic link correctly")
    func basicLinkParsing() {
        let input = "Check out <a href=\"https://example.com\">this link</a> for more info."
        let result = CommentHTMLParser.parseHTMLText(input)
        let resultString = String(result.characters)
        #expect(resultString.contains("this link"), "Link text should be preserved")
        #expect(!resultString.contains("<a"), "HTML tags should be removed")
        #expect(!resultString.contains("href"), "HTML attributes should be removed")

        // Verify the link has proper URL attribute
        let linkRange = resultString.range(of: "this link")!
        let start = result.characters.index(result.characters.startIndex, offsetBy: resultString.distance(from: resultString.startIndex, to: linkRange.lowerBound))
        let end = result.characters.index(result.characters.startIndex, offsetBy: resultString.distance(from: resultString.startIndex, to: linkRange.upperBound))
        let linkAttributes = result[start ..< end]
        #expect(linkAttributes.link?.absoluteString == "https://example.com", "Link should have correct URL")
    }

    @Test("Link parsing handles multiple links correctly")
    func multipleLinkParsing() {
        let input = "Visit <a href=\"https://site1.com\">Site 1</a> and <a href=\"https://site2.com\">Site 2</a> today."
        let result = CommentHTMLParser.parseHTMLText(input)
        let resultString = String(result.characters)
        #expect(resultString.contains("Site 1"), "First link text should be preserved")
        #expect(resultString.contains("Site 2"), "Second link text should be preserved")
        #expect(resultString.contains("and"), "Text between links should be preserved")
    }

    @Test("Link parsing handles links with single quotes")
    func linkParsingWithSingleQuotes() {
        let input = "Check <a href='https://example.com'>this site</a> out."
        let result = CommentHTMLParser.parseHTMLText(input)
        let resultString = String(result.characters)
        #expect(resultString.contains("this site"), "Link text should be preserved")
        #expect(!resultString.contains("href"), "HTML attributes should be removed")
    }

    @Test("Link parsing handles links with additional attributes")
    func linkParsingWithAttributes() {
        let input = "Visit <a href=\"https://example.com\" target=\"_blank\" class=\"link\">Example</a> now."
        let result = CommentHTMLParser.parseHTMLText(input)
        let resultString = String(result.characters)
        #expect(resultString.contains("Example"), "Link text should be preserved")
        #expect(!resultString.contains("target"), "Additional attributes should be removed")
    }

    @Test("Link parsing preserves whitespace around links")
    func linkParsingPreservesWhitespace() {
        let input = "Text before <a href=\"https://example.com\">link</a> text after"
        let result = CommentHTMLParser.parseHTMLText(input)
        let resultString = String(result.characters)
        #expect(resultString == "Text before link text after", "Whitespace around links should be preserved")
    }

    // MARK: - Paragraph Handling Tests

    @Test("Paragraph parsing handles single paragraph correctly")
    func singleParagraphParsing() {
        let input = "<p>This is a paragraph with some content.</p>"
        let result = CommentHTMLParser.parseHTMLText(input)
        let resultString = String(result.characters)
        #expect(resultString.contains("This is a paragraph"), "Paragraph content should be preserved")
        #expect(!resultString.contains("<p>"), "Paragraph tags should be removed")
    }

    @Test("Paragraph parsing handles multiple paragraphs with proper spacing")
    func multipleParagraphParsing() {
        let input = "<p>First paragraph content.</p><p>Second paragraph content.</p>"
        let result = CommentHTMLParser.parseHTMLText(input)
        let resultString = String(result.characters)
        #expect(resultString.contains("First paragraph"), "First paragraph should be preserved")
        #expect(resultString.contains("Second paragraph"), "Second paragraph should be preserved")
        #expect(resultString.contains("\n\n"), "Paragraphs should be separated by double newlines")
    }

    @Test("Paragraph parsing handles paragraphs containing links")
    func paragraphWithLinkParsing() {
        let input = "<p>Check out <a href=\"https://example.com\">this link</a> in paragraph.</p>"
        let result = CommentHTMLParser.parseHTMLText(input)
        let resultString = String(result.characters)
        #expect(resultString.contains("Check out"), "Paragraph text should be preserved")
        #expect(resultString.contains("this link"), "Link text should be preserved")
        #expect(resultString.contains("in paragraph"), "Text after link should be preserved")
    }

    @Test("Paragraph parsing handles text before first paragraph")
    func textBeforeFirstParagraph() {
        let input = "Text before paragraph <p>This is the paragraph content.</p>"
        let result = CommentHTMLParser.parseHTMLText(input)
        let resultString = String(result.characters)
        #expect(resultString.contains("Text before paragraph"), "Text before paragraph should be preserved")
        #expect(resultString.contains("This is the paragraph"), "Paragraph content should be preserved")
        #expect(resultString.contains("\n\n"), "Text and paragraph should be separated")
    }

    @Test("Paragraph parsing handles text after last paragraph")
    func textAfterLastParagraph() {
        let input = "<p>This is the paragraph content.</p>Text after paragraph"
        let result = CommentHTMLParser.parseHTMLText(input)
        let resultString = String(result.characters)
        #expect(resultString.contains("This is the paragraph"), "Paragraph content should be preserved")
        #expect(resultString.contains("Text after paragraph"), "Text after paragraph should be preserved")
        #expect(resultString.contains("\n\n"), "Paragraph and text should be separated")
    }

    @Test("Paragraph parsing handles links in text before paragraphs")
    func linkInTextBeforeParagraph() {
        let input = "Check <a href=\"https://example.com\">this link</a> before paragraph <p>Paragraph content.</p>"
        let result = CommentHTMLParser.parseHTMLText(input)
        let resultString = String(result.characters)
        #expect(resultString.contains("this link"), "Link in text before paragraph should be processed")
        #expect(resultString.contains("before paragraph"), "Text around link should be preserved")
        #expect(resultString.contains("Paragraph content"), "Paragraph content should be preserved")
    }

    // MARK: - Complex Content Tests

    @Test("Complex content parsing handles mixed paragraphs and links")
    func complexMixedContent() {
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

    @Test("Complex content parsing handles nested HTML with entities")
    func complexNestedHTMLWithEntities() {
        let input = "<p>Code example: <code>if (x &lt; y &amp;&amp; z &gt; 0) { return true; }</code></p>"
        let result = CommentHTMLParser.parseHTMLText(input)
        let resultString = String(result.characters)
        #expect(resultString.contains("if (x < y && z > 0)"), "HTML entities should be decoded")
        #expect(!resultString.contains("<code>"), "Nested HTML tags should be removed")
    }

    // MARK: - Edge Cases

    @Test("Edge case handles empty string correctly")
    func emptyString() {
        let result = CommentHTMLParser.parseHTMLText("")
        #expect(result.characters.isEmpty, "Empty string should return empty AttributedString")
    }

    @Test("Edge case handles whitespace-only string correctly")
    func whitespaceOnly() {
        let result = CommentHTMLParser.parseHTMLText("   \n\t   ")
        #expect(result.characters.isEmpty, "Whitespace-only string should return empty AttributedString")
    }

    @Test("Edge case handles HTML tags without content")
    func hTMLTagsOnly() {
        let result = CommentHTMLParser.parseHTMLText("<p></p><div></div>")
        #expect(result.characters.isEmpty, "Empty HTML tags should return empty AttributedString")
    }

    @Test("Edge case handles malformed links gracefully")
    func malformedLink() {
        let input = "Check <a href=\"https://example.com\">incomplete link"
        let result = CommentHTMLParser.parseHTMLText(input)
        let resultString = String(result.characters)
        #expect(resultString.contains("Check"), "Text before malformed link should be preserved")
        #expect(resultString.contains("incomplete link"), "Malformed link content should be preserved as text")
    }

    @Test("Edge case handles links without href attribute")
    func linkWithoutHref() {
        let input = "Check <a>link without href</a> here"
        let result = CommentHTMLParser.parseHTMLText(input)
        let resultString = String(result.characters)
        #expect(resultString.contains("link without href"), "Link text should be preserved even without href")
    }

    @Test("Edge case handles empty paragraphs correctly")
    func emptyParagraph() {
        let input = "Before <p></p> after"
        let result = CommentHTMLParser.parseHTMLText(input)
        let resultString = String(result.characters)
        #expect(resultString.contains("Before"), "Text before empty paragraph should be preserved")
        #expect(resultString.contains("after"), "Text after empty paragraph should be preserved")
    }

    // MARK: - Newline Handling Tests

    @Test("Newline handling converts newlines to spaces without paragraphs")
    func newlineHandlingWithoutParagraphs() {
        let input = "Line one\nLine two\nLine three"
        let result = CommentHTMLParser.parseHTMLText(input)
        let resultString = String(result.characters)
        #expect(resultString == "Line one Line two Line three", "Newlines should be converted to spaces when no paragraph tags are present")
    }

    @Test("Newline handling converts newlines in link text to spaces")
    func newlineHandlingInLinks() {
        let input = "Check out <a href=\"https://example.com\">this\nlink\ntext</a> here"
        let result = CommentHTMLParser.parseHTMLText(input)
        let resultString = String(result.characters)
        #expect(resultString == "Check out this link text here", "Newlines in link text should be converted to spaces")
    }

    @Test("Newline handling normalizes text around links")
    func newlineHandlingAroundLinks() {
        let input = "Text\nwith\nnewlines <a href=\"https://example.com\">link</a> more\ntext\nhere"
        let result = CommentHTMLParser.parseHTMLText(input)
        let resultString = String(result.characters)
        #expect(resultString == "Text with newlines link more text here", "Newlines around links should be converted to spaces")
    }

    @Test("Newline handling preserves paragraph structure while normalizing other content")
    func onlyParagraphsCreateNewlines() {
        let input = "Text\nbefore\n<p>Paragraph\ncontent\nhere</p>\nText\nafter"
        let result = CommentHTMLParser.parseHTMLText(input)
        let resultString = String(result.characters)
        #expect(resultString.contains("Text before"), "Text before paragraph should normalize newlines")
        #expect(resultString.contains("Text after"), "Text after paragraph should normalize newlines")
        #expect(resultString.contains("\n\n"), "Only paragraph spacing should create newlines")
        // The paragraph content itself may preserve some formatting, but the spacing around it should be normalized
    }

    @Test("Newline handling normalizes complex HTML to single spaces")
    func complexHTMLNewlineHandling() {
        let input = "Start\ntext\n<div>Some\ndiv\ncontent</div>\nMiddle\ntext\n<span>span\ncontent</span>\nEnd\ntext"
        let result = CommentHTMLParser.parseHTMLText(input)
        let resultString = String(result.characters)
        let expected = "Start text Some div content Middle text span content End text"
        #expect(resultString == expected, "All newlines should be normalized to spaces when no paragraph tags are present")
    }

    // MARK: - Bold Formatting Tests

    @Test("Bold formatting applies to basic bold tags")
    func basicBoldFormatting() {
        let input = "This is <b>bold text</b> in a sentence."
        let result = CommentHTMLParser.parseHTMLText(input)
        let resultString = String(result.characters)
        #expect(resultString == "This is bold text in a sentence.", "Bold text content should be preserved")

        // Check that bold formatting is applied
        let boldRange = resultString.range(of: "bold text")!
        let start = result.characters.index(result.characters.startIndex, offsetBy: resultString.distance(from: resultString.startIndex, to: boldRange.lowerBound))
        let end = result.characters.index(result.characters.startIndex, offsetBy: resultString.distance(from: resultString.startIndex, to: boldRange.upperBound))
        let attributes = result[start ..< end]
        #expect(attributes.font != nil, "Bold text should have font attribute")
    }

    @Test("Bold formatting handles multiple bold tags correctly")
    func multipleBoldFormatting() {
        let input = "First <b>bold</b> and second <b>bold</b> text."
        let result = CommentHTMLParser.parseHTMLText(input)
        let resultString = String(result.characters)
        #expect(resultString == "First bold and second bold text.", "Multiple bold texts should be processed correctly")
        #expect(!resultString.contains("<b>"), "Bold tags should be removed")
    }

    @Test("Bold formatting handles bold tags with attributes")
    func boldFormattingWithAttributes() {
        let input = "Text with <b class=\"highlight\" id=\"test\">bold styling</b> here."
        let result = CommentHTMLParser.parseHTMLText(input)
        let resultString = String(result.characters)
        #expect(resultString == "Text with bold styling here.", "Bold text with attributes should be processed correctly")
        #expect(!resultString.contains("class"), "Bold tag attributes should be removed")
    }

    @Test("Bold formatting handles nested bold content")
    func boldFormattingNested() {
        let input = "Check <a href=\"https://example.com\">this <b>bold link</b></a> out."
        let result = CommentHTMLParser.parseHTMLText(input)
        let resultString = String(result.characters)
        #expect(resultString == "Check this bold link out.", "Bold text within links should be processed")
    }

    // MARK: - Italic Formatting Tests

    @Test("Italic formatting applies to basic italic tags")
    func basicItalicFormatting() {
        let input = "This is <i>italic text</i> in a sentence."
        let result = CommentHTMLParser.parseHTMLText(input)
        let resultString = String(result.characters)
        #expect(resultString == "This is italic text in a sentence.", "Italic text content should be preserved")

        // Check that italic formatting is applied
        let italicRange = resultString.range(of: "italic text")!
        let start = result.characters.index(result.characters.startIndex, offsetBy: resultString.distance(from: resultString.startIndex, to: italicRange.lowerBound))
        let end = result.characters.index(result.characters.startIndex, offsetBy: resultString.distance(from: resultString.startIndex, to: italicRange.upperBound))
        let attributes = result[start ..< end]
        #expect(attributes.font != nil, "Italic text should have font attribute")
    }

    @Test("Italic formatting handles multiple italic tags correctly")
    func multipleItalicFormatting() {
        let input = "First <i>italic</i> and second <i>italic</i> text."
        let result = CommentHTMLParser.parseHTMLText(input)
        let resultString = String(result.characters)
        #expect(resultString == "First italic and second italic text.", "Multiple italic texts should be processed correctly")
        #expect(!resultString.contains("<i>"), "Italic tags should be removed")
    }

    @Test("Italic formatting handles italic tags with attributes")
    func italicFormattingWithAttributes() {
        let input = "Text with <i class=\"emphasis\" style=\"color: blue\">italic styling</i> here."
        let result = CommentHTMLParser.parseHTMLText(input)
        let resultString = String(result.characters)
        #expect(resultString == "Text with italic styling here.", "Italic text with attributes should be processed correctly")
        #expect(!resultString.contains("class"), "Italic tag attributes should be removed")
    }

    @Test("Italic formatting handles nested italic content")
    func italicFormattingNested() {
        let input = "Check <a href=\"https://example.com\">this <i>italic link</i></a> out."
        let result = CommentHTMLParser.parseHTMLText(input)
        let resultString = String(result.characters)
        #expect(resultString == "Check this italic link out.", "Italic text within links should be processed")
    }

    // MARK: - Combined Formatting Tests

    @Test("Combined formatting handles bold and italic together")
    func boldAndItalicTogether() {
        let input = "Text with <b>bold</b> and <i>italic</i> formatting."
        let result = CommentHTMLParser.parseHTMLText(input)
        let resultString = String(result.characters)
        #expect(resultString == "Text with bold and italic formatting.", "Bold and italic should both be processed")
        #expect(!resultString.contains("<b>"), "Bold tags should be removed")
        #expect(!resultString.contains("<i>"), "Italic tags should be removed")
    }

    @Test("Combined formatting handles nested bold and italic")
    func nestedBoldAndItalic() {
        let input = "This has <b>bold with <i>nested italic</i> text</b> content."
        let result = CommentHTMLParser.parseHTMLText(input)
        let resultString = String(result.characters)
        #expect(resultString == "This has bold with nested italic text content.", "Nested formatting should be processed correctly")
    }

    @Test("Combined formatting handles bold, italic, and links together")
    func boldItalicAndLinks() {
        let input = "Check <a href=\"https://example.com\"><b>bold</b> and <i>italic</i> link</a> here."
        let result = CommentHTMLParser.parseHTMLText(input)
        let resultString = String(result.characters)
        #expect(resultString == "Check bold and italic link here.", "Bold, italic, and links should all be processed")
        #expect(!resultString.contains("<"), "No HTML tags should remain")

        // Verify the link is detected and has URL attribute
        let linkRange = resultString.range(of: "bold and italic link")!
        let start = result.characters.index(result.characters.startIndex, offsetBy: resultString.distance(from: resultString.startIndex, to: linkRange.lowerBound))
        let end = result.characters.index(result.characters.startIndex, offsetBy: resultString.distance(from: resultString.startIndex, to: linkRange.upperBound))
        let linkAttributes = result[start ..< end]
        #expect(linkAttributes.link != nil, "Link text should have URL attribute")
    }

    @Test("Combined formatting handles formatting within paragraphs")
    func formattingInParagraphs() {
        let input = "<p>First paragraph with <b>bold</b> text.</p><p>Second paragraph with <i>italic</i> text.</p>"
        let result = CommentHTMLParser.parseHTMLText(input)
        let resultString = String(result.characters)
        #expect(resultString.contains("bold"), "Bold text should be preserved in paragraphs")
        #expect(resultString.contains("italic"), "Italic text should be preserved in paragraphs")
        #expect(resultString.contains("\n\n"), "Paragraph spacing should be maintained")
        #expect(!resultString.contains("<"), "No HTML tags should remain")
    }

    // MARK: - Formatting Edge Cases

    @Test("Formatting edge cases handle empty bold tags")
    func emptyBoldTag() {
        let input = "Text with <b></b> empty bold tag."
        let result = CommentHTMLParser.parseHTMLText(input)
        let resultString = String(result.characters)
        #expect(resultString == "Text with empty bold tag.", "Empty bold tags should be removed without affecting content")
    }

    @Test("Formatting edge cases handle empty italic tags")
    func emptyItalicTag() {
        let input = "Text with <i></i> empty italic tag."
        let result = CommentHTMLParser.parseHTMLText(input)
        let resultString = String(result.characters)
        #expect(resultString == "Text with empty italic tag.", "Empty italic tags should be removed without affecting content")
    }

    @Test("Formatting edge cases handle malformed bold tags")
    func malformedBoldTag() {
        let input = "Text with <b>unclosed bold tag."
        let result = CommentHTMLParser.parseHTMLText(input)
        let resultString = String(result.characters)
        #expect(resultString.contains("unclosed bold tag"), "Malformed bold tags should not break parsing")
    }

    @Test("Formatting edge cases handle malformed italic tags")
    func malformedItalicTag() {
        let input = "Text with <i>unclosed italic tag."
        let result = CommentHTMLParser.parseHTMLText(input)
        let resultString = String(result.characters)
        #expect(resultString.contains("unclosed italic tag"), "Malformed italic tags should not break parsing")
    }

    @Test("Formatting edge cases handle bold and italic with HTML entities")
    func formattingWithEntities() {
        let input = "Code: <b>if (x &lt; y)</b> and <i>result &amp;&amp; true</i>"
        let result = CommentHTMLParser.parseHTMLText(input)
        let resultString = String(result.characters)
        #expect(resultString.contains("if (x < y)"), "HTML entities in bold text should be decoded")
        #expect(resultString.contains("result && true"), "HTML entities in italic text should be decoded")
    }

    // MARK: - Code Block Tests

    @Test("Code block parsing handles basic pre/code blocks")
    func basicCodeBlockParsing() {
        let input = "Here is some code: <pre><code>function hello() {\n  return \"world\";\n}</code></pre> And more text."
        let result = CommentHTMLParser.parseHTMLText(input)
        let resultString = String(result.characters)
        #expect(resultString.contains("function hello()"), "Code block content should be preserved")
        #expect(resultString.contains("return \"world\""), "Code block content should include nested lines")
        #expect(!resultString.contains("<pre>"), "Pre tags should be removed")
        #expect(!resultString.contains("<code>"), "Code tags should be removed")
        // Check that there is paragraph spacing (double newlines) somewhere before the code
        #expect(resultString.contains("\n\nfunction hello()"), "Code blocks should have paragraph spacing before them")
        // The text after might not have spacing if it's considered part of the same block
        #expect(resultString.contains("And more text"), "Text after code block should be preserved")
    }

    @Test("Code block parsing handles HTML entities in code")
    func codeBlockWithHTMLEntities() {
        let input = "<pre><code>if (x &lt; y &amp;&amp; z &gt; w) {\n  return &quot;success&quot;;\n}</code></pre>"
        let result = CommentHTMLParser.parseHTMLText(input)
        let resultString = String(result.characters)
        #expect(resultString.contains("if (x < y && z > w)"), "HTML entities in code blocks should be decoded")
        #expect(resultString.contains("return \"success\""), "Quoted strings in code blocks should be decoded")
    }

    @Test("Code block parsing handles multiple code blocks")
    func multipleCodeBlocks() {
        let input = "First block: <pre><code>const a = 1;</code></pre> Second block: <pre><code>const b = 2;</code></pre>"
        let result = CommentHTMLParser.parseHTMLText(input)
        let resultString = String(result.characters)
        #expect(resultString.contains("const a = 1"), "First code block should be preserved")
        #expect(resultString.contains("const b = 2"), "Second code block should be preserved")
    }

    @Test("Inline code parsing handles basic inline code")
    func basicInlineCodeParsing() {
        let input = "Use the <code>getData()</code> function to retrieve data."
        let result = CommentHTMLParser.parseHTMLText(input)
        let resultString = String(result.characters)
        #expect(resultString.contains("getData()"), "Inline code content should be preserved")
        #expect(!resultString.contains("<code>"), "Code tags should be removed")
    }

    @Test("Inline code parsing handles HTML entities in inline code")
    func inlineCodeWithHTMLEntities() {
        let input = "Check if <code>x &lt; y &amp;&amp; z &gt; w</code> is true."
        let result = CommentHTMLParser.parseHTMLText(input)
        let resultString = String(result.characters)
        #expect(resultString.contains("x < y && z > w"), "HTML entities in inline code should be decoded")
    }

    @Test("Mixed code formatting handles code blocks and inline code together")
    func mixedCodeFormatting() {
        let input = "Use <code>foo()</code> like this:\n<pre><code>function foo() {\n  return bar();\n}</code></pre>\nThen call <code>bar()</code>."
        let result = CommentHTMLParser.parseHTMLText(input)
        let resultString = String(result.characters)
        #expect(resultString.contains("foo()"), "First inline code should be preserved")
        #expect(resultString.contains("function foo()"), "Code block should be preserved")
        #expect(resultString.contains("bar()"), "Last inline code should be preserved")
    }

    @Test("Code with other formatting handles bold, italic, and code together")
    func codeWithOtherFormatting() {
        let input = "This is <b>bold</b>, <i>italic</i>, and <code>code</code> text."
        let result = CommentHTMLParser.parseHTMLText(input)
        let resultString = String(result.characters)
        #expect(resultString == "This is bold, italic, and code text.", "All formatting should be processed correctly")
    }

    @Test("Code blocks in paragraphs")
    func codeBlocksInParagraphs() {
        let input = "<p>First paragraph with text.</p><p><pre><code>const example = true;</code></pre></p><p>Last paragraph.</p>"
        let result = CommentHTMLParser.parseHTMLText(input)
        let resultString = String(result.characters)
        #expect(resultString.contains("const example = true"), "Code block in paragraph should be preserved")
        #expect(resultString.contains("First paragraph"), "First paragraph should be preserved")
        #expect(resultString.contains("Last paragraph"), "Last paragraph should be preserved")
    }

    @Test("Code block paragraph spacing")
    func codeBlockParagraphSpacing() {
        let input = "Text before code block.<pre><code>const code = 123;</code></pre>Text after code block."
        let result = CommentHTMLParser.parseHTMLText(input)
        let resultString = String(result.characters)
        // Should have paragraph spacing (double newline) before code block
        #expect(resultString.contains("block.\n\nconst code"), "Code block should have paragraph spacing before it")
        // Should have single line spacing after code block
        #expect(resultString.contains("123;\nText after"), "Code block should have single line spacing after it")
        // Should NOT have double newlines after the code
        #expect(!resultString.contains("123;\n\nText"), "Should not have double newlines after code block")
    }

    // MARK: - String Extension Tests

    @Test("String extension strippingHTML removes HTML and decodes entities")
    func stringExtensionStrippingHTML() {
        let input = "<p>Hello &amp; <a href=\"https://example.com\">world</a>!</p>"
        let result = input.strippingHTML()
        let expected = "Hello & world!"
        #expect(result == expected, "String extension should strip HTML and decode entities")
    }

    @Test("String extension strippingHTML trims whitespace correctly")
    func stringExtensionStrippingHTMLWithWhitespace() {
        let input = "  <p>  Content  </p>  "
        let result = input.strippingHTML()
        #expect(result == "Content", "String extension should trim whitespace")
    }

    @Test("String extension strippingHTML removes formatting tags")
    func stringExtensionStrippingHTMLWithFormatting() {
        let input = "<p>Text with <b>bold</b> and <i>italic</i> formatting.</p>"
        let result = input.strippingHTML()
        let expected = "Text with bold and italic formatting."
        #expect(result == expected, "String extension should strip formatting tags while preserving text")
    }
}
