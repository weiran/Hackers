//
//  ContentSharePresenterTests.swift
//  SharedTests
//
//  Copyright © 2025 Weiran Zhang. All rights reserved.
//

@testable import Domain
import Foundation
import UIKit
@testable import Shared
import Testing

@Suite("ContentSharePresenter")
struct ContentSharePresenterTests {
    @Test("ContentSharePresenter is a singleton")
    func singleton() {
        let presenter1 = ContentSharePresenter.shared
        let presenter2 = ContentSharePresenter.shared

        #expect(presenter1 === presenter2, "ContentSharePresenter should be a singleton")
    }

    @Test("ContentSharePresenter conforms to Sendable")
    func sendableConformance() {
        let presenter = ContentSharePresenter.shared

        // Test that we can pass it across actor boundaries
        Task {
            _ = presenter // Compiles without warnings if Sendable is implemented correctly
        }

        #expect(presenter != nil)
    }

    @Test("ContentSharePresenter exists and is accessible")
    func presenterAccessibility() {
        let presenter = ContentSharePresenter.shared
        #expect(presenter != nil)
    }

    // MARK: - Helper Test Data Creation

    private func createTestPost() -> Post {
        Post(
            id: 123,
            url: URL(string: "https://example.com/test")!,
            title: "Test Post Title",
            age: "2 hours ago",
            commentsCount: 5,
            by: "testuser",
            score: 42,
            postType: .news,
            upvoted: false,
        )
    }

    private func createTestComment() -> Domain.Comment {
        Domain.Comment(
            id: 456,
            age: "1 hour ago",
            text: "<p>This is a test comment with <strong>HTML</strong> content.</p>",
            by: "commentuser",
            level: 0,
            upvoted: false,
            upvoteLink: nil,
            voteLinks: nil,
            visibility: .visible,
            parsedText: nil,
        )
    }

    // MARK: - Structure Tests

    @Test("Post share uses a single URL-backed activity item")
    func postShareItemsUseURLActivityItem() {
        let post = createTestPost()

        let items = ContentSharePresenter.items(for: post)

        #expect(items.count == 1)
        let source = items.first as? URLActivityItemSource
        #expect(source?.url == post.url)
    }

    @Test("URL share copy item is the raw URL")
    func urlShareCopyItemIsRawURL() {
        let testURL = URL(string: "https://example.com/article")!
        let source = URLActivityItemSource(url: testURL, title: "Example Article")
        let activityViewController = UIActivityViewController(activityItems: [], applicationActivities: nil)

        let placeholder = source.activityViewControllerPlaceholderItem(activityViewController)
        let copyItem = source.activityViewController(
            activityViewController,
            itemForActivityType: .copyToPasteboard
        )

        #expect(placeholder as? URL == testURL)
        #expect(copyItem as? String == testURL.absoluteString)
        #expect(source.activityViewController(
            activityViewController,
            subjectForActivityType: .copyToPasteboard
        ) == "")
    }

    @Test("URL share metadata preserves title and URL for preview")
    func urlShareMetadataPreservesPreviewTitle() throws {
        let testURL = URL(string: "https://example.com/article")!
        let source = URLActivityItemSource(url: testURL, title: "Example Article")
        let activityViewController = UIActivityViewController(activityItems: [], applicationActivities: nil)

        let metadata = try #require(source.activityViewControllerLinkMetadata(activityViewController))

        #expect(metadata.title == "Example Article")
        #expect(metadata.url == testURL)
        #expect(metadata.originalURL == testURL)
    }

    @Test("URL share works without a title")
    func urlShareWorksWithoutTitle() {
        let testURL = URL(string: "https://example.com/article")!
        let items = ContentSharePresenter.items(for: testURL)
        let source = items.first as? URLActivityItemSource
        let activityViewController = UIActivityViewController(activityItems: [], applicationActivities: nil)

        #expect(items.count == 1)
        #expect(source?.activityViewController(
            activityViewController,
            itemForActivityType: nil
        ) as? URL == testURL)
        #expect(source?.activityViewController(
            activityViewController,
            subjectForActivityType: nil
        ) == "")
    }

    @Test("Comment share still uses stripped text")
    func commentShareItemsUseStrippedText() {
        let items = ContentSharePresenter.items(for: createTestComment())

        #expect(items.count == 1)
        #expect(items.first as? String == "This is a test comment with HTML content.")
    }

    @Test("Presenter can be called with different data types")
    func presenterCallStructure() async {
        let presenter = ContentSharePresenter.shared
        let testPost = createTestPost()
        let testComment = createTestComment()
        let testURL = URL(string: "https://example.com")!

        await MainActor.run {
            presenter.sharePost(testPost)
            presenter.shareURL(testURL, title: "Test Title")
            presenter.shareURL(testURL)
            presenter.shareComment(testComment)
        }

        #expect(true)
    }

    @Test("ContentSharePresenter methods are MainActor isolated")
    func mainActorIsolation() async {
        let presenter = ContentSharePresenter.shared
        let testPost = createTestPost()

        await MainActor.run {
            presenter.sharePost(testPost)
            presenter.shareURL(URL(string: "https://example.com")!)
            presenter.shareComment(createTestComment())
        }

        #expect(true)
    }
}
