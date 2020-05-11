//
//  HackerNewsDataProtocol.swift
//  Hackers
//
//  Created by Weiran Zhang on 11/05/2020.
//  Copyright © 2020 Glass Umbrella. All rights reserved.
//

import Foundation
import PromiseKit

protocol HackerNewsDataProtocol {

}

enum HackerNewsPath: String {
    case new = "v0/newstories.json"
    case top = "v0/topstories.json"
    case best = "v0/beststories.json"
    case ask = "v0/askstories.json"
    case show = "v0/showstories.json"
    case jobs = "v0/jobsstories.json"
}

class HackerNewsData {
    public static let shared = HackerNewsData()

    let session = URLSession(configuration: .default)
    let baseURL = URL(string: "https://hacker-news.firebaseio.com/")!

    init() {

    }

    public func getPosts(type: HackerNewsPath) -> Promise<[HackerNewsPost]> {
        return firstly {
            getIds(type: type)
        }.then { ids in
            self.getItems(for: ids)
        }.map { items in
            items.compactMap { item in
                return HackerNewsPost(item)
            }
        }
    }
}

extension HackerNewsData { // all private methods
    private func route(for path: HackerNewsPath, limit: Int? = nil, orderBy: String? = "\"$key\"") -> String {
        var queryParameters: [String: String] = [String: String]()
        if let limit = limit {
            queryParameters["limitToFirst"] = String(limit)
        }
        if let orderBy = orderBy {
            queryParameters["orderBy"] = orderBy
        }

        var urlComponents = URLComponents()
        urlComponents.scheme = "https"
        urlComponents.host = "hacker-news.firebaseio.com"
        urlComponents.path = "/\(path.rawValue)"
        urlComponents.setQueryItems(with: queryParameters)
        return urlComponents.string!
    }

    private func getIds(type: HackerNewsPath) -> Promise<[Int]> {
        let (promise, seal) = Promise<[Int]>.pending()

        let route = self.route(for: type, limit: 25)
        let url = URL(string: route)!
        session.dataTask(with: url) { data, _, error in
            if let data = data, let ids = try? JSONDecoder().decode([Int].self, from: data) {
                seal.fulfill(ids)
            } else if let error = error {
                seal.reject(error)
            } else {
                seal.reject(HackerNewsError.typeError)
            }
        }.resume()

        return promise
    }

    private func getItems(for ids: [Int]) -> Promise<[HackerNewsRawItem]> {
        let (promise, seal) = Promise<[HackerNewsRawItem]>.pending()
        let itemPromises = ids.map { id in
            return getItem(for: id)
        }

        firstly {
            when(fulfilled: itemPromises)
        }.done { items in
            seal.fulfill(items)
        }.catch { error in
            seal.reject(error)
        }

        return promise
    }

    private func getItem(for id: Int) -> Promise<HackerNewsRawItem> {
        let (promise, seal) = Promise<HackerNewsRawItem>.pending()

        let url = URL(string: "v0/item/\(id).json", relativeTo: baseURL)!
        session.dataTask(with: url) { data, _, error in
            if let data = data, let item = try? JSONDecoder().decode(HackerNewsRawItem.self, from: data) {
                seal.fulfill(item)
            } else if let error = error {
                seal.reject(error)
            } else {
                seal.reject(HackerNewsError.typeError)
            }
        }.resume()

        return promise
    }
}

enum HackerNewsError: Error {
    case typeError
}

struct HackerNewsRawItem: Codable {
    let id: Int?
    let url: String?
    let title: String?
    let time: Int?
    let descendants: Int?
    let score: Int?
    let by: String?
    let text: String?
    let parent: Int?
    let kids: [Int]?
    let type: String?
}

struct HackerNewsPost {
    let id: Int
    let url: URL
    let title: String
    let date: Date
    let commentsCount: Int
    let by: String
    let score: Int
    let postType: HackerNewsPostType

    init?(_ item: HackerNewsRawItem) {
        guard let id = item.id,
            let urlString = item.url,
            let url = URL(string: urlString),
            let title = item.title,
            let time = item.time,
            let commentsCount = item.descendants,
            let by = item.by,
            let score = item.score else {
                return nil
        }

        self.id = id
        self.url = url
        self.title = title
        self.date = Date(timeIntervalSince1970: Double(time))
        self.commentsCount = commentsCount
        self.by = by
        self.score = score
        self.postType = .standard // TODO fix this
    }
}

struct HackerNewsComment {
    let id: Int
    let date: Date
    let kids: [HackerNewsComment]?
    let text: String
    let by: String
}

extension HackerNewsRawItem: Equatable {
    public static func == (lhs: HackerNewsRawItem, rhs: HackerNewsRawItem) -> Bool {
        return lhs.id == rhs.id
    }
}

enum HackerNewsItemType {
    case story
    case comment
    case job
    case poll
    case pollopt
}

enum HackerNewsPostType {
    case standard
    case ask
    case job
}

extension URLComponents {
    mutating func setQueryItems(with parameters: [String: String]) {
        self.queryItems = parameters.map { URLQueryItem(name: $0.key, value: $0.value) }
    }
}
