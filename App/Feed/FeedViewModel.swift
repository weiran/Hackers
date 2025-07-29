//
//  FeedViewModel.swift
//  Hackers
//
//  Created by Weiran Zhang on 06/07/2020.
//  Copyright © 2020 Weiran Zhang. All rights reserved.
//

import UIKit

class FeedViewModel {
    var posts: [Post] = []
    var postIds: Set<Int> = Set()
    var postType: PostType = .news
    var pageIndex = 1
    var lastPostId = 0
    var isFetching = false

    func fetchFeed(fetchNextPage: Bool = false) async throws {
        guard !isFetching else {
            return
        }

        if fetchNextPage {
            if postType == .newest || postType == .jobs {
                lastPostId = posts.last?.id ?? lastPostId
            } else {
                pageIndex += 1
            }
        }

        isFetching = true

        do {
            let posts = try await HackersKit.shared.getPosts(type: postType, page: pageIndex, nextId: lastPostId)
            let newPosts = posts.filter { !self.postIds.contains($0.id) }
            let newPostIds = newPosts.map { $0.id }
            self.posts.append(contentsOf: newPosts)
            self.postIds.formUnion(newPostIds)
            self.isFetching = false
        } catch {
            self.isFetching = false
            throw error
        }
    }

    func reset() {
        posts = []
        postIds = Set()
        pageIndex = 1
        lastPostId = 0
        isFetching = false
    }

    func vote(on post: Post, upvote: Bool) async throws {
        if upvote {
            try await HackersKit.shared.upvote(post: post)
        } else {
            try await HackersKit.shared.unvote(post: post)
        }
    }
}

extension FeedViewModel {
    enum Section: CaseIterable {
        case main
    }
}
