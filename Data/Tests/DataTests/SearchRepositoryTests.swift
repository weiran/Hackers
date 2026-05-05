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
        {"nbHits":41,"page":0,"nbPages":3,"hitsPerPage":20,"hits":[{"objectID":"123","title":"Swift","url":"https://example.com","points":42,"author":"tester","num_comments":7,"created_at_i": 0}]}
        """
        let repository = SearchRepository(
            networkManager: mockNetwork,
            currentDate: { Date(timeIntervalSince1970: 86_400) }
        )

        let page = try await repository.searchPosts(
            query: "swift",
            sort: .popular,
            dateRange: .allTime,
            page: 0,
            hitsPerPage: 20
        )

        #expect(mockNetwork.lastURL?.path == "/api/v1/search")
        #expect(mockNetwork.lastQueryItems["query"] == "swift")
        #expect(mockNetwork.lastQueryItems["tags"] == "story")
        #expect(mockNetwork.lastQueryItems["page"] == "0")
        #expect(mockNetwork.lastQueryItems["hitsPerPage"] == "20")
        #expect(page.posts.count == 1)
        #expect(page.page == 0)
        #expect(page.totalPages == 3)
        #expect(page.totalResults == 41)
        #expect(page.hasMore)
        let post = try #require(page.posts.first)
        #expect(post.id == 123)
        #expect(post.title == "Swift")
        #expect(post.url.absoluteString == "https://example.com")
        #expect(post.score == 42)
        #expect(post.commentsCount == 7)
        #expect(post.by == "tester")
        #expect(post.isBookmarked == false)
        #expect(!post.age.isEmpty)
    }

    @Test("Recent search uses search by date endpoint")
    func recentSearchUsesSearchByDateEndpoint() async throws {
        let mockNetwork = MockNetworkManager()
        mockNetwork.nextResponse = emptyResponse(page: 0, totalPages: 1)
        let repository = SearchRepository(networkManager: mockNetwork)

        _ = try await repository.searchPosts(
            query: "swift",
            sort: .recent,
            dateRange: .allTime,
            page: 0,
            hitsPerPage: 20
        )

        #expect(mockNetwork.lastURL?.path == "/api/v1/search_by_date")
    }

    @Test("Date ranges add created at numeric filter")
    func dateRangesAddNumericFilter() async throws {
        let mockNetwork = MockNetworkManager()
        mockNetwork.nextResponse = emptyResponse(page: 0, totalPages: 1)
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let repository = SearchRepository(networkManager: mockNetwork, currentDate: { now })

        _ = try await repository.searchPosts(
            query: "swift",
            sort: .popular,
            dateRange: .pastWeek,
            page: 2,
            hitsPerPage: 10
        )

        let expectedCutoff = 1_700_000_000 - (7 * 24 * 60 * 60)
        #expect(mockNetwork.lastQueryItems["numericFilters"] == "created_at_i>\(expectedCutoff)")
        #expect(mockNetwork.lastQueryItems["page"] == "2")
        #expect(mockNetwork.lastQueryItems["hitsPerPage"] == "10")
    }

    @Test("Final search page reports no more results")
    func finalPageHasNoMoreResults() async throws {
        let mockNetwork = MockNetworkManager()
        mockNetwork.nextResponse = emptyResponse(page: 2, totalPages: 3)
        let repository = SearchRepository(networkManager: mockNetwork)

        let page = try await repository.searchPosts(
            query: "swift",
            sort: .popular,
            dateRange: .allTime,
            page: 2,
            hitsPerPage: 20
        )

        #expect(page.page == 2)
        #expect(page.totalPages == 3)
        #expect(page.hasMore == false)
    }

    @Test("Throws on invalid JSON")
    func throwsOnInvalidJSON() async {
        let mockNetwork = MockNetworkManager()
        mockNetwork.nextResponse = "{" // malformed
        let repository = SearchRepository(networkManager: mockNetwork)

        await #expect(throws: Error.self) {
            _ = try await repository.searchPosts(
                query: "swift",
                sort: .popular,
                dateRange: .allTime,
                page: 0,
                hitsPerPage: 20
            )
        }
    }
}

private func emptyResponse(page: Int, totalPages: Int) -> String {
    """
    {"nbHits":0,"page":\(page),"nbPages":\(totalPages),"hitsPerPage":20,"hits":[]}
    """
}

private final class MockNetworkManager: NetworkManagerProtocol, @unchecked Sendable {
    var nextResponse: String = "{}"
    var lastURL: URL?
    var lastQueryItems: [String: String] {
        guard let lastURL,
              let components = URLComponents(url: lastURL, resolvingAgainstBaseURL: false)
        else { return [:] }
        return Dictionary(uniqueKeysWithValues: components.queryItems?.compactMap { item in
            item.value.map { (item.name, $0) }
        } ?? [])
    }

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
