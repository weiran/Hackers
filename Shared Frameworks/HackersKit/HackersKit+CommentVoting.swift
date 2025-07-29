//
//  HackersKit+CommentVoting.swift
//  Hackers
//
//  Created by Weiran Zhang on 25/05/2020.
//  Copyright © 2020 Weiran Zhang. All rights reserved.
//

import Foundation

extension HackersKit {
    func upvote(comment: Comment, for post: Post) async throws {
        try await scraperShim.upvote(comment: comment, for: post)
    }

    func unvote(comment: Comment, for post: Post) async throws {
        try await scraperShim.unvote(comment: comment, for: post)
    }
}
