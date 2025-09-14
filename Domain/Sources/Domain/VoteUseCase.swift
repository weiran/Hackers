//
//  VoteUseCase.swift
//  Domain
//
//  Copyright © 2025 Weiran Zhang. All rights reserved.
//

import Foundation

public protocol VoteUseCase: Sendable {
    func upvote(post: Post) async throws
    func upvote(comment: Comment, for post: Post) async throws
}
