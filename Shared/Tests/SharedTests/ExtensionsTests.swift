//
//  ExtensionsTests.swift
//  SharedTests
//
//  Copyright © 2025 Weiran Zhang. All rights reserved.
//

import Testing
@testable import Shared
@testable import Domain

@Suite("Extensions Tests")
struct ExtensionsTests {
    
    // MARK: - PostType Extensions Tests
    
    @Suite("PostType Extensions")
    struct PostTypeExtensionsTests {
        
        @Test("PostType displayName returns correct values")
        func testPostTypeDisplayName() {
            #expect(PostType.news.displayName == "Top")
            #expect(PostType.ask.displayName == "Ask")
            #expect(PostType.show.displayName == "Show")
            #expect(PostType.jobs.displayName == "Jobs")
            #expect(PostType.newest.displayName == "New")
            #expect(PostType.best.displayName == "Best")
            #expect(PostType.active.displayName == "Active")
        }
        
        @Test("PostType iconName returns valid SF Symbol names")
        func testPostTypeIconName() {
            #expect(PostType.news.iconName == "flame")
            #expect(PostType.ask.iconName == "bubble.left.and.bubble.right")
            #expect(PostType.show.iconName == "eye")
            #expect(PostType.jobs.iconName == "briefcase")
            #expect(PostType.newest.iconName == "clock")
            #expect(PostType.best.iconName == "star")
            #expect(PostType.active.iconName == "bolt")
        }
        
        @Test("All PostType cases have displayName")
        func testAllPostTypesHaveDisplayName() {
            let allCases: [PostType] = [.news, .ask, .show, .jobs, .newest, .best, .active]
            
            for postType in allCases {
                #expect(postType.displayName.isEmpty == false)
                #expect(postType.iconName.isEmpty == false)
            }
        }
    }
    
    // MARK: - String Extensions Tests
    
    @Suite("String Extensions")
    struct StringExtensionsTests {
        
        @Test("strippingHTML removes basic HTML tags")
        func testStrippingHTMLBasicTags() {
            let htmlString = "<p>Hello <b>world</b>!</p>"
            let expected = "Hello world!"
            
            #expect(htmlString.strippingHTML() == expected)
        }
        
        @Test("strippingHTML removes nested HTML tags")
        func testStrippingHTMLNestedTags() {
            let htmlString = "<div><p>Hello <strong><em>world</em></strong>!</p></div>"
            let expected = "Hello world!"
            
            #expect(htmlString.strippingHTML() == expected)
        }
        
        @Test("strippingHTML handles self-closing tags")
        func testStrippingHTMLSelfClosingTags() {
            let htmlString = "Line 1<br/>Line 2<hr/>"
            let expected = "Line 1Line 2"
            
            #expect(htmlString.strippingHTML() == expected)
        }
        
        @Test("strippingHTML handles tags with attributes")
        func testStrippingHTMLTagsWithAttributes() {
            let htmlString = "<p class=\"text\">Hello</p> <a href=\"https://example.com\">world</a>!"
            let expected = "Hello world!"
            
            #expect(htmlString.strippingHTML() == expected)
        }
        
        @Test("strippingHTML trims whitespace")
        func testStrippingHTMLTrimsWhitespace() {
            let htmlString = "  <p>  Hello world  </p>  "
            let expected = "Hello world"
            
            #expect(htmlString.strippingHTML() == expected)
        }
        
        @Test("strippingHTML handles empty string")
        func testStrippingHTMLEmptyString() {
            let htmlString = ""
            let expected = ""
            
            #expect(htmlString.strippingHTML() == expected)
        }
        
        @Test("strippingHTML handles string without HTML")
        func testStrippingHTMLNoHTML() {
            let htmlString = "Hello world!"
            let expected = "Hello world!"
            
            #expect(htmlString.strippingHTML() == expected)
        }
        
        @Test("strippingHTML handles only HTML tags")
        func testStrippingHTMLOnlyTags() {
            let htmlString = "<div></div><p></p><br/>"
            let expected = ""
            
            #expect(htmlString.strippingHTML() == expected)
        }
        
        @Test("strippingHTML handles malformed HTML")
        func testStrippingHTMLMalformed() {
            let htmlString = "Hello <b world!"
            let expected = "Hello <b world!"
            
            #expect(htmlString.strippingHTML() == expected)
        }
        
        @Test("strippingHTML handles newlines and tabs")
        func testStrippingHTMLWhitespaceChars() {
            let htmlString = "<p>Hello\n\t</p><p>world</p>"
            let expected = "Hello\nworld"
            
            #expect(htmlString.strippingHTML() == expected)
        }
        
        @Test("strippingHTML handles special characters in content")
        func testStrippingHTMLSpecialCharacters() {
            let htmlString = "<p>&lt;Hello&gt; &amp; &quot;world&quot;</p>"
            let expected = "&lt;Hello&gt; &amp; &quot;world&quot;"
            
            #expect(htmlString.strippingHTML() == expected)
        }
        
        @Test("strippingHTML handles complex real-world HTML")
        func testStrippingHTMLComplexExample() {
            let htmlString = """
            <div class="container">
                <h1>Title</h1>
                <p>This is a <strong>bold</strong> statement with a 
                <a href="https://example.com">link</a>.</p>
                <ul>
                    <li>Item 1</li>
                    <li>Item 2</li>
                </ul>
            </div>
            """
            
            let result = htmlString.strippingHTML()
            
            // Should contain the text content but no HTML tags
            #expect(result.contains("Title"))
            #expect(result.contains("This is a bold statement"))
            #expect(result.contains("link"))
            #expect(result.contains("Item 1"))
            #expect(result.contains("Item 2"))
            
            // Should not contain any HTML tags
            #expect(result.contains("<") == false)
            #expect(result.contains(">") == false)
        }
    }
}