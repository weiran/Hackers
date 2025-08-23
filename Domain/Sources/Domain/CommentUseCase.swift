//
//  CommentUseCase.swift
//  Domain
//
//  Copyright © 2025 Weiran Zhang. All rights reserved.
//

import Foundation

public protocol CommentUseCase: Sendable {
    func getComments(for post: Post) async throws -> [Comment]
}
