@testable import Domain
import Foundation
import Testing

@Suite("Comment HTML parser contracts")
struct CommentHTMLParserTests {
    @Test("Decodes common named and numeric entities before parsing markup")
    func decodesEntitiesBeforeMarkup() {
        let html = "<p>Tom &amp; <b>Jerry</b>: &quot;ok&quot; &#39; ✓</p>"
        let result = String(CommentHTMLParser.parseHTMLText(html).characters)
        #expect(result == "Tom & Jerry: \"ok\" ' ✓")
    }

    @Test("Preserves paragraph boundaries while normalizing incidental newlines")
    func paragraphBoundaries() {
        let result = String(CommentHTMLParser.parseHTMLText("lead\ntext<p>first</p><p>second\nline</p>tail").characters)
        #expect(result == "lead text\n\nfirst\n\nsecond line\n\ntail")
    }

    @Test("Resolves relative Hacker News links and preserves link attributes")
    func relativeLinkAttribute() throws {
        let result = CommentHTMLParser.parseHTMLText("<a href='/item?id=123'>story</a>")
        let range = try #require(result.range(of: "story"))
        #expect(result[range].link?.absoluteString == "https://news.ycombinator.com/item?id=123")

        let noSlash = CommentHTMLParser.parseHTMLText("<a href='item?id=456'>comment</a>")
        let noSlashRange = try #require(noSlash.range(of: "comment"))
        #expect(noSlash[noSlashRange].link?.absoluteString == "https://news.ycombinator.com/item?id=456")
    }

    @Test("Preserves two links and the text between them")
    func repeatedLinks() throws {
        let html = "<a href='https://one.example'>first</a> between <a href='https://two.example'>second</a> end"
        let result = CommentHTMLParser.parseHTMLText(html)
        #expect(String(result.characters) == "first between second end")
        let first = try #require(result.range(of: "first"))
        let second = try #require(result.range(of: "second"))
        #expect(result[first].link?.absoluteString == "https://one.example")
        #expect(result[second].link?.absoluteString == "https://two.example")
    }

    @Test("Applies emphasis to bold and italic text")
    func emphasisAttributes() throws {
        let result = CommentHTMLParser.parseHTMLText("<b>strong</b> and <i>emphasis</i>")
        let boldRange = try #require(result.range(of: "strong"))
        let italicRange = try #require(result.range(of: "emphasis"))
        #expect(result[boldRange].inlinePresentationIntent == .stronglyEmphasized)
        #expect(result[italicRange].inlinePresentationIntent == .emphasized)
    }

    @Test("Marks inline code while decoding entities")
    func inlineCodeAttribute() throws {
        let result = CommentHTMLParser.parseHTMLText("Use <code>x &lt; y</code>")
        let range = try #require(result.range(of: "x < y"))
        #expect(result[range].inlinePresentationIntent == .code)
    }

    @Test("Keeps code literal and does not turn code links into active links")
    func codeRemainsLiteral() throws {
        let html = "<pre><code>&lt;a href='https://example.com'&gt;link&lt;/a&gt;\n✓</code></pre>"
        let result = CommentHTMLParser.parseHTMLText(html)
        #expect(String(result.characters).contains("<a href='https://example.com'>link</a>"))
        let range = try #require(result.range(of: "link"))
        #expect(result[range].link == nil)
        #expect(result[range].inlinePresentationIntent == .code)
    }

    @Test("Preserves repeated code blocks and intervening text")
    func repeatedCodeBlocks() {
        let html = "before <pre><code>first()</code></pre> between <pre><code>second()</code></pre> after"
        let result = String(CommentHTMLParser.parseHTMLText(html).characters)
        #expect(result.contains("first()"))
        #expect(result.contains("between"))
        #expect(result.contains("second()"))
        #expect(result.contains("after"))
    }

    @Test("Plain text conversion removes markup and trims the result")
    func plainText() {
        #expect(CommentHTMLParser.plainText(fromHTML: "  <p>Hello &amp; <b>world</b></p>  ") == "Hello & world")
    }

    @Test("Empty and malformed link input remains safe plain text")
    func emptyAndMalformedInput() {
        #expect(String(CommentHTMLParser.parseHTMLText("").characters).isEmpty)
        #expect(String(CommentHTMLParser.parseHTMLText("<a>plain &amp; safe</a>").characters) == "plain & safe")
    }
}

extension CommentHTMLParserTests {
    @Test("HTML entity decoding supports numeric scalars and rejects invalid values")
    func hTMLEntityDecodingNumericScalars() {
        let input = "caf&#233; &#x1F642; &#x110000; &#xD800;"
        let result = CommentHTMLParser.decodeHTMLEntities(input)
        #expect(result == "café 🙂 &#x110000; &#xD800;", "Valid numeric entities should decode while invalid scalars remain literal")
    }

    @Test("HTML entity decoding is single pass")
    func hTMLEntityDecodingSinglePass() {
        #expect(CommentHTMLParser.decodeHTMLEntities("&amp;lt;") == "&lt;", "Entity decoding must not recursively decode its own output")
    }

    @Test("HTML entity decoding does not swallow later entities after plain ampersands")
    func hTMLEntityDecodingHandlesPlainAmpersandText() {
        #expect(CommentHTMLParser.decodeHTMLEntities("AT&T &amp; Co") == "AT&T & Co",
                "Malformed ampersands must not prevent subsequent entities from decoding")
    }

    @Test("Decoded whitespace is normalized after entity decoding")
    func decodedWhitespaceIsNormalizedAfterEntityDecoding() {
        #expect(String(CommentHTMLParser.parseHTMLText("A&nbsp;&nbsp;B").characters) == "A B",
                "Adjacent nbsp entities should collapse to one display space")
        #expect(String(CommentHTMLParser.parseHTMLText("A &nbsp; B").characters) == "A B",
                "Whitespace surrounding nbsp should retain the pre-task normalized display form")
    }

    @Test("Decoded whitespace is normalized in formatted and linked text")
    func decodedWhitespaceIsNormalizedInFormattedAndLinkedText() {
        let formatted = CommentHTMLParser.parseHTMLText("A <b>B&nbsp;&nbsp;C&#10;D</b> E")
        #expect(String(formatted.characters) == "A B C D E",
                "Formatted non-paragraph text should collapse whitespace decoded from entities")

        let linked = CommentHTMLParser.parseHTMLText("<a href=\"https://example.com\">A&nbsp;&nbsp;B&#10;C</a>")
        #expect(String(linked.characters) == "A B C",
                "Link text should collapse whitespace decoded from entities")
    }

    @Test("Link URL attributes decode entities after raw extraction")
    func linkURLAttributeDecodesEntitiesAfterRawExtraction() {
        let result = CommentHTMLParser.parseHTMLText("<a href=\"https://example.com/?a=1&amp;b=2\">query</a>")
        let text = String(result.characters)
        let range = text.range(of: "query")!
        let start = result.characters.index(result.characters.startIndex, offsetBy: text.distance(from: text.startIndex, to: range.lowerBound))
        let end = result.characters.index(result.characters.startIndex, offsetBy: text.distance(from: text.startIndex, to: range.upperBound))
        #expect(result[start ..< end].link?.absoluteString == "https://example.com/?a=1&b=2",
                "URL entities should decode once after the raw href value is extracted")
    }

    @Test("Escaped markup remains literal text")
    func escapedMarkupRemainsLiteral() {
        let result = CommentHTMLParser.parseHTMLText("&lt;b&gt;literal&lt;/b&gt;")
        #expect(String(result.characters) == "<b>literal</b>", "Escaped tags must not become formatting tags")
        let fullRange = result.startIndex ..< result.endIndex
        #expect(result[fullRange].inlinePresentationIntent == nil,
                "Escaped literal markup must not receive formatting attributes")
    }

    // Issue #378: escaped tag names must survive both display and copy parsing,
    // including HN's paragraphs without closing tags and real emphasis nearby.
    @Test("Preserves the literal HTML tags reported in issue 378", arguments: [
        "style", "table", "figure", "aside", "video", "audio", "iframes"
    ])
    func reportedHTMLTagsRemainLiteral(tag: String) throws {
        let html = "RSS elements:<p>Use &lt;\(tag)&gt; with <i>care</i>."
        let result = CommentHTMLParser.parseHTMLText(html)
        #expect(String(result.characters) == "RSS elements:\n\nUse <\(tag)> with care.")
        let literalRange = try #require(result.range(of: "<\(tag)>"))
        #expect(result[literalRange].inlinePresentationIntent == nil)
        let emphasisRange = try #require(result.range(of: "care"))
        #expect(result[emphasisRange].inlinePresentationIntent == .emphasized)
        #expect(CommentHTMLParser.plainText(fromHTML: html).contains("<\(tag)>"))
    }

    @Test("Nested bold and code emits content once")
    func nestedBoldAndCodeEmitsContentOnce() {
        let result = CommentHTMLParser.parseHTMLText("<b><code>x</code></b>")
        #expect(String(result.characters) == "x", "Nested formatting must not duplicate text")
    }

    @Test("Paragraph parsing treats an opening p tag as a separator when closing tag is absent")
    func paragraphSeparatorWithoutClosingTag() {
        let result = CommentHTMLParser.parseHTMLText("First paragraph.<p>Second paragraph.")
        #expect(String(result.characters) == "First paragraph.\n\nSecond paragraph.", "Opening p tags should delimit paragraphs even without a closing tag")
    }

    @Test("Paragraph parsing trims entity whitespace around empty outer chunks")
    func paragraphTrimsEntityWhitespaceAroundEmptyChunks() {
        #expect(String(CommentHTMLParser.parseHTMLText("&nbsp;<p>B").characters) == "B",
                "Whitespace-only entity prefixes should not create a blank paragraph")
        #expect(String(CommentHTMLParser.parseHTMLText("<p>B</p>&nbsp;").characters) == "B",
                "Whitespace-only entity suffixes should not create a blank paragraph")
    }

    @Test("Paragraph parsing trims entity whitespace around nonempty outer chunks")
    func paragraphTrimsEntityWhitespaceAroundNonemptyChunks() {
        #expect(String(CommentHTMLParser.parseHTMLText("&nbsp;A<p>B").characters) == "A\n\nB",
                "Entity whitespace must not lead text before a paragraph")
        #expect(String(CommentHTMLParser.parseHTMLText("<p>B</p>A&nbsp;").characters) == "B\n\nA",
                "Entity whitespace must not trail text after a paragraph")
    }

}
