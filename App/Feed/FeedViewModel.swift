//
//  FeedViewModel.swift
//  Hackers
//
//  Created by Weiran Zhang on 06/07/2020.
//  Copyright © 2020 Weiran Zhang. All rights reserved.
//

import UIKit
import PromiseKit

class FeedViewModel {
    var posts: [Post] = []
    var postIds: Set<Int> = Set()
    var postType: PostType = .news
    var pageIndex = 1
    var isFetching = false

    func fetchFeed(fetchNextPage: Bool = false) -> Promise<Void> {
        guard !isFetching else {
            return Promise.value(())
        }

        if fetchNextPage {
            pageIndex += 1
        }

        isFetching = true

        return firstly {
            HackersKit.shared.getPosts(type: postType, page: pageIndex)
        }.done { posts in
            let newPosts = posts.filter { !self.postIds.contains($0.id) }
            let newPostIds = newPosts.map { $0.id }
            self.posts.append(contentsOf: newPosts)
            self.postIds.formUnion(newPostIds)
            self.isFetching = false
        }
    }

    func reset() {
        posts = []
        postIds = Set()
        pageIndex = 1
        isFetching = false
    }

    func vote(on post: Post, upvote: Bool) -> Promise<Void> {
        if upvote {
            return HackersKit.shared.upvote(post: post)
        } else {
            return HackersKit.shared.unvote(post: post)
        }
    }
}

extension FeedViewModel {
    enum Section: CaseIterable {
        case main
    }
}
