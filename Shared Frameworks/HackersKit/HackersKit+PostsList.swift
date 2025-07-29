//
//  HackersKit+PostsList.swift
//  Hackers
//
//  Created by Weiran Zhang on 25/05/2020.
//  Copyright © 2020 Weiran Zhang. All rights reserved.
//

import Foundation
import SwiftSoup

extension HackersKit {
    func getPosts(type: PostType, page: Int = 1, nextId: Int = 0) async throws -> [Post] {
        let html = try await fetchPostsHtml(type: type, page: page, nextId: nextId)
        let tableElement = try HtmlParser.postsTableElement(from: html)
        return try HtmlParser.posts(from: tableElement, type: type)
    }

    private func fetchPostsHtml(type: PostType, page: Int, nextId: Int) async throws -> String {
        var url: URL
        if type == .newest || type == .jobs {
            url = URL(string: "https://news.ycombinator.com/\(type.rawValue)?next=\(nextId)")!
        } else if type == .active {
            url = URL(string: "https://news.ycombinator.com/active?p=\(page)")!
        } else {
            url = URL(string: "https://news.ycombinator.com/\(type.rawValue)?p=\(page)")!
        }
        return try await fetchHtml(url: url)
    }
}
