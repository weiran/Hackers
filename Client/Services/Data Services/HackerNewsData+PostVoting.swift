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
    public func upvote(comment: HackerNewsComment, for post: HackerNewsPost) -> Promise<Void> {
        let scraperShim = HNScraperShim()

        return firstly {
            scraperShim.getComment(id: comment.id, for: post.id)
        }.then { comment in
            scraperShim.upvote(comment: comment)
        }
    }

    public func unvote(comment: HackerNewsComment, for post: HackerNewsPost) -> Promise<Void> {
        let scraperShim = HNScraperShim()

        return firstly {
            scraperShim.getComment(id: comment.id, for: post.id)
        }.then { comment in
            scraperShim.unvote(comment: comment)
        }
    }
}
