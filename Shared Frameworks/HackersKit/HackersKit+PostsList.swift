//
//  HackersKit+PostsList.swift
//  Hackers
//
//  Created by Weiran Zhang on 25/05/2020.
//  Copyright © 2020 Weiran Zhang. All rights reserved.
//

import Foundation
import PromiseKit
import SwiftSoup

extension HackersKit {
    func getPosts(type: PostType, page: Int = 1) -> Promise<[Post]> {
        firstly {
            fetchPostsHtml(type: type, page: page)
        }.map { html in
            try HtmlParser.postsTableElement(from: html)
        }.compactMap { tableElement in
            try HtmlParser.posts(from: tableElement, type: type)
        }
    }

    private func fetchPostsHtml(type: PostType, page: Int) -> Promise<String> {
        let url = URL(string: "https://news.ycombinator.com/\(type.rawValue)?p=\(page)")!
        return fetchHtml(url: url)
    }
}
