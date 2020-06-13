//
//  HackersKit+CommentVoting.swift
//  Hackers
//
//  Created by Weiran Zhang on 25/05/2020.
//  Copyright © 2020 Weiran Zhang. All rights reserved.
//

import Foundation
import PromiseKit

extension HackersKit {
    func upvote(comment: Comment, for post: Post) -> Promise<Void> {
        scraperShim.upvote(comment: comment, for: post)
    }

    func unvote(comment: Comment, for post: Post) -> Promise<Void> {
        scraperShim.unvote(comment: comment, for: post)
    }
}
