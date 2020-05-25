//
//  HackerNewsDataProtocol.swift
//  Hackers
//
//  Created by Weiran Zhang on 11/05/2020.
//  Copyright © 2020 Glass Umbrella. All rights reserved.
//

import Foundation
import PromiseKit
import SwiftSoup

protocol HackerNewsDataProtocol {

}

enum HackerNewsPath: String {
    case new = "newstories.json"
    case top = "topstories.json"
    case best = "beststories.json"
    case ask = "askstories.json"
    case show = "showstories.json"
    case jobs = "jobsstories.json"
}

struct HNPath {
    let new = "v0/newstories.json"
    func item(id: Int) -> String {
        return "item/\(id).json"
    }
}

class HackerNewsData {
    public static let shared = HackerNewsData()

    let session = URLSession(configuration: .default)
    let firebaseURL = URL(string: "https://hacker-news.firebaseio.com/v0/")!
    let agoliaURL = URL(string: "https://hn.algolia.com/api/v1/")!

    init() { }

    public func getPosts(type: HackerNewsPath, page: Int = 0) -> Promise<[HackerNewsPost]> {
        let pageLimit = 25

        return firstly {
            getIds(type: type)
        }.compactMap { ids in
            if page == 0 {
                return Array(ids.prefix(pageLimit))
            } else {
                let start = pageLimit * page
                let end = start + pageLimit
                return Array(ids[start...end])
            }
        }.then { ids in
            self.getItems(for: ids)
        }.map { items in
            items.compactMap { item in
                HackerNewsPost(item)
            }
        }
    }

    public func getHTMLComments(postId: Int) -> Promise<[HackerNewsComment]> {
        firstly {
            getHackerNewsHTML(id: postId)
        }.map { html in
            try self.commentElements(from: html)
        }.map { elements in
            elements.compactMap { element in
                try? self.comment(from: element)
            }
        }
    }

    private func commentElements(from data: String) throws -> Elements {
        let document = try SwiftSoup.parse(data)
        return try document.select(".comtr")
    }

    private func comment(from element: Element) throws -> HackerNewsComment {
        let text = try commentText(from: element.select(".commtext"))
        let age = try element.select(".age").text()
        let user = try element.select(".hnuser").text()
        guard let id = try Int(element.select(".comtr").attr("id")) else {
            throw Exception.Error(type: .SelectorParseException, Message: "Couldn't parse comment id")
        }
        guard let indentWidth = try Int(element.select(".ind img").attr("width")) else {
            throw Exception.Error(type: .SelectorParseException, Message: "Couldn't parse comment indent width")
        }
        let level = indentWidth / 40
        let upvoteLink = try element.select(".votelinks a").attr("href")

        let comment = HackerNewsComment(id: id, age: age, text: text, by: user, level: level)
        comment.upvoteLink = upvoteLink
        return comment
    }

    private func commentText(from elements: Elements) throws -> String {
        if let replyElement = try? elements.select(".reply") {
            try replyElement.html("")
        }
        return try elements.html()
    }

    func getHackerNewsHTML(id: Int) -> Promise<String> {
        let (promise, seal) = Promise<String>.pending()

        let url = URL(string: "https://news.ycombinator.com/item?id=\(id)")!
        session.dataTask(with: url) { data, _, error in
            if let data = data, let ids = String(bytes: data, encoding: .utf8) {
                seal.fulfill(ids)
            } else if let error = error {
                seal.reject(error)
            } else {
                seal.reject(HackerNewsError.typeError)
            }
        }.resume()

        return promise
    }

    public func getComments(postId: Int) -> Promise<[HackerNewsRawItem]> {
        func test(items: [HackerNewsRawItem]) -> Promise<[HackerNewsRawItem]> {
            func flattenItems(_ items: [HackerNewsRawItem]) -> [Int] {
                var flatItems = [Int]()
                items.forEach { item in
                    guard let kids = item.kids else { return }
                    flatItems.append(contentsOf: kids)
                }
                return flatItems
            }
            let flatChildren = flattenItems(items)
            let promises = flatChildren.map { self.getItem(for: $0) } as [Promise<HackerNewsRawItem>]
            return when(fulfilled: promises)
        }

        return firstly {
            getItem(for: postId)
        }.compactMap { item in
            return item.kids
        }.then { ids in
            self.getItems(for: ids)
        }
        .then { items in
            test(items: items)
        }
    }

    public func getPost(postId: Int) -> Promise<AgoliaRawItem> {
        let (promise, seal) = Promise<AgoliaRawItem>.pending()

        let url = URL(string: "items/\(postId)", relativeTo: agoliaURL)!
        session.dataTask(with: url) { data, _, error in
            let decoder = JSONDecoder()
            do {
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                decoder.dateDecodingStrategy = .formatted(DateFormatter.iso8601Full)
                try decoder.decode(AgoliaRawItem.self, from: data!)
            } catch {
                print(error.localizedDescription)
            }

            if let data = data, let item = try? decoder.decode(AgoliaRawItem.self, from: data) {
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

extension DateFormatter {
  static let iso8601Full: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
    formatter.calendar = Calendar(identifier: .iso8601)
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    formatter.locale = Locale(identifier: "en_US_POSIX")
    return formatter
  }()
}


extension HackerNewsData { // all private methods
    private func route(for path: String, limit: Int? = nil, orderBy: String? = "\"$key\"") -> String {
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
        urlComponents.path = "/v0/\(path)"
        urlComponents.setQueryItems(with: queryParameters)
        return urlComponents.string!
    }

    private func getIds(type: HackerNewsPath) -> Promise<[Int]> {
        let (promise, seal) = Promise<[Int]>.pending()

        let route = self.route(for: type.rawValue)
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

    func getItems(for ids: [Int]) -> Promise<[HackerNewsRawItem]> {
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

        let url = URL(string: "item/\(id).json", relativeTo: firebaseURL)!
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

struct AgoliaRawItem: Codable {
    let id: Int
    let createdAt: Date
    let author: String?
    let title: String?
    let url: String?
    let text: String?
    let points: Int?
    let parentId: Int?
    let children: [AgoliaRawItem]?
}

class HackerNewsPost {
    let id: Int
    let url: URL
    let title: String
    let date: Date
    let commentsCount: Int
    let by: String
    var score: Int
    let postType: HackerNewsPostType

    // not from API
    var upvoted: Bool = false

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

class HackerNewsComment {
    let id: Int
    let age: String
    var children: [HackerNewsComment]?
    let text: String
    let by: String
    var level: Int
    var upvoteLink: String?

    // UI properties
    var visibility = CommentVisibilityType.visible
    var upvoted = false

    init(id: Int, age: String, text: String, by: String, level: Int) {
        self.id = id
        self.age = age
        self.text = text
        self.by = by
        self.level = level
    }
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
