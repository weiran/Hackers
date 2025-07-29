//
//  HNScraperShim.swift
//  Hackers
//
//  Created by Weiran Zhang on 25/05/2020.
//  Copyright © 2020 Weiran Zhang. All rights reserved.
//

import Foundation
import HNScraper

class HNScraperShim {
    weak var authenticationDelegate: HNScraperShimAuthenticationDelegate?

    init() {
        HNLogin.shared.addObserver(self)
    }

    internal func convert(error: HNScraper.HNScraperError) -> HackersKitError {
        switch error {
        case .notLoggedIn: return .unauthenticated
        default: return .scraperError
        }
    }
}

extension HNScraperShim { // posts
    func upvote(post: Post) async throws {
        let hnPost = try await getPost(id: post.id)
        try await scraperUpvote(post: hnPost)
    }

    func unvote(post: Post) async throws {
        let hnPost = try await getPost(id: post.id)
        try await scraperUnvote(post: hnPost)
    }

    private func getPost(id: Int) async throws -> HNPost {
        return try await withCheckedThrowingContinuation { continuation in
            HNScraper.shared.getPost(ById: String(id)) { (post, _, error) in
                if let post = post {
                    continuation.resume(returning: post)
                } else if let error = error {
                    continuation.resume(throwing: self.convert(error: error))
                } else {
                    continuation.resume(throwing: HackersKitError.scraperError)
                }
            }
        }
    }

    private func scraperUpvote(post: HNPost) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            HNScraper.shared.upvote(Post: post) { error in
                if let error = error {
                    continuation.resume(throwing: self.convert(error: error))
                } else {
                    continuation.resume()
                }
            }
        }
    }

    private func scraperUnvote(post: HNPost) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            HNScraper.shared.unvote(Post: post) { error in
                if let error = error {
                    continuation.resume(throwing: self.convert(error: error))
                } else {
                    continuation.resume()
                }
            }
        }
    }
}

extension HNScraperShim { // comments
    func upvote(comment: Comment, for post: Post) async throws {
        if comment.upvoteLink != nil {
            let hnComment = self.hnComment(for: comment)
            try await scraperUpvote(comment: hnComment)
        } else {
            let hnComment = try await getComment(id: comment.id, for: post)
            try await scraperUpvote(comment: hnComment)
        }
    }

    func unvote(comment: Comment, for post: Post) async throws {
        if comment.upvoteLink != nil {
            let hnComment = self.hnComment(for: comment)
            try await scraperUnvote(comment: hnComment)
        } else {
            let hnComment = try await getComment(id: comment.id, for: post)
            try await scraperUnvote(comment: hnComment)
        }
    }

    private func hnComment(for comment: Comment) -> HNComment {
        let hnComment = HNComment()
        hnComment.id = String(comment.id)
        hnComment.upvoteUrl = comment.upvoteLink
        return hnComment
    }

    private func getComment(id: Int, for post: Post) async throws -> HNComment {
        return try await withCheckedThrowingContinuation { continuation in
            HNScraper.shared.getComments(ByPostId: String(post.id)) { (_, comments, error) in
                if let error = error {
                    continuation.resume(throwing: self.convert(error: error))
                } else {
                    let comment = self.firstComment(in: comments, for: id)
                    if let comment = comment {
                        continuation.resume(returning: comment)
                    } else {
                        continuation.resume(throwing: HackersKitError.scraperError)
                    }
                }
            }
        }
    }

    /// Recursively search the comment tree for a specific `Comment` by `id`
    private func firstComment(in comments: [HNComment], for commentId: Int) -> HNComment? {
        let commentIdString = String(commentId)

        for comment in comments {
            if comment.id == commentIdString {
                return comment
            } else if !comment.replies.isEmpty {
                let replies = comment.replies.compactMap { $0 as? HNComment }
                return firstComment(in: replies, for: commentId)
            }
        }

        return nil
    }

    private func scraperUpvote(comment: HNComment) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            HNScraper.shared.upvote(Comment: comment) { error in
                if let error = error {
                    continuation.resume(throwing: self.convert(error: error))
                } else {
                    continuation.resume()
                }
            }
        }
    }

    private func scraperUnvote(comment: HNComment) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            HNScraper.shared.unvote(Comment: comment) { error in
                if let error = error {
                    continuation.resume(throwing: self.convert(error: error))
                } else {
                    continuation.resume()
                }
            }
        }
    }
}

extension HNScraperShim { // authentication
    func login(username: String, password: String) async throws -> User {
        return try await withCheckedThrowingContinuation { continuation in
            HNLogin.shared.logout() // need to logout first otherwise will always get current logged in session
            HNLogin.shared.login(username: username, psw: password) { (user, cookie, error) in
                if let user = user, cookie != nil {
                    let user = User(username: user.username, karma: user.karma, joined: user.age)
                    continuation.resume(returning: user)
                } else if let error = error {
                    continuation.resume(throwing: self.convert(error: error))
                } else {
                    continuation.resume(throwing: HackersKitAuthenticationError.unknown)
                }
            }
        }
    }

    func logout() {
        HNLogin.shared.logout()
    }

    func isAuthenticated() -> Bool {
        return HNLogin.shared.sessionCookie != nil
    }

    private func convert(error: HNLogin.HNLoginError) -> HackersKitAuthenticationError {
        switch error {
        case .badCredentials: return .badCredentials
        case .noInternet: return .noInternet
        case .serverUnreachable: return .serverUnreachable
        case .unknown: return .unknown
        }
    }
}

protocol HNScraperShimAuthenticationDelegate: AnyObject {
    func didAuthenticate(user: User, cookie: HTTPCookie)
}

extension HNScraperShim: HNLoginDelegate {
    func didLogin(user: HNUser, cookie: HTTPCookie) {
        let user = User(username: user.username, karma: user.karma, joined: user.age)
        authenticationDelegate?.didAuthenticate(user: user, cookie: cookie)
    }
}
