//
//  ModelsTests.swift
//  DomainTests
//
//  Copyright © 2025 Weiran Zhang. All rights reserved.
//

// swiftlint:disable force_cast

import XCTest
import Foundation
@testable import Domain

class ModelsTests: XCTestCase {

    // MARK: - VoteLinks Tests

    func testVoteLinksInit() {
        let upvoteURL = URL(string: "https://example.com/upvote")
        let unvoteURL = URL(string: "https://example.com/unvote")

        let voteLinks = VoteLinks(upvote: upvoteURL, unvote: unvoteURL)

        XCTAssertEqual(voteLinks.upvote, upvoteURL)
        XCTAssertEqual(voteLinks.unvote, unvoteURL)
    }

    func testVoteLinksHashable() {
        let upvoteURL = URL(string: "https://example.com/upvote")
        let unvoteURL = URL(string: "https://example.com/unvote")

        let voteLinks1 = VoteLinks(upvote: upvoteURL, unvote: unvoteURL)
        let voteLinks2 = VoteLinks(upvote: upvoteURL, unvote: unvoteURL)
        let voteLinks3 = VoteLinks(upvote: nil, unvote: unvoteURL)

        XCTAssertEqual(voteLinks1, voteLinks2)
        XCTAssertNotEqual(voteLinks1, voteLinks3)
        XCTAssertEqual(voteLinks1.hashValue, voteLinks2.hashValue)
    }

    // MARK: - Post Tests

    func testPostInit() {
        let url = URL(string: "https://example.com/post")!
        let voteLinks = VoteLinks(upvote: URL(string: "https://example.com/upvote"), unvote: nil)

        let post = Post(
            id: 123,
            url: url,
            title: "Test Post",
            age: "2 hours ago",
            commentsCount: 5,
            by: "testuser",
            score: 10,
            postType: .news,
            upvoted: false,
            voteLinks: voteLinks
        )

        XCTAssertEqual(post.id, 123)
        XCTAssertEqual(post.url, url)
        XCTAssertEqual(post.title, "Test Post")
        XCTAssertEqual(post.age, "2 hours ago")
        XCTAssertEqual(post.commentsCount, 5)
        XCTAssertEqual(post.by, "testuser")
        XCTAssertEqual(post.score, 10)
        XCTAssertEqual(post.postType, .news)
        XCTAssertEqual(post.upvoted, false)
        XCTAssertEqual(post.voteLinks, voteLinks)
    }

    func testPostHashable() {
        let url = URL(string: "https://example.com/post")!
        let post1 = Post(
            id: 123,
            url: url,
            title: "Test Post",
            age: "2 hours ago",
            commentsCount: 5,
            by: "testuser",
            score: 10,
            postType: .news,
            upvoted: false
        )

        let post2 = Post(
            id: 123,
            url: url,
            title: "Test Post",
            age: "2 hours ago",
            commentsCount: 5,
            by: "testuser",
            score: 10,
            postType: .news,
            upvoted: false
        )

        let post3 = Post(
            id: 456,
            url: url,
            title: "Different Post",
            age: "1 hour ago",
            commentsCount: 3,
            by: "otheruser",
            score: 5,
            postType: .ask,
            upvoted: true
        )

        XCTAssertEqual(post1, post2)
        XCTAssertNotEqual(post1, post3)
        XCTAssertEqual(post1.hashValue, post2.hashValue)
    }

    // MARK: - Comment Tests

    func testCommentInit() {
        let voteLinks = VoteLinks(upvote: URL(string: "https://example.com/upvote"), unvote: nil)

        let comment = Comment(
            id: 456,
            age: "1 hour ago",
            text: "This is a test comment",
            by: "commenter",
            level: 0,
            upvoted: false,
            voteLinks: voteLinks,
            visibility: .visible
        )

        XCTAssertEqual(comment.id, 456)
        XCTAssertEqual(comment.age, "1 hour ago")
        XCTAssertEqual(comment.text, "This is a test comment")
        XCTAssertEqual(comment.by, "commenter")
        XCTAssertEqual(comment.level, 0)
        XCTAssertEqual(comment.upvoted, false)
        XCTAssertEqual(comment.voteLinks, voteLinks)
        XCTAssertEqual(comment.visibility, .visible)
    }

    func testCommentHashable() {
        let comment1 = Comment(
            id: 456,
            age: "1 hour ago",
            text: "Test comment",
            by: "user",
            level: 0,
            upvoted: false
        )

        let comment2 = Comment(
            id: 456,
            age: "1 hour ago",
            text: "Test comment",
            by: "user",
            level: 0,
            upvoted: false
        )

        let comment3 = Comment(
            id: 789,
            age: "2 hours ago",
            text: "Different comment",
            by: "otheruser",
            level: 1,
            upvoted: true
        )

        XCTAssertEqual(comment1, comment2)
        XCTAssertNotEqual(comment1, comment3)
        XCTAssertEqual(comment1.hashValue, comment2.hashValue)
    }

    // MARK: - PostType Tests

    func testPostTypeRawValues() {
        XCTAssertEqual(PostType.news.rawValue, "news")
        XCTAssertEqual(PostType.ask.rawValue, "ask")
        XCTAssertEqual(PostType.show.rawValue, "show")
        XCTAssertEqual(PostType.jobs.rawValue, "jobs")
        XCTAssertEqual(PostType.newest.rawValue, "newest")
        XCTAssertEqual(PostType.best.rawValue, "best")
        XCTAssertEqual(PostType.active.rawValue, "active")
    }

    func testPostTypeAllCases() {
        let expectedCases: [PostType] = [.news, .ask, .show, .jobs, .newest, .best, .active]
        XCTAssertEqual(PostType.allCases, expectedCases)
    }

    // MARK: - CommentVisibilityType Tests

    func testCommentVisibilityTypeRawValues() {
        XCTAssertEqual(CommentVisibilityType.visible.rawValue, 3)
        XCTAssertEqual(CommentVisibilityType.compact.rawValue, 2)
        XCTAssertEqual(CommentVisibilityType.hidden.rawValue, 1)
    }

    // MARK: - User Tests

    func testUserInit() {
        let joinDate = Date()
        let user = User(username: "testuser", karma: 1000, joined: joinDate)

        XCTAssertEqual(user.username, "testuser")
        XCTAssertEqual(user.karma, 1000)
        XCTAssertEqual(user.joined, joinDate)
    }

    // MARK: - Error Tests

    func testHackersKitError() {
        let authError = HackersKitError.authenticationError(error: .badCredentials)

        switch authError {
        case .authenticationError(let error):
            XCTAssertEqual(error, .badCredentials)
        default:
            XCTFail("Expected authentication error")
        }
    }

    func testHackersKitAuthenticationError() {
        let errors: [HackersKitAuthenticationError] = [.badCredentials, .serverUnreachable, .noInternet, .unknown]

        for error in errors {
            XCTAssertNotNil(error, "Error case should be valid")
        }
    }
}
