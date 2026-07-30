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
        private enum PendingResponse {
            case success(String)
            case failure(Error)
        }

        var stubbedGetResponse: String = ""
        var stubbedPostResponse: String = ""
        private var getResponses: [PendingResponse] = []
        private var postResponses: [PendingResponse] = []
        var getCallCount = 0
        var postCallCount = 0
        var lastGetURL: URL?
        var lastPostURL: URL?
        var lastPostBody: String?

        func get(url: URL) async throws -> String {
            getCallCount += 1
            lastGetURL = url
            if !getResponses.isEmpty {
                let response = getResponses.removeFirst()
                switch response {
                case let .success(html):
                    return html
                case let .failure(error):
                    throw error
                }
            }
            return stubbedGetResponse
        }

        func post(url: URL, body: String) async throws -> String {
            postCallCount += 1
            lastPostURL = url
            lastPostBody = body
            if !postResponses.isEmpty {
                let response = postResponses.removeFirst()
                switch response {
                case let .success(html):
                    return html
                case let .failure(error):
                    throw error
                }
            }
            return stubbedPostResponse
        }

        func clearCookies() {
            // No-op for testing
        }

        func containsCookie(for _: URL) -> Bool {
            false // Return false for testing simplicity
        }

        // MARK: - Helpers

        func enqueueGetResponse(_ html: String) {
            getResponses.append(.success(html))
        }

        func enqueueGetError(_ error: Error) {
            getResponses.append(.failure(error))
        }

        func enqueuePostResponse(_ html: String) {
            postResponses.append(.success(html))
        }

        func enqueuePostError(_ error: Error) {
            postResponses.append(.failure(error))
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
        #expect(posts.count == 1, "Should parse a single post from fixture")

        guard let post = posts.first else {
            Issue.record("Expected parsed post")
            return
        }

        #expect(post.id == 123)
        #expect(post.title == "Test Article Title")
        #expect(post.url.absoluteString == "https://example.com/article")
        #expect(post.by == "testuser")
        #expect(post.commentsCount == 5)
        #expect(post.score == 10)
        #expect(post.age == "2023-01-01T10:00:00")
        #expect(post.voteLinks?.upvote != nil)
    }

    @Test("Get posts with newest type")
    func getPostsNewestType() async throws {
        mockNetworkManager.stubbedGetResponse = createMockPostsHTML()

        let posts = try await postRepository.getPosts(type: .newest, page: 1, nextId: 12345)

        #expect(mockNetworkManager.getCallCount == 1)
        #expect(mockNetworkManager.lastGetURL != nil)
        #expect(mockNetworkManager.lastGetURL!.absoluteString.contains("newest"))
        #expect(mockNetworkManager.lastGetURL!.absoluteString.contains("next=12345"))
        if let upvote = posts.first?.voteLinks?.upvote?.absoluteString {
            #expect(upvote.contains("vote?id=123&how=up"))
        } else {
            Issue.record("Expected upvote URL for newest post fixture")
        }
    }

    @Test("Get posts with active type")
    func getPostsActiveType() async throws {
        mockNetworkManager.stubbedGetResponse = createMockPostsHTML()

        let posts = try await postRepository.getPosts(type: .active, page: 2, nextId: nil)

        #expect(mockNetworkManager.getCallCount == 1)
        #expect(mockNetworkManager.lastGetURL != nil)
        #expect(mockNetworkManager.lastGetURL!.absoluteString.contains("active"))
        #expect(mockNetworkManager.lastGetURL!.absoluteString.contains("p=2"))
        #expect(posts.first?.commentsCount == 5)
    }

    @Test("Malformed feed HTML surfaces scraper error")
    func malformedFeedHTMLThrows() async {
        mockNetworkManager.stubbedGetResponse = "<html><body><p>No table</p></body></html>"

        await #expect(throws: HackersKitError.self) {
            _ = try await postRepository.getPosts(type: .news, page: 1, nextId: nil)
        }
    }

    // MARK: - GetPost Tests

    @Test("Get post")
    func getPost() async throws {
        mockNetworkManager.stubbedGetResponse =
            createMockSinglePostWithCommentsHTML(storyID: 123, commentIDs: [201, 202])

        let post = try await postRepository.getPost(id: 123)

        #expect(mockNetworkManager.getCallCount == 1)
        #expect(mockNetworkManager.lastGetURL != nil)
        #expect(mockNetworkManager.lastGetURL!.absoluteString.contains("id=123"))
        #expect(post.id == 123)
        #expect(post.title == "Test Article Title")
        #expect(post.score == 10)
        #expect(post.by == "testuser")
        #expect(post.comments?.count == 2)
        #expect(post.comments?.first?.id == 201)
        if let commentUpvote = post.comments?.first?.voteLinks?.upvote?.absoluteString {
            #expect(commentUpvote.contains("vote?id=201"))
        } else {
            Issue.record("Expected comment upvote link")
        }
    }

    @Test("Flagged comments are parsed as collapsed placeholders")
    func flaggedCommentPlaceholder() async throws {
        mockNetworkManager.stubbedGetResponse = createMockPostWithFlaggedCommentHTML()

        let post = try await postRepository.getPost(id: 123)
        let comments = try #require(post.comments)

        #expect(comments.count == 2)
        #expect(comments[0].id == 201)
        #expect(comments[0].text == "[flagged]")
        #expect(comments[0].isFlagged)
        #expect(comments[0].level == 1)
        #expect(comments[0].visibility == .compact)
        #expect(comments[1].id == 202)
        #expect(comments[1].level == 2)
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

        mockNetworkManager.enqueueGetResponse(
            createMockCommentPermalinkHTML(commentID: commentID, parentCommentID: parentCommentID, storyID: storyID)
        )
        mockNetworkManager.enqueueGetResponse(
            createMockSinglePostWithCommentsHTML(storyID: storyID, commentIDs: [commentID])
        )

        let post = try await postRepository.getPost(id: commentID)

        #expect(mockNetworkManager.getCallCount == 2)
        #expect(post.id == storyID)
        #expect(post.comments?.contains(where: { $0.id == commentID }) == true)
    }

    @Test("Unresolvable permalink chain is bounded and throws")
    func unresolvablePermalinkChainThrows() async {
        // Enqueue a chain of permalinks longer than maxParentResolutionDepth, each pointing
        // at the next, none of which ever contain a story fatitem. The depth guard must
        // stop the recursion and throw rather than looping indefinitely.
        for index in 0..<8 {
            let current = 2000 + index
            let parent = 2000 + index + 1
            let story = 2000 + index + 2
            mockNetworkManager.enqueueGetResponse(
                createMockCommentPermalinkHTML(commentID: current, parentCommentID: parent, storyID: story)
            )
        }

        await #expect(throws: HackersKitError.self) {
            _ = try await postRepository.getPost(id: 2000)
        }
    }

    @Test("Parent id resolves even with extra query parameters")
    func parentIDWithExtraQueryParams() async throws {
        let commentID = 888
        let storyID = 777
        mockNetworkManager.enqueueGetResponse(
            createMockCommentPermalinkWithExtraParamsHTML(commentID: commentID, storyID: storyID)
        )
        mockNetworkManager.enqueueGetResponse(
            createMockSinglePostWithCommentsHTML(storyID: storyID, commentIDs: [commentID])
        )

        let post = try await postRepository.getPost(id: commentID)

        #expect(post.id == storyID)
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
        // The repository performs the vote and reports success/failure; it does not mutate
        // the caller's comment. Optimistic upvoted state is owned by the view model.
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
        mockNetworkManager.stubbedGetResponse =
            createMockSinglePostWithCommentsHTML(storyID: 123, commentIDs: [456, 789, 790])
        let post = createTestPost()

        let comments = try await postRepository.getComments(for: post)

        #expect(mockNetworkManager.getCallCount == 1)
        #expect(mockNetworkManager.lastGetURL != nil)
        #expect(mockNetworkManager.lastGetURL!.absoluteString.contains("item"))
        #expect(mockNetworkManager.lastGetURL!.absoluteString.contains("id=123"))
        #expect(comments.count == 3)
        #expect(comments[0].id == 456)
        #expect(comments[0].level == 0)
        #expect(comments[1].level == 1)
        #expect(comments[2].level == 2)
        #expect(comments[0].text.contains("Comment 456"))
    }

    @Test("Follows comment pagination (morelink) across pages")
    func getCommentsFollowsPagination() async throws {
        let storyID = 555
        // Page 1: the story plus the first two comments and a "More" link.
        mockNetworkManager.enqueueGetResponse(
            createMockSinglePostWithCommentsHTML(
                storyID: storyID, commentIDs: [601, 602], morelink: true
            )
        )
        // Page 2: two further comments and no more link (last page).
        mockNetworkManager.enqueueGetResponse(
            createMockCommentsPageHTML(storyID: storyID, commentIDs: [603, 604], morelink: false)
        )
        let post = createTestPostWithId(storyID)

        let comments = try await postRepository.getComments(for: post)

        #expect(mockNetworkManager.getCallCount == 2, "Should fetch both comment pages")
        #expect(comments.count == 4, "Should merge comments across pages")
        #expect(comments.map(\.id) == [601, 602, 603, 604])
    }

    @Test("Does not fetch additional pages when there is no morelink")
    func getCommentsSinglePage() async throws {
        mockNetworkManager.stubbedGetResponse =
            createMockSinglePostWithCommentsHTML(storyID: 999, commentIDs: [700, 701], morelink: false)
        let post = createTestPostWithId(999)

        _ = try await postRepository.getComments(for: post)

        #expect(mockNetworkManager.getCallCount == 1, "Should fetch only the first page")
    }

    // MARK: - Error Handling Tests

    @Test("Network error handling")
    func networkError() async {
        mockNetworkManager.enqueueGetError(URLError(.notConnectedToInternet))
        let post = createTestPost()

        await #expect(throws: URLError.self) {
            _ = try await postRepository.getComments(for: post)
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
                <td align="right" valign="top" class="title"><span class="rank">1.</span></td>
                <td valign="top" class="votelinks">
                    <center>
                        <a id='up_123' href='vote?id=123&how=up'>
                            <div class='votearrow' title='upvote'></div>
                        </a>
                    </center>
                </td>
                <td class="title">
                    <span class="titleline">
                        <a href="https://example.com/article">Test Article Title</a>
                    </span>
                </td>
            </tr>
            <tr>
                <td colspan="2"></td>
                <td class="subtext">
                    <span class="score">10 points</span>
                    <span class="age" title="2023-01-01T10:00:00">2 hours ago</span>
                    <a class="hnuser" href="user?id=testuser">testuser</a>
                    <a href="item?id=123">5&nbsp;comments</a>
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

    private func createMockSinglePostWithCommentsHTML(
        storyID: Int, commentIDs: [Int], morelink: Bool = false
    ) -> String {
        let commentsHTML = commentTreeRowsHTML(storyID: storyID, commentIDs: commentIDs)
        let moreLinkHTML = morelink ? """
        <a href="item?id=\(storyID)&p=2" class="morelink">More</a>
        """ : ""

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
            \(moreLinkHTML)
        </table>
        </body>
        </html>
        """
    }

    /// Renders a standalone comment page (no fatitem story header) used to model HN's
    /// paginated comment threads, optionally including a "More" link to the next page.
    private func createMockCommentsPageHTML(
        storyID: Int, commentIDs: [Int], morelink: Bool
    ) -> String {
        let commentsHTML = commentTreeRowsHTML(storyID: storyID, commentIDs: commentIDs)
        let moreLinkHTML = morelink ? """
        <a href="item?id=\(storyID)&p=2" class="morelink">More</a>
        """ : ""

        return """
        <html>
        <body>
        <table class=\"comment-tree\">
            \(commentsHTML)
            \(moreLinkHTML)
        </table>
        </body>
        </html>
        """
    }

    /// Shared builder for `<tr class="comtr">` rows used by both the story fixture and the
    /// standalone comment-page fixture.
    private func commentTreeRowsHTML(storyID: Int, commentIDs: [Int]) -> String {
        commentIDs.enumerated().map { index, id -> String in
            let indentWidth = index * 40
            return """
            <tr class=\"athing comtr\" id=\"\(id)\">
                <td>
                    <table>
                        <tr>
                            <td class=\"ind\" indent=\"\(indentWidth)\"><img src=\"s.gif\" height=\"1\" width=\"\(indentWidth)\"></td>
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
    }

    private func createMockPostWithFlaggedCommentHTML() -> String {
        """
        <html>
        <body>
        <table class="fatitem">
            <tr class="athing" id="123">
                <td><span class="titleline"><a href="https://example.com/article">Test Article Title</a></span></td>
            </tr>
            <tr><td>
                <span class="score">10 points</span>
                <span class="age">2 hours ago</span>
                <a class="hnuser">testuser</a>
                <a href="item?id=123">2 comments</a>
            </td></tr>
        </table>
        <table class="comment-tree">
            <tr class="athing comtr coll" id="201"><td><table><tr>
                <td class="ind" indent="1"><img src="s.gif" width="40"></td>
                <td class="votelinks nosee"></td>
                <td class="default">
                    <span class="comhead">
                        <a class="hnuser">flagged-user</a>
                        <span class="age">1 hour ago</span>
                    </span>
                    <div class="comment noshow">[flagged]<div class="reply"></div></div>
                </td>
            </tr></table></td></tr>
            <tr class="athing comtr noshow" id="202"><td><table><tr>
                <td class="ind" indent="2"><img src="s.gif" width="80"></td>
                <td class="votelinks"></td>
                <td class="default">
                    <span class="comhead">
                        <a class="hnuser">reply-user</a>
                        <span class="age">30 minutes ago</span>
                    </span>
                    <div class="comment"><div class="commtext c00">Visible reply</div></div>
                </td>
            </tr></table></td></tr>
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

    /// Permalink fixture whose on-story link carries extra query parameters, exercising the
    /// URLComponents-based parent-id parser (the old `components(separatedBy:)` approach
    /// would have returned "777&foo=bar" and failed to parse an int).
    private func createMockCommentPermalinkWithExtraParamsHTML(commentID: Int, storyID: Int) -> String {
        """
        <html>
        <body>
        <table class=\"fatitem\">
            <tr class=\"athing\" id=\"\(commentID)\"></tr>
        </table>
        <span class=\"navs\">
            <span class=\"onstory\"> | on: <a href=\"item?id=\(storyID)&foo=bar\">Story Title</a></span>
        </span>
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

@Suite("PostRepository Number Parsing")
struct PostRepositoryNumberParsingTests {
    let repository = PostRepository(networkManager: StubNetworkManager())

    @Test("Parses plain plural counts")
    func plainPlural() {
        #expect(repository.leadingInt(from: "10 points") == 10)
        #expect(repository.leadingInt(from: "5 comments") == 5)
    }

    @Test("Parses singular 'point' form without dropping to zero")
    func singularPoint() {
        #expect(repository.leadingInt(from: "1 point") == 1)
    }

    @Test("Parses 'Discuss' as zero comments")
    func discuss() {
        #expect(repository.leadingInt(from: "Discuss") == 0)
    }

    @Test("Parses NBSP thousands-separated scores")
    func nbspThousands() {
        #expect(repository.leadingInt(from: "1\u{00A0}234\u{00A0}points") == 1234)
        #expect(repository.leadingInt(from: "1\u{00A0}234\u{00A0}comments") == 1234)
    }

    @Test("Parses narrow no-break space (U+202F) separators")
    func narrowNbsp() {
        #expect(repository.leadingInt(from: "1\u{202F}234\u{202F}points") == 1234)
    }

    @Test("Returns zero for nil and empty input")
    func nilAndEmpty() {
        #expect(repository.leadingInt(from: nil) == 0)
        #expect(repository.leadingInt(from: "") == 0)
    }

    @Test("Stops at non-digit suffix")
    func suffix() {
        #expect(repository.leadingInt(from: "42 points by alice") == 42)
    }
}

@Suite("PostRepository NBSP Score Parsing")
struct PostRepositoryNBSPParsingTests {
    let network = StubNetworkManager()
    var postRepository: PostRepository {
        PostRepository(networkManager: network)
    }

    @Test("Parses NBSP-formatted score and singular score from feed HTML")
    func nbspAndSingularScoreFromFeed() async throws {
        network.enqueue(html: """
        <html><body><table class="itemlist">
            <tr class="athing submission" id="1">
                <td valign="top" class="votelinks"><center><a id='up_1' href='vote?id=1&how=up'><div class='votearrow'></div></a></center></td>
                <td class="title"><span class="titleline"><a href="https://example.com/a">A</a></span></td>
            </tr>
            <tr><td colspan="2"></td><td class="subtext">
                <span class="score">1\u{00A0}234\u{00A0}points</span>
                <span class="age" title="t">2 hours ago</span>
                <a class="hnuser" href="user?id=u">u</a>
                <a href="item?id=1">1 comment</a>
            </td></tr>
            <tr class="athing submission" id="2">
                <td valign="top" class="votelinks"><center><a id='up_2' href='vote?id=2&how=up'><div class='votearrow'></div></a></center></td>
                <td class="title"><span class="titleline"><a href="https://example.com/b">B</a></span></td>
            </tr>
            <tr><td colspan="2"></td><td class="subtext">
                <span class="score">1 point</span>
                <span class="age" title="t">2 hours ago</span>
                <a class="hnuser" href="user?id=u">u</a>
                <a href="item?id=2">Discuss</a>
            </td></tr>
        </table></body></html>
        """)

        let posts = try await postRepository.getPosts(type: .news, page: 1, nextId: nil)

        #expect(posts.count == 2)
        #expect(posts[0].score == 1234, "NBSP-separated score should parse to 1234")
        #expect(posts[0].commentsCount == 1, "Singular '1 point' comment count should parse to 1")
        #expect(posts[1].score == 1, "Singular '1 point' score should parse to 1")
        #expect(posts[1].commentsCount == 0, "'Discuss' should parse to 0 comments")
    }
}

// swiftlint:enable type_body_length
