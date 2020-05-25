//
//  HackerNewsData+PostVoting.swift
//  Hackers
//
//  Created by Weiran Zhang on 25/05/2020.
//  Copyright © 2020 Weiran Zhang. All rights reserved.
//

import Foundation
import PromiseKit

extension HackerNewsData {
    public func upvote(post: HackerNewsPost) -> Promise<Void> {
        let scraperShim = HNScraperShim()

        return firstly {
            scraperShim.getPost(id: post.id)
        }.then { post in
            scraperShim.upvote(post: post)
        }
    }

    public func unvote(post: HackerNewsPost) -> Promise<Void> {
        let scraperShim = HNScraperShim()

        return firstly {
            scraperShim.getPost(id: post.id)
        }.then { post in
            scraperShim.unvote(post: post)
        }
    }
}
