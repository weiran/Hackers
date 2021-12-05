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
    func getPosts(type: PostType, page: Int = 1, nextId: Int = 0) -> Promise<[Post]> {
        firstly {
            fetchPostsHtml(type: type, page: page, nextId: nextId)
        }.map { html in
            try HtmlParser.postsTableElement(from: html)
        }.compactMap { tableElement in
            try HtmlParser.posts(from: tableElement, type: type)
        }
    }

    private func fetchPostsHtml(type: PostType, page: Int, nextId: Int) -> Promise<String> {
        var url: URL
        if type == .newest || type == .jobs {
            url = URL(string: "https://news.ycombinator.com/\(type.rawValue)?next=\(nextId)")!
        } else {
            url = URL(string: "https://news.ycombinator.com/\(type.rawValue)?p=\(page)")!
        }
        return fetchHtml(url: url)
    }
}
