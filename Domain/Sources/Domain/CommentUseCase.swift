//
//  CommentUseCase.swift
//  Domain
//
//  Copyright © 2025 Weiran Zhang. All rights reserved.
//

import Foundation

/// A request to submit a comment through the Hacker News website.
public struct CommentSubmissionRequest: Sendable, Equatable {
    public let storyID: Int
    public let parentID: Int
    public let expectedAuthor: String
    public let text: String

    public init(storyID: Int, parentID: Int, expectedAuthor: String, text: String) {
        self.storyID = storyID
        self.parentID = parentID
        self.expectedAuthor = expectedAuthor
        self.text = text
    }
}

/// A server-confirmed comment hydrated from Hacker News-rendered data.
public struct SubmittedComment: Sendable, Equatable {
    public let id: Int
    public let parentID: Int
    public let author: String
    public let htmlText: String
    public let createdAt: Date

    public init(id: Int, parentID: Int, author: String, htmlText: String, createdAt: Date) {
        self.id = id
        self.parentID = parentID
        self.author = author
        self.htmlText = htmlText
        self.createdAt = createdAt
    }
}

/// Evidence retained for a submission whose transport outcome is unknown.
public struct CommentSubmissionAttempt: Sendable, Equatable {
    public let request: CommentSubmissionRequest
    public let baselineChildIDs: Set<Int>
    public let startedAt: Date

    public init(
        request: CommentSubmissionRequest,
        baselineChildIDs: Set<Int>,
        startedAt: Date
    ) {
        self.request = request
        self.baselineChildIDs = baselineChildIDs
        self.startedAt = startedAt
    }
}

public enum CommentSubmissionOutcome: Sendable, Equatable {
    case confirmed(SubmittedComment)
    case unconfirmed(CommentSubmissionAttempt)
}

public enum CommentSubmissionError: Error, Sendable, Equatable {
    case empty
    case invalidTarget
    case unauthenticated
    case commentingUnavailable
    case rejected(message: String?)
    case malformedResponse
}

public protocol CommentUseCase: Sendable {
    func getComments(for post: Post) async throws -> [Comment]

    /// Submits a comment through the authenticated Hacker News website. The
    /// baseline child IDs describe the caller's currently known children of the
    /// target parent and are used to resolve the server-created comment.
    func submitComment(
        _ request: CommentSubmissionRequest,
        baselineChildIDs: Set<Int>
    ) async throws -> CommentSubmissionOutcome

    /// Re-resolves an unconfirmed submission attempt without ever re-submitting.
    /// Returns the server-confirmed comment when one can be found.
    func reconcileComment(
        _ attempt: CommentSubmissionAttempt
    ) async throws -> SubmittedComment?
}
