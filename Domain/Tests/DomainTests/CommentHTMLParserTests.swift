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
