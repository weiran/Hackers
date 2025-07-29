//
//  HackersKit+PostVoting.swift
//  Hackers
//
//  Created by Weiran Zhang on 25/05/2020.
//  Copyright © 2020 Weiran Zhang. All rights reserved.
//

import Foundation

extension HackersKit {
    func upvote(post: Post) async throws {
        try await scraperShim.upvote(post: post)
    }

    func unvote(post: Post) async throws {
        try await scraperShim.unvote(post: post)
    }
}
