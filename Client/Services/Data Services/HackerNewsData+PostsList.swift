//
//  HackerNewsData+PostsList.swift
//  Hackers
//
//  Created by Weiran Zhang on 25/05/2020.
//  Copyright © 2020 Weiran Zhang. All rights reserved.
//

import Foundation
import PromiseKit
import SwiftSoup

extension HackerNewsData {
    public func getPosts(type: HackerNewsPostType, page: Int = 1) -> Promise<[HackerNewsPost]> {
        firstly {
            fetchPostsHtml(type: type, page: page)
        }.map { html in
            try HackerNewsHtmlParser.postsTableElement(from: html)
        }.map { tableElement in
            try HackerNewsHtmlParser.posts(from: tableElement, type: type)
        }
    }

    private func fetchPostsHtml(type: HackerNewsPostType, page: Int) -> Promise<String> {
        let url = URL(string: "https://news.ycombinator.com/\(type.rawValue)?p=\(page)")!
        return fetchHtml(url: url)
    }
}
