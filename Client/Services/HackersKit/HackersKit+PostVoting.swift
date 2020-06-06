//
//  HackersKit+PostVoting.swift
//  Hackers
//
//  Created by Weiran Zhang on 25/05/2020.
//  Copyright © 2020 Weiran Zhang. All rights reserved.
//

import Foundation
import PromiseKit

extension HackersKit {
    func upvote(post: Post) -> Promise<Void> {
        scraperShim.upvote(post: post)
    }

    func unvote(post: Post) -> Promise<Void> {
        scraperShim.unvote(post: post)
    }
}
