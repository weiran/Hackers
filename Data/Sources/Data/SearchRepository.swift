//
//  SearchRepository.swift
//  Data
//
//  Provides Hacker News search via the Algolia API.
//

import Domain
import Foundation
import Networking

public final class SearchRepository: SearchUseCase, @unchecked Sendable {
    private enum Constants {
        static let popularEndpoint = "https://hn.algolia.com/api/v1/search"
        static let recentEndpoint = "https://hn.algolia.com/api/v1/search_by_date"
    }

    private let networkManager: NetworkManagerProtocol
    private let decoder: JSONDecoder
    private let relativeFormatter: RelativeDateTimeFormatter
    private let currentDate: @Sendable () -> Date

    public init(
        networkManager: NetworkManagerProtocol = NetworkManager(),
        currentDate: @escaping @Sendable () -> Date = Date.init
    ) {
        self.networkManager = networkManager
        self.currentDate = currentDate
        decoder = JSONDecoder()
        relativeFormatter = RelativeDateTimeFormatter()
        relativeFormatter.unitsStyle = .full
    }

    public func searchPosts(
        query: String,
        sort: SearchSort,
        dateRange: SearchDateRange,
        page: Int,
        hitsPerPage: Int
    ) async throws -> SearchResultsPage {
        let endpoint = sort == .popular ? Constants.popularEndpoint : Constants.recentEndpoint
        guard var components = URLComponents(string: endpoint) else {
            throw HackersKitError.requestFailure
        }
        var queryItems = [
            URLQueryItem(name: "query", value: query),
            URLQueryItem(name: "tags", value: "story"),
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "hitsPerPage", value: String(hitsPerPage)),
        ]
        if let cutoff = cutoffTimestamp(for: dateRange) {
            queryItems.append(URLQueryItem(name: "numericFilters", value: "created_at_i>\(cutoff)"))
        }
        components.queryItems = queryItems

        guard let url = components.url else { throw HackersKitError.requestFailure }

        let responseString = try await networkManager.get(url: url)
        guard let data = responseString.data(using: .utf8) else {
            throw HackersKitError.requestFailure
        }

        let response = try decoder.decode(SearchResponse.self, from: data)
        let posts: [Post] = response.hits.compactMap { hit in
            guard let postID = Int(hit.objectID) else { return nil }

            let url = hit.url.flatMap { URL(string: $0) }
                ?? URL(string: "https://news.ycombinator.com/item?id=\(hit.objectID)")!
            let age = ageString(from: hit.createdAt)

            return Post(
                id: postID,
                url: url,
                title: hit.title ?? "(no title)",
                age: age,
                commentsCount: hit.commentsCount ?? 0,
                by: hit.author ?? "unknown",
                score: hit.points ?? 0,
                postType: .news,
                upvoted: false,
                isBookmarked: false,
                voteLinks: nil,
                text: hit.storyText
            )
        }
        return SearchResultsPage(
            posts: posts,
            page: response.page,
            totalPages: response.nbPages,
            totalResults: response.nbHits,
            hasMore: response.page + 1 < response.nbPages
        )
    }
}

private extension SearchRepository {
    struct SearchResponse: Decodable {
        let nbHits: Int
        let page: Int
        let nbPages: Int
        let hitsPerPage: Int
        let hits: [Hit]
    }

    struct Hit: Decodable {
        let objectID: String
        let title: String?
        let url: String?
        let points: Int?
        let author: String?
        let num_comments: Int?
        let created_at_i: TimeInterval?
        let story_text: String?

        var commentsCount: Int? { num_comments }
        var createdAt: TimeInterval { created_at_i ?? Date().timeIntervalSince1970 }
        var storyText: String? { story_text }
    }

    func ageString(from timestamp: TimeInterval) -> String {
        let date = Date(timeIntervalSince1970: timestamp)
        return relativeFormatter.localizedString(for: date, relativeTo: currentDate())
    }

    func cutoffTimestamp(for dateRange: SearchDateRange) -> Int? {
        let seconds: TimeInterval
        switch dateRange {
        case .allTime:
            return nil
        case .last24Hours:
            seconds = 24 * 60 * 60
        case .pastWeek:
            seconds = 7 * 24 * 60 * 60
        case .pastMonth:
            seconds = 30 * 24 * 60 * 60
        case .pastYear:
            seconds = 365 * 24 * 60 * 60
        }
        return Int(currentDate().timeIntervalSince1970 - seconds)
    }
}
