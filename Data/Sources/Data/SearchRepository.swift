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
        static let endpoint = "https://hn.algolia.com/api/v1/search"
    }

    private let networkManager: NetworkManagerProtocol
    private let decoder: JSONDecoder
    private let relativeFormatter: RelativeDateTimeFormatter

    public init(networkManager: NetworkManagerProtocol = NetworkManager()) {
        self.networkManager = networkManager
        decoder = JSONDecoder()
        relativeFormatter = RelativeDateTimeFormatter()
        relativeFormatter.unitsStyle = .full
    }

    public func searchPosts(query: String) async throws -> [Post] {
        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "\(Constants.endpoint)?query=\(encodedQuery)&tags=story")
        else {
            throw HackersKitError.requestFailure
        }

        let responseString = try await networkManager.get(url: url)
        guard let data = responseString.data(using: .utf8) else {
            throw HackersKitError.requestFailure
        }

        let response = try decoder.decode(SearchResponse.self, from: data)
        return response.hits.compactMap { hit in
            guard let postID = Int(hit.objectID) else { return nil }

            let url = hit.url.flatMap(URL.init(string:))
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
    }
}

private extension SearchRepository {
    struct SearchResponse: Decodable {
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
        return relativeFormatter.localizedString(for: date, relativeTo: Date())
    }
}
