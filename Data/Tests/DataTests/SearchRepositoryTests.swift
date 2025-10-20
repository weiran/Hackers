//
//  SearchRepositoryTests.swift
//  DataTests
//

@testable import Data
import Domain
import Foundation
import Networking
import Testing

@Suite("SearchRepository")
struct SearchRepositoryTests {
    @Test("Decodes search hits into posts")
    func decodesHits() async throws {
        let mockNetwork = MockNetworkManager()
        mockNetwork.nextResponse = """
        {"hits":[{"objectID":"123","title":"Swift","url":"https://example.com","points":42,"author":"tester","num_comments":7,"created_at_i": 0}]}
        """
        let repository = SearchRepository(networkManager: mockNetwork)

        let posts = try await repository.searchPosts(query: "swift")

        #expect(mockNetwork.lastURL?.absoluteString.contains("swift") == true)
        #expect(posts.count == 1)
        let post = try #require(posts.first)
        #expect(post.id == 123)
        #expect(post.title == "Swift")
        #expect(post.url.absoluteString == "https://example.com")
        #expect(post.score == 42)
        #expect(post.commentsCount == 7)
        #expect(post.by == "tester")
        #expect(post.isBookmarked == false)
        #expect(!post.age.isEmpty)
    }

    @Test("Throws on invalid JSON")
    func throwsOnInvalidJSON() async {
        let mockNetwork = MockNetworkManager()
        mockNetwork.nextResponse = "{" // malformed
        let repository = SearchRepository(networkManager: mockNetwork)

        await #expect(throws: Error.self) {
            _ = try await repository.searchPosts(query: "swift")
        }
    }
}

private final class MockNetworkManager: NetworkManagerProtocol, @unchecked Sendable {
    var nextResponse: String = "{}"
    var lastURL: URL?

    func get(url: URL) async throws -> String {
        lastURL = url
        return nextResponse
    }

    func post(url _: URL, body _: String) async throws -> String {
        fatalError("Not implemented in mock")
    }

    func clearCookies() {}

    func containsCookie(for _: URL) -> Bool { false }
}
