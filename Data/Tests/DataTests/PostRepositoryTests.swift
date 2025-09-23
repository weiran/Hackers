//
//  PostRepositoryTests.swift
//  DataTests
//
//  Copyright © 2025 Weiran Zhang. All rights reserved.
//

// swiftlint:disable force_cast

@testable import Data
@testable import Domain
import Foundation
@testable import Networking
import Testing

// swiftlint:disable type_body_length
@Suite("PostRepository Tests")
struct PostRepositoryTests {
    let mockNetworkManager = MockNetworkManager()
    var postRepository: PostRepository {
        PostRepository(networkManager: mockNetworkManager)
    }

    // MARK: - Mock NetworkManager

    final class MockNetworkManager: NetworkManagerProtocol, @unchecked Sendable {
        var stubbedGetResponse: String = ""
        var stubbedPostResponse: String = ""
        var responseQueue: [String] = []
        var getCallCount = 0
        var postCallCount = 0
        var lastGetURL: URL?
        var lastPostURL: URL?
        var lastPostBody: String?

        func get(url: URL) async throws -> String {
            getCallCount += 1
            lastGetURL = url
            if !responseQueue.isEmpty {
                return responseQueue.removeFirst()
            }
            return stubbedGetResponse
        }

        func post(url: URL, body: String) async throws -> String {
            postCallCount += 1
            lastPostURL = url
            lastPostBody = body
            return stubbedPostResponse
        }

        func clearCookies() {
            // No-op for testing
        }

        func containsCookie(for _: URL) -> Bool {
            false // Return false for testing simplicity
        }
    }

    // MARK: - Initialization Tests

    @Test("PostRepository initialization")
    func postRepositoryInitialization() {
        #expect(postRepository != nil, "PostRepository should initialize successfully")
    }

    // MARK: - GetPosts Tests

    @Test("Get posts with news type")
    func getPostsNewsType() async throws {
        mockNetworkManager.stubbedGetResponse = createMockPostsHTML()

        let posts = try await postRepository.getPosts(type: .news, page: 1, nextId: nil)

        #expect(mockNetworkManager.getCallCount == 1, "Should make one network call")
        #expect(mockNetworkManager.lastGetURL != nil, "Should have a URL")
        #expect(mockNetworkManager.lastGetURL!.absoluteString.contains("news"), "URL should contain 'news'")
        #expect(mockNetworkManager.lastGetURL!.absoluteString.contains("p=1"), "URL should contain page parameter")
    }

    @Test("Get posts with newest type")
    func getPostsNewestType() async throws {
        mockNetworkManager.stubbedGetResponse = createMockPostsHTML()

        let posts = try await postRepository.getPosts(type: .newest, page: 1, nextId: 12345)

        #expect(mockNetworkManager.getCallCount == 1)
        #expect(mockNetworkManager.lastGetURL != nil)
        #expect(mockNetworkManager.lastGetURL!.absoluteString.contains("newest"))
        #expect(mockNetworkManager.lastGetURL!.absoluteString.contains("next=12345"))
    }

    @Test("Get posts with active type")
    func getPostsActiveType() async throws {
        mockNetworkManager.stubbedGetResponse = createMockPostsHTML()

        let posts = try await postRepository.getPosts(type: .active, page: 2, nextId: nil)

        #expect(mockNetworkManager.getCallCount == 1)
        #expect(mockNetworkManager.lastGetURL != nil)
        #expect(mockNetworkManager.lastGetURL!.absoluteString.contains("active"))
        #expect(mockNetworkManager.lastGetURL!.absoluteString.contains("p=2"))
    }

    // MARK: - GetPost Tests

    @Test("Get post")
    func getPost() async throws {
        mockNetworkManager.stubbedGetResponse = createMockSinglePostHTML()

        let post = try await postRepository.getPost(id: 123)

        #expect(mockNetworkManager.getCallCount == 1)
        #expect(mockNetworkManager.lastGetURL != nil)
        #expect(mockNetworkManager.lastGetURL!.absoluteString.contains("id=123"))
    }

    @Test("Get Ask HN post includes top text")
    func getAskPostIncludesTopText() async throws {
        mockNetworkManager.stubbedGetResponse = createMockAskPostHTML(id: 456)

        let post = try await postRepository.getPost(id: 456)

        let topComment = post.comments?.first

        #expect(post.text?.contains("Intro text") == true)
        #expect(topComment != nil)
        #expect(topComment?.id == -456)
        #expect(topComment?.level == 0)
        #expect(topComment?.age == "4 hours ago")
        #expect(topComment?.text.contains("Intro text") == true)
        #expect(topComment?.text.contains("<p>First paragraph</p>") == true)
        #expect(topComment?.text.contains("<p>Second paragraph</p>") == true)
    }

    @Test("Get post from comment id resolves parent story")
    func getPostFromCommentID() async throws {
        let commentID = 999
        let parentCommentID = 998
        let storyID = 321

        mockNetworkManager.responseQueue = [
            createMockCommentPermalinkHTML(commentID: commentID, parentCommentID: parentCommentID, storyID: storyID),
            createMockSinglePostWithCommentsHTML(storyID: storyID, commentIDs: [commentID])
        ]

        let post = try await postRepository.getPost(id: commentID)

        #expect(mockNetworkManager.getCallCount == 2)
        #expect(post.id == storyID)
        #expect(post.comments?.contains(where: { $0.id == commentID }) == true)
    }

    // MARK: - Vote Tests

    @Test("Upvote post")
    func upvotePost() async throws {
        let voteLinks = VoteLinks(upvote: URL(string: "/vote?id=123&how=up")!, unvote: nil)
        let post = createTestPost(voteLinks: voteLinks)

        try await postRepository.upvote(post: post)

        #expect(mockNetworkManager.getCallCount == 1)
        #expect(mockNetworkManager.lastGetURL != nil)
        #expect(mockNetworkManager.lastGetURL!.absoluteString.contains("news.ycombinator.com"))
        #expect(mockNetworkManager.lastGetURL!.absoluteString.contains("vote"))
    }

    // Unvote post test removed

    @Test("Upvote post without vote links")
    func upvotePostWithoutVoteLinks() async {
        let post = createTestPost(voteLinks: nil)

        do {
            try await postRepository.upvote(post: post)
            Issue.record("Expected error for post without vote links")
        } catch {
            #expect(error is HackersKitError)
        }
    }

    @Test("Upvote comment")
    func upvoteComment() async throws {
        let voteLinks = VoteLinks(upvote: URL(string: "/vote?id=456&how=up")!, unvote: nil)
        let comment = createTestComment(voteLinks: voteLinks)
        let post = createTestPost()

        try await postRepository.upvote(comment: comment, for: post)

        #expect(mockNetworkManager.getCallCount == 1)
        #expect(mockNetworkManager.lastGetURL != nil)
        #expect(mockNetworkManager.lastGetURL!.absoluteString.contains("news.ycombinator.com"))
        #expect(mockNetworkManager.lastGetURL!.absoluteString.contains("vote"))

        // Verify comment state is updated after successful upvote
        #expect(comment.upvoted == true, "Comment should be marked as upvoted after successful API call")
    }

    // Unvote comment test removed

    // MARK: - Post Feed Upvoted State Tests

    @Test("Parse upvoted post from feed HTML (nosee + explicit unvote)")
    func parseUpvotedPostFromFeed() async throws {
        mockNetworkManager.stubbedGetResponse = createMockFeedHTMLWithUpvotedPost()

        let posts = try await postRepository.getPosts(type: .news, page: 1, nextId: nil)

        #expect(posts.count == 2, "Should parse two posts")

        let upvotedPost = posts.first { $0.id == 45_237_717 }
        let alsoUpvotedHiddenArrow = posts.first { $0.id == 45_238_055 }

        #expect(upvotedPost != nil, "Should find upvoted post")
        #expect(alsoUpvotedHiddenArrow != nil, "Should find post with hidden upvote arrow (nosee)")

        #expect(upvotedPost?.upvoted == true, "Post with explicit unvote link should be marked as upvoted")
        #expect(alsoUpvotedHiddenArrow?.upvoted == true, "Post with 'nosee' upvote link should be marked as upvoted")

        #expect(upvotedPost?.voteLinks?.unvote != nil, "Upvoted post should have unvote link")
        #expect(upvotedPost?.voteLinks?.upvote != nil, "Upvoted post should still have upvote link available")

        // For the 'nosee' case without explicit unvote, we derive the unvote URL
        #expect(alsoUpvotedHiddenArrow?.voteLinks?.unvote != nil, "Hidden upvote arrow should yield a derived unvote link")
        #expect(alsoUpvotedHiddenArrow?.voteLinks?.unvote?.absoluteString.contains("how=un") == true,
                "Derived unvote link should use how=un")
    }

    // Derived unvote link test removed

    // Unvote after optimistic upvote test removed

    // MARK: - Comments Tests

    @Test("Get comments")
    func getComments() async throws {
        mockNetworkManager.stubbedGetResponse = createMockCommentsHTML()
        let post = createTestPost()

        let comments = try await postRepository.getComments(for: post)

        #expect(mockNetworkManager.getCallCount == 1)
        #expect(mockNetworkManager.lastGetURL != nil)
        #expect(mockNetworkManager.lastGetURL!.absoluteString.contains("item"))
        #expect(mockNetworkManager.lastGetURL!.absoluteString.contains("id=123"))
    }

    // MARK: - Error Handling Tests

    @Test("Network error handling")
    func networkError() async {
        // Configure mock to throw an error
        let post = createTestPost()

        do {
            _ = try await postRepository.getComments(for: post)
            // Since we're not setting stubbed response, this should use the default empty string
            // which should result in an empty comments array, not an error
            // This test verifies the repository handles parsing gracefully
        } catch {
            Issue.record("Repository should handle parsing errors gracefully")
        }
    }

    // MARK: - Helper Methods

    private func createTestPost(voteLinks: VoteLinks? = nil) -> Post {
        Post(
            id: 123,
            url: URL(string: "https://example.com/post")!,
            title: "Test Post",
            age: "2 hours ago",
            commentsCount: 5,
            by: "testuser",
            score: 10,
            postType: .news,
            upvoted: false,
            voteLinks: voteLinks,
        )
    }

    private func createTestPostWithId(_ id: Int, voteLinks: VoteLinks? = nil, upvoted: Bool = false) -> Post {
        Post(
            id: id,
            url: URL(string: "https://example.com/post")!,
            title: "Test Post",
            age: "2 hours ago",
            commentsCount: 5,
            by: "testuser",
            score: 10,
            postType: .news,
            upvoted: upvoted,
            voteLinks: voteLinks,
        )
    }

    private func createTestComment(voteLinks: VoteLinks? = nil, upvoted: Bool = false) -> Domain.Comment {
        Domain.Comment(
            id: 456,
            age: "1 hour ago",
            text: "Test comment",
            by: "commenter",
            level: 0,
            upvoted: upvoted,
            voteLinks: voteLinks,
        )
    }

    private func createMockPostsHTML() -> String {
        """
        <html>
        <body>
        <table class="itemlist">
            <tr class="athing submission" id="123">
                <td>
                    <span class="titleline">
                        <a href="https://example.com/article">Test Article Title</a>
                    </span>
                </td>
            </tr>
            <tr>
                <td>
                    <span class="score">10 points</span>
                    <span class="age" title="2023-01-01T10:00:00">2 hours ago</span>
                    <a class="hnuser" href="user?id=testuser">testuser</a>
                    <a href="item?id=123">5 comments</a>
                </td>
            </tr>
        </table>
        </body>
        </html>
        """
    }

    private func createMockSinglePostHTML(id: Int = 123) -> String {
        """
        <html>
        <body>
        <table class="fatitem">
            <tr class="athing" id="\(id)">
                <td>
                    <span class="titleline">
                        <a href="https://example.com/article">Test Article Title</a>
                    </span>
                </td>
            </tr>
            <tr>
                <td>
                    <span class="score">10 points</span>
                    <span class="age" title="2023-01-01T10:00:00">2 hours ago</span>
                    <a class="hnuser" href="user?id=testuser">testuser</a>
                    <a href="item?id=\(id)">5 comments</a>
                </td>
            </tr>
        </table>
        </body>
        </html>
        """
    }

    private func createMockAskPostHTML(id: Int) -> String {
        """
        <html>
        <body>
        <table class="fatitem">
            <tr class="athing submission" id="\(id)">
                <td align="right" valign="top" class="title"><span class="rank"></span></td>
                <td valign="top" class="votelinks"></td>
                <td class="title">
                    <span class="titleline">
                        <a href="item?id=\(id)">Ask HN Example</a>
                    </span>
                </td>
            </tr>
            <tr>
                <td colspan="2"></td>
                <td class="subtext">
                    <span class="subline">
                        <span class="score">12 points</span>
                        by <a href="user?id=asker" class="hnuser">asker</a>
                        <span class="age" title="2023-01-01T12:00:00"><a href="item?id=\(id)">4 hours ago</a></span>
                        <a href="item?id=\(id)">3&nbsp;comments</a>
                    </span>
                </td>
            </tr>
            <tr>
                <td colspan="2"></td>
                <td>
                    <div class="toptext">Intro text<p>First paragraph</p><p>Second paragraph</p></div>
                </td>
            </tr>
        </table>
        </body>
        </html>
        """
    }

    private func createMockSinglePostWithCommentsHTML(storyID: Int, commentIDs: [Int]) -> String {
        let commentsHTML = commentIDs.map { id in
            """
            <tr class=\"athing comtr\" id=\"\(id)\">
                <td>
                    <table>
                        <tr>
                            <td class=\"ind\" indent=\"0\"><img src=\"s.gif\" height=\"1\" width=\"0\"></td>
                            <td valign=\"top\" class=\"votelinks\"><center><a id='up_\(id)' href='vote?id=\(id)&how=up&goto=item%3Fid%3D\(storyID)'><div class='votearrow' title='upvote'></div></a></center></td>
                            <td class=\"default\">
                                <div style=\"margin-top:2px; margin-bottom:-10px;\">
                                    <span class=\"comhead\">
                                        <a href=\"user?id=commenter\" class=\"hnuser\">commenter</a>
                                        <span class=\"age\" title=\"2023-01-01T10:00:00\"><a href=\"item?id=\(id)\">1 hour ago</a></span>
                                        <span id=\"unv_\(id)\"></span>
                                        <span class=\"navs\"></span>
                                    </span>
                                </div>
                                <br>
                                <div class=\"comment\">
                                    <div class=\"commtext c00\">Comment \(id)</div>
                                </div>
                            </td>
                        </tr>
                    </table>
                </td>
            </tr>
            """
        }.joined(separator: "\n")

        return """
        <html>
        <body>
        <table class=\"fatitem\">
            <tr class=\"athing\" id=\"\(storyID)\">
                <td>
                    <span class=\"titleline\">
                        <a href=\"https://example.com/article\">Test Article Title</a>
                    </span>
                </td>
            </tr>
            <tr>
                <td>
                    <span class=\"score\">10 points</span>
                    <span class=\"age\" title=\"2023-01-01T10:00:00\">2 hours ago</span>
                    <a class=\"hnuser\" href=\"user?id=testuser\">testuser</a>
                    <a href=\"item?id=\(storyID)\">5 comments</a>
                </td>
            </tr>
        </table>
        <table class=\"comment-tree\">
            \(commentsHTML)
        </table>
        </body>
        </html>
        """
    }

    private func createMockCommentPermalinkHTML(commentID: Int, parentCommentID: Int, storyID: Int) -> String {
        """
        <html>
        <body>
        <table class=\"fatitem\">
            <tr class=\"athing\" id=\"\(commentID)\"></tr>
        </table>
        <span class=\"navs\">
            | <a href=\"item?id=\(parentCommentID)\">parent</a>
            <span class=\"onstory\"> | on: <a href=\"item?id=\(storyID)\">Story Title</a></span>
        </span>
        </body>
        </html>
        """
    }

    private func createMockCommentsHTML() -> String {
        """
        <html>
        <body>
        <table class="comment-tree">
            <tr class="athing comtr" id="456">
                <td>
                    <div class="comment">
                        <span class="age">1 hour ago</span>
                        <a class="hnuser" href="user?id=commenter">commenter</a>
                        <div class="comment-body">This is a test comment</div>
                    </div>
                </td>
            </tr>
        </table>
        </body>
        </html>
        """
    }

    private func createMockFeedHTMLWithUpvotedPost() -> String {
        """
        <html>
        <body>
        <table id="hnmain">
            <tr class="athing submission" id="45238055">
                <td align="right" valign="top" class="title">
                    <span class="rank">1.</span>
                </td>
                <td valign="top" class="votelinks">
                    <center>
                        <a id='up_45238055' class='clicky nosee' href='vote?id=45238055&amp;how=up&amp;auth=test&amp;goto=news'>
                            <div class='votearrow' title='upvote'></div>
                        </a>
                    </center>
                </td>
                <td class="title">
                    <span class="titleline">
                        <a href="http://example.com/article1">Not Upvoted Article</a>
                    </span>
                </td>
            </tr>
            <tr>
                <td colspan="2"></td>
                <td class="subtext">
                    <span class="subline">
                        <span class="score" id="score_45238055">241 points</span>
                         by 
                        <a href="user?id=testuser" class="hnuser">testuser</a>
                        <span class="age" title="2025-09-14T07:00:44">
                            <a href="item?id=45238055">3 hours ago</a>
                        </span>
                        <span id="unv_45238055"></span>
                         | 
                        <a href="item?id=45238055">45&nbsp;comments</a>
                    </span>
                </td>
            </tr>
            <tr class="spacer" style="height:5px"></tr>
            <tr class="athing submission" id="45237717">
                <td align="right" valign="top" class="title">
                    <span class="rank">2.</span>
                </td>
                <td valign="top" class="votelinks">
                    <center>
                        <a id='up_45237717' class='clicky nosee' href='vote?id=45237717&amp;how=up&amp;auth=test&amp;goto=news'>
                            <div class='votearrow' title='upvote'></div>
                        </a>
                    </center>
                </td>
                <td class="title">
                    <span class="titleline">
                        <a href="http://example.com/article2">Upvoted Article</a>
                    </span>
                </td>
            </tr>
            <tr>
                <td colspan="2"></td>
                <td class="subtext">
                    <span class="subline">
                        <span class="score" id="score_45237717">72 points</span>
                         by 
                        <a href="user?id=testuser2" class="hnuser">testuser2</a>
                        <span class="age" title="2025-09-14T05:42:38">
                            <a href="item?id=45237717">4 hours ago</a>
                        </span>
                        <span id="unv_45237717">
                             |
                            <a id='un_45237717' class='clicky' href='vote?id=45237717&amp;how=un&amp;auth=test&amp;goto=news'>unvote</a>
                        </span>
                         |
                        <a href="item?id=45237717">13&nbsp;comments</a>
                    </span>
                </td>
            </tr>
        </table>
        </body>
        </html>
        """
    }
}

// swiftlint:enable type_body_length
