//
//  ModelsTests.swift
//  DomainTests
//
//  Copyright © 2025 Weiran Zhang. All rights reserved.
//

// swiftlint:disable force_cast

import Testing
import Foundation
@testable import Domain

@Suite("Model Tests")
struct ModelsTests {

    // MARK: - VoteLinks Tests

    @Test("VoteLinks initializes with correct properties")
    func voteLinksInit() {
        let upvoteURL = URL(string: "https://example.com/upvote")
        let unvoteURL = URL(string: "https://example.com/unvote")

        let voteLinks = VoteLinks(upvote: upvoteURL, unvote: unvoteURL)

        #expect(voteLinks.upvote == upvoteURL)
        #expect(voteLinks.unvote == unvoteURL)
    }

    @Test("VoteLinks implements Hashable correctly")
    func voteLinksHashable() {
        let upvoteURL = URL(string: "https://example.com/upvote")
        let unvoteURL = URL(string: "https://example.com/unvote")

        let voteLinks1 = VoteLinks(upvote: upvoteURL, unvote: unvoteURL)
        let voteLinks2 = VoteLinks(upvote: upvoteURL, unvote: unvoteURL)
        let voteLinks3 = VoteLinks(upvote: nil, unvote: unvoteURL)

        #expect(voteLinks1 == voteLinks2)
        #expect(voteLinks1 != voteLinks3)
        #expect(voteLinks1.hashValue == voteLinks2.hashValue)
    }

    // MARK: - Post Tests

    @Test("Post initializes with correct properties")
    func postInit() {
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

        #expect(post.id == 123)
        #expect(post.url == url)
        #expect(post.title == "Test Post")
        #expect(post.age == "2 hours ago")
        #expect(post.commentsCount == 5)
        #expect(post.by == "testuser")
        #expect(post.score == 10)
        #expect(post.postType == .news)
        #expect(post.upvoted == false)
        #expect(post.voteLinks == voteLinks)
    }

    @Test("Post implements Hashable correctly")
    func postHashable() {
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

        #expect(post1 == post2)
        #expect(post1 != post3)
        #expect(post1.hashValue == post2.hashValue)
    }

    // MARK: - Comment Tests

    @Test("Comment initializes with correct properties")
    func commentInit() {
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

        #expect(comment.id == 456)
        #expect(comment.age == "1 hour ago")
        #expect(comment.text == "This is a test comment")
        #expect(comment.by == "commenter")
        #expect(comment.level == 0)
        #expect(comment.upvoted == false)
        #expect(comment.voteLinks == voteLinks)
        #expect(comment.visibility == .visible)
    }

    @Test("Comment implements Hashable correctly")
    func commentHashable() {
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

        #expect(comment1 == comment2)
        #expect(comment1 != comment3)
        #expect(comment1.hashValue == comment2.hashValue)
    }

    // MARK: - PostType Tests

    @Test("PostType raw values match expected strings")
    func postTypeRawValues() {
        #expect(PostType.news.rawValue == "news")
        #expect(PostType.ask.rawValue == "ask")
        #expect(PostType.show.rawValue == "show")
        #expect(PostType.jobs.rawValue == "jobs")
        #expect(PostType.newest.rawValue == "newest")
        #expect(PostType.best.rawValue == "best")
        #expect(PostType.active.rawValue == "active")
    }

    @Test("PostType allCases contains all expected cases")
    func postTypeAllCases() {
        let expectedCases: [PostType] = [.news, .ask, .show, .jobs, .newest, .best, .active]
        #expect(PostType.allCases == expectedCases)
    }

    // MARK: - CommentVisibilityType Tests

    @Test("CommentVisibilityType raw values match expected integers")
    func commentVisibilityTypeRawValues() {
        #expect(CommentVisibilityType.visible.rawValue == 3)
        #expect(CommentVisibilityType.compact.rawValue == 2)
        #expect(CommentVisibilityType.hidden.rawValue == 1)
    }

    // MARK: - User Tests

    @Test("User initializes with correct properties")
    func userInit() {
        let joinDate = Date()
        let user = User(username: "testuser", karma: 1000, joined: joinDate)

        #expect(user.username == "testuser")
        #expect(user.karma == 1000)
        #expect(user.joined == joinDate)
    }

    // MARK: - Error Tests

    @Test("HackersKitError handles authentication errors correctly")
    func hackersKitError() {
        let authError = HackersKitError.authenticationError(error: .badCredentials)

        switch authError {
        case .authenticationError(let error):
            #expect(error == .badCredentials)
        default:
            Issue.record("Expected authentication error")
        }
    }

    @Test("HackersKitAuthenticationError cases are valid")
    func hackersKitAuthenticationError() {
        let errors: [HackersKitAuthenticationError] = [.badCredentials, .serverUnreachable, .noInternet, .unknown]

        for error in errors {
            #expect(error != nil, "Error case should be valid")
        }
    }
}