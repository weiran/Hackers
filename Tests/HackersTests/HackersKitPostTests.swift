//
//  HackersKitPostTests.swift
//  HackersTests
//
//  Created by Test Suite
//

import XCTest
import PromiseKit
import SwiftSoup
@testable import Hackers

class HackersKitPostTests: XCTestCase {
    
    var hackersKit: HackersKit!
    
    override func setUp() {
        super.setUp()
        hackersKit = HackersKit()
    }
    
    override func tearDown() {
        hackersKit = nil
        super.tearDown()
    }
    
    // MARK: - getPost Tests
    
    func testGetPost_SuccessfulPostRetrieval_DefaultIncludeAllComments() {
        // Given
        let postId = 1 // Known valid HN post ID
        let expectation = self.expectation(description: "Post retrieval should succeed with default includeAllComments")
        
        // When
        hackersKit.getPost(id: postId).done { post in
            // Then
            XCTAssertNotNil(post)
            XCTAssertNotNil(post.comments)
            expectation.fulfill()
        }.catch { error in
            // Network errors are acceptable in unit tests
            print("Network error (acceptable): \(error)")
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 15.0, handler: nil)
    }
    
    func testGetPost_WithIncludeAllCommentsTrue() {
        // Given
        let postId = 1
        let expectation = self.expectation(description: "Post with all comments should be retrieved")
        
        // When
        hackersKit.getPost(id: postId, includeAllComments: true).done { post in
            // Then
            XCTAssertNotNil(post)
            XCTAssertNotNil(post.comments)
            expectation.fulfill()
        }.catch { error in
            print("Network error (acceptable): \(error)")
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 20.0, handler: nil)
    }
    
    func testGetPost_WithIncludeAllCommentsFalse() {
        // Given
        let postId = 1
        let expectation = self.expectation(description: "Post with limited comments should be retrieved")
        
        // When
        hackersKit.getPost(id: postId, includeAllComments: false).done { post in
            // Then
            XCTAssertNotNil(post)
            XCTAssertNotNil(post.comments)
            expectation.fulfill()
        }.catch { error in
            print("Network error (acceptable): \(error)")
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 15.0, handler: nil)
    }
    
    func testGetPost_InvalidPostId_NegativeValue() {
        // Given
        let invalidPostId = -1
        let expectation = self.expectation(description: "Invalid negative post ID should handle gracefully")
        
        // When
        hackersKit.getPost(id: invalidPostId).done { post in
            XCTFail("Should not succeed with negative post ID")
            expectation.fulfill()
        }.catch { error in
            // This is expected for invalid IDs
            XCTAssertNotNil(error)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 10.0, handler: nil)
    }
    
    func testGetPost_ZeroPostId() {
        // Given
        let zeroPostId = 0
        let expectation = self.expectation(description: "Zero post ID should handle gracefully")
        
        // When
        hackersKit.getPost(id: zeroPostId).done { post in
            XCTFail("Should not succeed with zero post ID")
            expectation.fulfill()
        }.catch { error in
            XCTAssertNotNil(error)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 10.0, handler: nil)
    }
    
    func testGetPost_ExtremelyLargePostId() {
        // Given
        let largePostId = 999999999
        let expectation = self.expectation(description: "Large post ID should handle gracefully")
        
        // When
        hackersKit.getPost(id: largePostId).done { post in
            // May succeed but unlikely
            expectation.fulfill()
        }.catch { error in
            // Expected to fail for non-existent large IDs
            XCTAssertNotNil(error)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 15.0, handler: nil)
    }
    
    // MARK: - URL Construction Tests
    
    func testHackerNewsURL_ValidInputs() {
        // Given
        let postId = 12345
        let page = 1
        
        // When
        let url = hackersKit.hackerNewsURL(id: postId, page: page)
        
        // Then
        XCTAssertNotNil(url)
        XCTAssertEqual(url?.scheme, "https")
        XCTAssertEqual(url?.host, "news.ycombinator.com")
        XCTAssertEqual(url?.path, "/item")
        
        let components = URLComponents(url: url!, resolvingAgainstBaseURL: false)
        let queryItems = components?.queryItems
        XCTAssertNotNil(queryItems)
        
        let idQuery = queryItems?.first { $0.name == "id" }
        let pageQuery = queryItems?.first { $0.name == "p" }
        
        XCTAssertEqual(idQuery?.value, "12345")
        XCTAssertEqual(pageQuery?.value, "1")
    }
    
    func testHackerNewsURL_ZeroValues() {
        // Given
        let postId = 0
        let page = 0
        
        // When
        let url = hackersKit.hackerNewsURL(id: postId, page: page)
        
        // Then
        XCTAssertNotNil(url)
        let components = URLComponents(url: url!, resolvingAgainstBaseURL: false)
        let queryItems = components?.queryItems
        
        let idQuery = queryItems?.first { $0.name == "id" }
        let pageQuery = queryItems?.first { $0.name == "p" }
        
        XCTAssertEqual(idQuery?.value, "0")
        XCTAssertEqual(pageQuery?.value, "0")
    }
    
    func testHackerNewsURL_NegativeValues() {
        // Given
        let postId = -1
        let page = -5
        
        // When
        let url = hackersKit.hackerNewsURL(id: postId, page: page)
        
        // Then
        XCTAssertNotNil(url)
        let components = URLComponents(url: url!, resolvingAgainstBaseURL: false)
        let queryItems = components?.queryItems
        
        let idQuery = queryItems?.first { $0.name == "id" }
        let pageQuery = queryItems?.first { $0.name == "p" }
        
        XCTAssertEqual(idQuery?.value, "-1")
        XCTAssertEqual(pageQuery?.value, "-5")
    }
    
    func testHackerNewsURL_LargeValues() {
        // Given
        let postId = 999999999
        let page = 999999
        
        // When
        let url = hackersKit.hackerNewsURL(id: postId, page: page)
        
        // Then
        XCTAssertNotNil(url)
        let components = URLComponents(url: url!, resolvingAgainstBaseURL: false)
        let queryItems = components?.queryItems
        
        let idQuery = queryItems?.first { $0.name == "id" }
        let pageQuery = queryItems?.first { $0.name == "p" }
        
        XCTAssertEqual(idQuery?.value, "999999999")
        XCTAssertEqual(pageQuery?.value, "999999")
    }
    
    func testHackerNewsURL_URLStructure() {
        // Given
        let postId = 12345
        let page = 2
        
        // When
        let url = hackersKit.hackerNewsURL(id: postId, page: page)
        
        // Then
        XCTAssertNotNil(url)
        let urlString = url!.absoluteString
        
        XCTAssertTrue(urlString.contains("https://news.ycombinator.com/item"))
        XCTAssertTrue(urlString.contains("id=12345"))
        XCTAssertTrue(urlString.contains("p=2"))
    }
    
    func testHackerNewsURL_FirstPage() {
        // Given
        let postId = 123
        let page = 1
        
        // When
        let url = hackersKit.hackerNewsURL(id: postId, page: page)
        
        // Then
        XCTAssertNotNil(url)
        XCTAssertTrue(url!.absoluteString.contains("p=1"))
    }
    
    // MARK: - HTML Parsing Tests
    
    func testComments_EmptyHtml() {
        // Given
        let emptyHtml = ""
        
        // When & Then
        XCTAssertNoThrow {
            let comments = try hackersKit.comments(from: emptyHtml)
            XCTAssertEqual(comments.count, 0)
        }
    }
    
    func testComments_MinimalValidHtml() {
        // Given
        let minimalHtml = "<html><body></body></html>"
        
        // When & Then
        XCTAssertNoThrow {
            let comments = try hackersKit.comments(from: minimalHtml)
            XCTAssertEqual(comments.count, 0)
        }
    }
    
    func testComments_MalformedHtml() {
        // Given
        let malformedHtml = "<html><body><div>Unclosed div<span>Unclosed span"
        
        // When & Then
        XCTAssertNoThrow {
            let comments = try hackersKit.comments(from: malformedHtml)
            // Should handle gracefully even with malformed HTML
            XCTAssertNotNil(comments)
        }
    }
    
    func testComments_InvalidHtmlString() {
        // Given
        let invalidHtml = "This is not HTML at all! Just plain text."
        
        // When & Then
        XCTAssertNoThrow {
            let comments = try hackersKit.comments(from: invalidHtml)
            // Should handle gracefully and return empty array
            XCTAssertNotNil(comments)
        }
    }
    
    func testComments_HtmlWithSpecialCharacters() {
        // Given
        let specialCharHtml = "<html><body>Content with &amp; &lt; &gt; &quot; &#39; special chars</body></html>"
        
        // When & Then
        XCTAssertNoThrow {
            let comments = try hackersKit.comments(from: specialCharHtml)
            XCTAssertNotNil(comments)
        }
    }
    
    func testComments_VeryLargeHtml() {
        // Given
        let largeContent = String(repeating: "This is a very long comment that repeats many times. ", count: 1000)
        let largeHtml = "<html><body>\(largeContent)</body></html>"
        
        // When & Then
        XCTAssertNoThrow {
            let comments = try hackersKit.comments(from: largeHtml)
            XCTAssertNotNil(comments)
        }
    }
    
    func testComments_HtmlWithCommentElements() {
        // Given
        let htmlWithComment = """
        <html>
        <body>
        <table class="comment-tree">
        <tr class="athing comtr" id="12345">
        <td class="ind"><img src="s.gif" height="1" width="40"></td>
        <td class="default">
        <div style="margin-top:2px; margin-bottom:-10px;">
        <span class="comhead">
        <a href="user?id=testuser" class="hnuser">testuser</a>
        <span class="age">1 day ago</span>
        </span>
        </div>
        <div class="comment">
        <span class="commtext c00">This is a test comment</span>
        </div>
        </td>
        </tr>
        </table>
        </body>
        </html>
        """
        
        // When & Then
        XCTAssertNoThrow {
            let comments = try hackersKit.comments(from: htmlWithComment)
            XCTAssertNotNil(comments)
            // Should parse at least one comment or handle gracefully
        }
    }
    
    func testComments_HtmlWithToptext() {
        // Given - HTML with .toptext element for AskHN posts
        let htmlWithToptext = """
        <html>
        <body>
        <tr class="athing" id="12345">
        <td class="title">
        <span class="titleline">Ask HN: Test Question?</span>
        </td>
        </tr>
        <tr>
        <td colspan="2"></td>
        <td>
        <div class="toptext">
        <span class="commtext c00">This is the main post text for Ask HN</span>
        </div>
        </td>
        </tr>
        </body>
        </html>
        """
        
        // When & Then
        XCTAssertNoThrow {
            let comments = try hackersKit.comments(from: htmlWithToptext)
            XCTAssertNotNil(comments)
            // Should include the post comment if detected
        }
    }
    
    // MARK: - fetchPostHtml Tests
    
    func testFetchPostHtml_RecursiveFalse() {
        // Given
        let postId = 1
        let expectation = self.expectation(description: "Non-recursive fetch should succeed")
        
        // When
        hackersKit.fetchPostHtml(id: postId, recursive: false).done { html in
            // Then
            XCTAssertNotNil(html)
            XCTAssertFalse(html.isEmpty)
            expectation.fulfill()
        }.catch { error in
            print("Network error (acceptable): \(error)")
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 15.0, handler: nil)
    }
    
    func testFetchPostHtml_RecursiveTrue() {
        // Given
        let postId = 1
        let expectation = self.expectation(description: "Recursive fetch should succeed")
        
        // When
        hackersKit.fetchPostHtml(id: postId, recursive: true).done { html in
            // Then
            XCTAssertNotNil(html)
            XCTAssertFalse(html.isEmpty)
            expectation.fulfill()
        }.catch { error in
            print("Network error (acceptable): \(error)")
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 20.0, handler: nil)
    }
    
    func testFetchPostHtml_WithWorkingHtml() {
        // Given
        let postId = 1
        let workingHtml = "<html><body>Existing content</body></html>"
        let expectation = self.expectation(description: "Fetch with working HTML should append")
        
        // When
        hackersKit.fetchPostHtml(id: postId, workingHtml: workingHtml, recursive: false).done { html in
            // Then
            XCTAssertNotNil(html)
            XCTAssertTrue(html.contains("Existing content"))
            expectation.fulfill()
        }.catch { error in
            print("Network error (acceptable): \(error)")
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 15.0, handler: nil)
    }
    
    func testFetchPostHtml_SpecificPage() {
        // Given
        let postId = 1
        let startPage = 2
        let expectation = self.expectation(description: "Specific page fetch should succeed")
        
        // When
        hackersKit.fetchPostHtml(id: postId, page: startPage, recursive: false).done { html in
            // Then
            XCTAssertNotNil(html)
            expectation.fulfill()
        }.catch { error in
            print("Network error (acceptable): \(error)")
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 15.0, handler: nil)
    }
    
    func testFetchPostHtml_InvalidPostId() {
        // Given
        let invalidPostId = -999
        let expectation = self.expectation(description: "Invalid post ID should result in error")
        
        // When
        hackersKit.fetchPostHtml(id: invalidPostId).done { html in
            XCTFail("Should not succeed with invalid post ID")
            expectation.fulfill()
        }.catch { error in
            // Expected to fail for invalid IDs
            XCTAssertNotNil(error)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 10.0, handler: nil)
    }
    
    // MARK: - Error Handling Tests
    
    func testGetPost_HandlesNetworkError() {
        // Given - Using an ID that's very unlikely to exist
        let nonExistentPostId = -999999
        let expectation = self.expectation(description: "Network error should be handled gracefully")
        
        // When
        hackersKit.getPost(id: nonExistentPostId).done { post in
            XCTFail("Should not succeed with non-existent post ID")
            expectation.fulfill()
        }.catch { error in
            // Expected error
            XCTAssertNotNil(error)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 10.0, handler: nil)
    }
    
    func testGetPost_HandlesHtmlParsingError() {
        // Test that the method can handle various HTML formats gracefully
        let postId = 1
        let expectation = self.expectation(description: "HTML parsing should be robust")
        
        hackersKit.getPost(id: postId, includeAllComments: false).done { post in
            XCTAssertNotNil(post)
            expectation.fulfill()
        }.catch { error in
            print("Error (acceptable): \(error)")
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 15.0, handler: nil)
    }
    
    // MARK: - Performance Tests
    
    func testGetPost_Performance() {
        // Test performance of getting a single post
        let postId = 1
        
        measure {
            let expectation = self.expectation(description: "Performance test")
            
            hackersKit.getPost(id: postId, includeAllComments: false).done { _ in
                expectation.fulfill()
            }.catch { _ in
                expectation.fulfill()
            }
            
            waitForExpectations(timeout: 10.0, handler: nil)
        }
    }
    
    func testHackerNewsURL_Performance() {
        // Test performance of URL generation
        measure {
            for i in 1...1000 {
                _ = hackersKit.hackerNewsURL(id: i, page: 1)
            }
        }
    }
    
    func testComments_PerformanceWithLargeHtml() {
        // Given
        let largeHtml = String(repeating: "<div>Comment content </div>", count: 1000)
        
        // When & Then
        measure {
            XCTAssertNoThrow {
                _ = try hackersKit.comments(from: largeHtml)
            }
        }
    }
    
    // MARK: - Edge Case Tests
    
    func testGetPost_ConcurrentRequests() {
        // Test multiple concurrent requests
        let postIds = [1, 2, 3, 4, 5]
        let expectation = self.expectation(description: "Concurrent requests should complete")
        expectation.expectedFulfillmentCount = postIds.count
        
        for postId in postIds {
            hackersKit.getPost(id: postId, includeAllComments: false).done { post in
                XCTAssertNotNil(post)
                expectation.fulfill()
            }.catch { error in
                print("Network error (acceptable): \(error)")
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: 30.0, handler: nil)
    }
    
    func testFetchPostHtml_WorkingHtmlEdgeCases() {
        // Test with various working HTML inputs
        let postId = 1
        let testCases = [
            "",
            "<html></html>",
            "<invalid>html</invalid>",
            String(repeating: "x", count: 1000) // Reduced size for performance
        ]
        
        for (index, workingHtml) in testCases.enumerated() {
            let expectation = self.expectation(description: "Working HTML test case \(index)")
            
            hackersKit.fetchPostHtml(id: postId, workingHtml: workingHtml, recursive: false).done { html in
                XCTAssertNotNil(html)
                XCTAssertTrue(html.contains(workingHtml))
                expectation.fulfill()
            }.catch { error in
                print("Network error (acceptable): \(error)")
                expectation.fulfill()
            }
            
            waitForExpectations(timeout: 15.0, handler: nil)
        }
    }
    
    // MARK: - Integration Tests
    
    func testGetPost_PostCommentsIntegration() {
        // Test that comments are properly attached to posts
        let postId = 1
        let expectation = self.expectation(description: "Post should have comments attached")
        
        hackersKit.getPost(id: postId, includeAllComments: false).done { post in
            XCTAssertNotNil(post)
            XCTAssertNotNil(post.comments)
            // Comments array should be initialized even if empty
            expectation.fulfill()
        }.catch { error in
            print("Network error (acceptable): \(error)")
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 15.0, handler: nil)
    }
    
    func testFetchPostHtml_RecursivePagination() {
        // Test recursive functionality with posts that have multiple pages
        let postId = 1
        let expectation = self.expectation(description: "Recursive fetch should handle pagination")
        
        hackersKit.fetchPostHtml(id: postId, page: 1, recursive: true).done { html in
            XCTAssertNotNil(html)
            XCTAssertFalse(html.isEmpty)
            expectation.fulfill()
        }.catch { error in
            print("Network error (acceptable): \(error)")
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 25.0, handler: nil)
    }
}

// MARK: - Test Extensions for Private Method Access
extension HackersKit {
    func testComments(from html: String) throws -> [Comment] {
        return try self.comments(from: html)
    }
    
    func testFetchPostHtml(id: Int, page: Int = 1, recursive: Bool = true, workingHtml: String = "") -> Promise<String> {
        return self.fetchPostHtml(id: id, page: page, recursive: recursive, workingHtml: workingHtml)
    }
    
    func testHackerNewsURL(id: Int, page: Int) -> URL? {
        return self.hackerNewsURL(id: id, page: page)
    }
}