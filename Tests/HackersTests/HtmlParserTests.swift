//
//  HtmlParserTests.swift
//  HackersTests
//
//  Created by Test Generator
//  Unit tests for HtmlParser functionality
//

import XCTest
import SwiftSoup
@testable import Hackers

class HtmlParserTests: XCTestCase {
    
    // MARK: - Test Data
    
    private let samplePostListHTML = """
    <table id="hnmain">
        <tr><td></td></tr>
        <tr><td></td></tr>
        <tr>
            <td>
                <table>
                    <tr class="athing" id="123">
                        <td>
                            <span class="titleline">
                                <a href="https://example.com">Sample Post Title</a>
                            </span>
                        </td>
                    </tr>
                    <tr>
                        <td class="subtext">
                            <span class="score" id="score_123">10 points</span>
                            by <a href="user?id=testuser" class="hnuser">testuser</a>
                            <span class="age" title="2023-01-01T12:00:00">2 hours ago</span>
                            | <a href="item?id=123">5 comments</a>
                        </td>
                    </tr>
                </table>
            </td>
        </tr>
    </table>
    """
    
    private let sampleSinglePostHTML = """
    <table id="hnmain">
        <tr><td></td></tr>
        <tr><td></td></tr>
        <tr>
            <td>
                <table class="fatitem" id="456">
                    <tr class="athing" id="456">
                        <td>
                            <span class="titleline">
                                <a href="https://example.com/single">Single Post Title</a>
                            </span>
                        </td>
                    </tr>
                    <tr>
                        <td class="subtext">
                            <span class="score" id="score_456">25 points</span>
                            by <a href="user?id=author" class="hnuser">author</a>
                            <span class="age" title="2023-01-01T10:00:00">4 hours ago</span>
                            | <a href="item?id=456">15 comments</a>
                        </td>
                    </tr>
                    <tr>
                        <td>This is the post text content.</td>
                    </tr>
                </table>
            </td>
        </tr>
    </table>
    """
    
    private let sampleCommentHTML = """
    <tr class="comtr" id="789">
        <td>
            <table>
                <tr>
                    <td><img src="s.gif" height="1" width="40" class="ind"></td>
                    <td>
                        <div class="commtext">
                            This is a sample comment text.
                            <div class="reply">
                                <p><font size="1">
                                    <u><a href="reply?id=789">reply</a></u>
                                </font></p>
                            </div>
                        </div>
                        <p><font color="#828282">
                            <span class="age">3 hours ago</span>
                            by <a href="user?id=commenter" class="hnuser">commenter</a>
                        </font></p>
                    </td>
                </tr>
            </table>
        </td>
    </tr>
    """
    
    private let upvotedPostHTML = """
    <table class="fatitem" id="999">
        <tr class="athing" id="999">
            <td>
                <div class="votelinks">
                    <a id="un_999" class="nosee" href="vote?id=999&how=un">
                        <div class="votearrow" title="unvote"></div>
                    </a>
                </div>
            </td>
            <td>
                <span class="titleline">
                    <a href="https://example.com/upvoted">Upvoted Post</a>
                </span>
            </td>
        </tr>
        <tr>
            <td class="subtext">
                <span class="score" id="score_999">50 points</span>
                by <a href="user?id=upvoter" class="hnuser">upvoter</a>
                <span class="age">1 hour ago</span>
                | <a href="item?id=999">3 comments</a>
            </td>
        </tr>
    </table>
    """
    
    // MARK: - Posts Tests
    
    func testParsePostsFromSinglePost() throws {
        let document = try SwiftSoup.parse(sampleSinglePostHTML)
        let tableElement = try document.select("table.fatitem").first()!
        
        let posts = try HtmlParser.posts(from: tableElement, type: .news)
        
        XCTAssertEqual(posts.count, 1)
        let post = posts[0]
        XCTAssertEqual(post.id, 456)
        XCTAssertEqual(post.title, "Single Post Title")
        XCTAssertEqual(post.url.absoluteString, "https://example.com/single")
        XCTAssertEqual(post.by, "author")
        XCTAssertEqual(post.score, 25)
        XCTAssertEqual(post.age, "4 hours ago")
        XCTAssertEqual(post.commentsCount, 15)
        XCTAssertEqual(post.postType, .news)
        XCTAssertNotNil(post.text)
    }
    
    func testParsePostsFromPostList() throws {
        let document = try SwiftSoup.parse(samplePostListHTML)
        let tableElement = try document.select("table").last()!
        
        let posts = try HtmlParser.posts(from: tableElement, type: .news)
        
        XCTAssertEqual(posts.count, 1)
        let post = posts[0]
        XCTAssertEqual(post.id, 123)
        XCTAssertEqual(post.title, "Sample Post Title")
        XCTAssertEqual(post.url.absoluteString, "https://example.com")
        XCTAssertEqual(post.by, "testuser")
        XCTAssertEqual(post.score, 10)
        XCTAssertEqual(post.age, "2 hours ago")
        XCTAssertEqual(post.commentsCount, 5)
        XCTAssertEqual(post.postType, .news)
        XCTAssertFalse(post.upvoted)
    }
    
    func testParsePostsWithUpvotedPost() throws {
        let document = try SwiftSoup.parse(upvotedPostHTML)
        let tableElement = try document.select("table.fatitem").first()!
        
        let posts = try HtmlParser.posts(from: tableElement, type: .news)
        
        XCTAssertEqual(posts.count, 1)
        let post = posts[0]
        XCTAssertTrue(post.upvoted)
    }
    
    func testParsePostsThrowsErrorForInvalidHTML() {
        let invalidHTML = "<table><tr><td>Invalid</td></tr></table>"
        
        XCTAssertThrowsError(try {
            let document = try SwiftSoup.parse(invalidHTML)
            let tableElement = try document.select("table").first()!
            return try HtmlParser.posts(from: tableElement, type: .news)
        }())
    }
    
    // MARK: - Individual Post Tests
    
    func testParseIndividualPost() throws {
        let postHTML = """
        <tr class="athing" id="123">
            <td>
                <span class="titleline">
                    <a href="https://example.com">Test Post</a>
                </span>
            </td>
        </tr>
        <tr>
            <td class="subtext">
                <span class="score">15 points</span>
                by <a href="user?id=testuser" class="hnuser">testuser</a>
                <span class="age">1 hour ago</span>
                | <a href="item?id=123">8 comments</a>
            </td>
        </tr>
        """
        
        let document = try SwiftSoup.parse(postHTML)
        let elements = try document.select("tr")
        
        let post = try HtmlParser.post(from: elements, type: .ask)
        
        XCTAssertEqual(post.id, 123)
        XCTAssertEqual(post.title, "Test Post")
        XCTAssertEqual(post.url.absoluteString, "https://example.com")
        XCTAssertEqual(post.by, "testuser")
        XCTAssertEqual(post.score, 15)
        XCTAssertEqual(post.age, "1 hour ago")
        XCTAssertEqual(post.commentsCount, 8)
        XCTAssertEqual(post.postType, .ask)
        XCTAssertFalse(post.upvoted)
    }
    
    func testParsePostThrowsErrorForMissingElements() {
        let incompleteHTML = "<tr class='athing' id='123'><td>Incomplete</td></tr>"
        
        XCTAssertThrowsError(try {
            let document = try SwiftSoup.parse(incompleteHTML)
            let elements = try document.select("tr")
            return try HtmlParser.post(from: elements, type: .news)
        }())
    }
    
    func testParsePostThrowsErrorForInvalidID() {
        let invalidIDHTML = """
        <tr class="athing" id="invalid">
            <td><span class="titleline"><a href="https://example.com">Test</a></span></td>
        </tr>
        <tr><td class="subtext">metadata</td></tr>
        """
        
        XCTAssertThrowsError(try {
            let document = try SwiftSoup.parse(invalidIDHTML)
            let elements = try document.select("tr")
            return try HtmlParser.post(from: elements, type: .news)
        }())
    }
    
    func testParsePostThrowsErrorForInvalidURL() {
        let invalidURLHTML = """
        <tr class="athing" id="123">
            <td><span class="titleline"><a href="invalid-url">Test</a></span></td>
        </tr>
        <tr><td class="subtext"><span class="hnuser">user</span></td></tr>
        """
        
        XCTAssertThrowsError(try {
            let document = try SwiftSoup.parse(invalidURLHTML)
            let elements = try document.select("tr")
            return try HtmlParser.post(from: elements, type: .news)
        }())
    }
    
    // MARK: - Posts Table Element Tests
    
    func testPostsTableElementFromHTML() throws {
        let tableElement = try HtmlParser.postsTableElement(from: samplePostListHTML)
        
        XCTAssertNotNil(tableElement)
        XCTAssertTrue(try tableElement.select("tr.athing").count > 0)
    }
    
    func testPostsTableElementThrowsErrorForInvalidHTML() {
        let invalidHTML = "<html><body>No table here</body></html>"
        
        XCTAssertThrowsError(try HtmlParser.postsTableElement(from: invalidHTML))
    }
    
    // MARK: - Comment Tests
    
    func testParseComment() throws {
        let document = try SwiftSoup.parse(sampleCommentHTML)
        let commentElement = try document.select("tr.comtr").first()!
        
        let comment = try HtmlParser.comment(from: commentElement)
        
        XCTAssertEqual(comment.id, 789)
        XCTAssertEqual(comment.by, "commenter")
        XCTAssertEqual(comment.age, "3 hours ago")
        XCTAssertEqual(comment.level, 1) // 40 width / 40 = 1
        XCTAssertFalse(comment.upvoted)
        XCTAssertTrue(comment.text.contains("This is a sample comment text"))
        XCTAssertFalse(comment.text.contains("reply")) // Reply link should be removed
    }
    
    func testParseCommentWithMultipleIndentLevels() throws {
        let indentedCommentHTML = """
        <tr class="comtr" id="890">
            <td>
                <table>
                    <tr>
                        <td><img src="s.gif" height="1" width="120" class="ind"></td>
                        <td>
                            <div class="commtext">Deeply nested comment</div>
                            <p><font color="#828282">
                                <span class="age">1 hour ago</span>
                                by <a href="user?id=deepuser" class="hnuser">deepuser</a>
                            </font></p>
                        </td>
                    </tr>
                </table>
            </td>
        </tr>
        """
        
        let document = try SwiftSoup.parse(indentedCommentHTML)
        let commentElement = try document.select("tr.comtr").first()!
        
        let comment = try HtmlParser.comment(from: commentElement)
        
        XCTAssertEqual(comment.level, 3) // 120 width / 40 = 3
        XCTAssertEqual(comment.by, "deepuser")
        XCTAssertEqual(comment.text, "Deeply nested comment")
    }
    
    func testParseCommentThrowsErrorForEmptyText() {
        let emptyCommentHTML = """
        <tr class="comtr" id="891">
            <td>
                <table>
                    <tr>
                        <td><img src="s.gif" height="1" width="40" class="ind"></td>
                        <td>
                            <div class="commtext">   </div>
                            <p><font color="#828282">
                                <span class="age">1 hour ago</span>
                                by <a href="user?id=emptyuser" class="hnuser">emptyuser</a>
                            </font></p>
                        </td>
                    </tr>
                </table>
            </td>
        </tr>
        """
        
        XCTAssertThrowsError(try {
            let document = try SwiftSoup.parse(emptyCommentHTML)
            let commentElement = try document.select("tr.comtr").first()!
            return try HtmlParser.comment(from: commentElement)
        }())
    }
    
    func testParseUpvotedComment() throws {
        let upvotedCommentHTML = """
        <tr class="comtr" id="892">
            <td>
                <table>
                    <tr>
                        <td><img src="s.gif" height="1" width="40" class="ind"></td>
                        <td>
                            <div class="commtext">Upvoted comment</div>
                            <p><font color="#828282">
                                <span class="age">1 hour ago</span>
                                by <a href="user?id=upvoteduser" class="hnuser">upvoteduser</a>
                                <a id="un_892" href="vote?id=892">unvote</a>
                            </font></p>
                        </td>
                    </tr>
                </table>
            </td>
        </tr>
        """
        
        let document = try SwiftSoup.parse(upvotedCommentHTML)
        let commentElement = try document.select("tr.comtr").first()!
        
        let comment = try HtmlParser.comment(from: commentElement)
        
        XCTAssertTrue(comment.upvoted)
    }
    
    // MARK: - Comment Elements Tests
    
    func testCommentElementsFromHTML() throws {
        let htmlWithComments = """
        <html>
            <body>
                <tr class="comtr" id="1">
                    <td>Comment 1</td>
                </tr>
                <tr class="comtr" id="2">
                    <td>Comment 2</td>
                </tr>
            </body>
        </html>
        """
        
        let commentElements = try HtmlParser.commentElements(from: htmlWithComments)
        
        XCTAssertEqual(commentElements.count, 2)
    }
    
    func testCommentElementsFromEmptyHTML() throws {
        let emptyHTML = "<html><body></body></html>"
        
        let commentElements = try HtmlParser.commentElements(from: emptyHTML)
        
        XCTAssertEqual(commentElements.count, 0)
    }
    
    // MARK: - Post Comment Tests
    
    func testPostCommentFromHTML() throws {
        let postCommentHTML = """
        <html>
            <body>
                <div class="toptext">This is post text content</div>
                <table id="hnmain">
                    <tr><td></td></tr>
                    <tr><td></td></tr>
                    <tr>
                        <td>
                            <table class="fatitem" id="456">
                                <tr class="athing" id="456">
                                    <td>
                                        <span class="titleline">
                                            <a href="https://example.com/post">Post with Text</a>
                                        </span>
                                    </td>
                                </tr>
                                <tr>
                                    <td class="subtext">
                                        <span class="score">20 points</span>
                                        by <a href="user?id=postauthor" class="hnuser">postauthor</a>
                                        <span class="age">2 hours ago</span>
                                        | <a href="item?id=456">10 comments</a>
                                    </td>
                                </tr>
                                <tr>
                                    <td>Post text content here</td>
                                </tr>
                            </table>
                        </td>
                    </tr>
                </table>
            </body>
        </html>
        """
        
        let comment = try HtmlParser.postComment(from: postCommentHTML)
        
        XCTAssertNotNil(comment)
        XCTAssertEqual(comment?.id, 456)
        XCTAssertEqual(comment?.by, "postauthor")
        XCTAssertEqual(comment?.level, 0)
        XCTAssertNotNil(comment?.text)
    }
    
    func testPostCommentReturnsNilForEmptyToptext() throws {
        let htmlWithoutToptext = sampleSinglePostHTML
        
        let comment = try HtmlParser.postComment(from: htmlWithoutToptext)
        
        XCTAssertNil(comment)
    }
    
    func testPostCommentReturnsNilWhenNoPostFound() throws {
        let invalidHTML = """
        <html>
            <body>
                <div class="toptext">This is post text content</div>
            </body>
        </html>
        """
        
        let comment = try HtmlParser.postComment(from: invalidHTML)
        
        XCTAssertNil(comment)
    }
    
    // MARK: - Edge Cases and Error Handling Tests
    
    func testScoreParsingWithZeroScore() throws {
        let zeroScoreHTML = """
        <tr class="athing" id="123">
            <td><span class="titleline"><a href="https://example.com">Test</a></span></td>
        </tr>
        <tr>
            <td class="subtext">
                <span class="score">0 points</span>
                by <a href="user?id=user" class="hnuser">user</a>
                <span class="age">1 hour ago</span>
            </td>
        </tr>
        """
        
        let document = try SwiftSoup.parse(zeroScoreHTML)
        let elements = try document.select("tr")
        
        let post = try HtmlParser.post(from: elements, type: .news)
        
        XCTAssertEqual(post.score, 0)
    }
    
    func testScoreParsingWithoutScoreElement() throws {
        let noScoreHTML = """
        <tr class="athing" id="123">
            <td><span class="titleline"><a href="https://example.com">Test</a></span></td>
        </tr>
        <tr>
            <td class="subtext">
                by <a href="user?id=user" class="hnuser">user</a>
                <span class="age">1 hour ago</span>
            </td>
        </tr>
        """
        
        let document = try SwiftSoup.parse(noScoreHTML)
        let elements = try document.select("tr")
        
        let post = try HtmlParser.post(from: elements, type: .news)
        
        XCTAssertEqual(post.score, 0)
    }
    
    func testCommentsCountParsingWithZeroComments() throws {
        let noCommentsHTML = """
        <tr class="athing" id="123">
            <td><span class="titleline"><a href="https://example.com">Test</a></span></td>
        </tr>
        <tr>
            <td class="subtext">
                <span class="score">5 points</span>
                by <a href="user?id=user" class="hnuser">user</a>
                <span class="age">1 hour ago</span>
                | <a href="item?id=123">discuss</a>
            </td>
        </tr>
        """
        
        let document = try SwiftSoup.parse(noCommentsHTML)
        let elements = try document.select("tr")
        
        let post = try HtmlParser.post(from: elements, type: .news)
        
        XCTAssertEqual(post.commentsCount, 0)
    }
    
    func testPostTextExtractionFromFatItem() {
        let fatItemHTML = """
        <table class="fatitem">
            <tr><td class="title">Title row</td></tr>
            <tr><td class="subtext">Subtext row</td></tr>
            <tr><td>This is the actual post text content.</td></tr>
        </table>
        """
        
        let document = try! SwiftSoup.parse(fatItemHTML)
        let element = try! document.select("table").first()!
        
        // Test the private postText method indirectly through posts method
        let posts = try! HtmlParser.posts(from: element, type: .news)
        
        XCTAssertEqual(posts.count, 1)
        XCTAssertNotNil(posts[0].text)
    }
    
    func testPostTextReturnsNilForNonFatItem() {
        let normalHTML = """
        <table>
            <tr class="athing" id="123">
                <td><span class="titleline"><a href="https://example.com">Test</a></span></td>
            </tr>
            <tr>
                <td class="subtext">Metadata</td>
            </tr>
        </table>
        """
        
        let document = try! SwiftSoup.parse(normalHTML)
        let element = try! document.select("table").first()!
        
        let posts = try! HtmlParser.posts(from: element, type: .news)
        
        XCTAssertEqual(posts.count, 1)
        XCTAssertNil(posts[0].text)
    }
    
    func testCommentTextWithLinksProcessing() throws {
        let commentWithLinksHTML = """
        <tr class="comtr" id="123">
            <td>
                <table>
                    <tr>
                        <td><img src="s.gif" height="1" width="40" class="ind"></td>
                        <td>
                            <div class="commtext">
                                Check out <a href="https://example.com">this link</a> for more info.
                            </div>
                            <p><font color="#828282">
                                <span class="age">1 hour ago</span>
                                by <a href="user?id=user" class="hnuser">user</a>
                            </font></p>
                        </td>
                    </tr>
                </table>
            </td>
        </tr>
        """
        
        let document = try SwiftSoup.parse(commentWithLinksHTML)
        let commentElement = try document.select("tr.comtr").first()!
        
        let comment = try HtmlParser.comment(from: commentElement)
        
        XCTAssertTrue(comment.text.contains("https://example.com"))
    }
    
    // MARK: - Performance Tests
    
    func testPerformanceOfPostsParsing() {
        let largePostListHTML = generateLargePostListHTML(count: 100)
        
        self.measure {
            do {
                let document = try SwiftSoup.parse(largePostListHTML)
                let tableElement = try document.select("table").last()!
                _ = try HtmlParser.posts(from: tableElement, type: .news)
            } catch {
                XCTFail("Performance test failed with error: \(error)")
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func generateLargePostListHTML(count: Int) -> String {
        var html = """
        <table id="hnmain">
            <tr><td></td></tr>
            <tr><td></td></tr>
            <tr>
                <td>
                    <table>
        """
        
        for i in 1...count {
            html += """
                        <tr class="athing" id="\(i)">
                            <td>
                                <span class="titleline">
                                    <a href="https://example.com/\(i)">Post Title \(i)</a>
                                </span>
                            </td>
                        </tr>
                        <tr>
                            <td class="subtext">
                                <span class="score">\(i) points</span>
                                by <a href="user?id=user\(i)" class="hnuser">user\(i)</a>
                                <span class="age">\(i) hours ago</span>
                                | <a href="item?id=\(i)">\(i) comments</a>
                            </td>
                        </tr>
            """
        }
        
        html += """
                    </table>
                </td>
            </tr>
        </table>
        """
        
        return html
    }
}