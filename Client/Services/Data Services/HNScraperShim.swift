//
//  HNScraperShim.swift
//  Hackers
//
//  Created by Weiran Zhang on 25/05/2020.
//  Copyright © 2020 Weiran Zhang. All rights reserved.
//

import Foundation
import HNScraper
import PromiseKit

class HNScraperShim {
    weak var authenticationDelegate: HNScraperShimAuthenticationDelegate?

    init() {
        HNLogin.shared.addObserver(self)
    }

    internal func convert(error: HNScraper.HNScraperError) -> HackerNewsError {
        switch error {
        case .notLoggedIn: return .unauthenticated
        default: return .scraperError
        }
    }
}

extension HNScraperShim { // posts
    func upvote(post: HackerNewsPost) -> Promise<Void> {
        return firstly {
            getPost(id: post.id)
        }.then { post in
            self.scraperUpvote(post: post)
        }
    }

    func unvote(post: HackerNewsPost) -> Promise<Void> {
        return firstly {
            getPost(id: post.id)
        }.then { post in
            self.scraperUnvote(post: post)
        }
    }

    private func getPost(id: Int) -> Promise<HNPost> {
        let (promise, seal) = Promise<HNPost>.pending()
        HNScraper.shared.getPost(ById: String(id)) { (post, _, error) in
            if let post = post {
                seal.fulfill(post)
            } else if let error = error {
                seal.reject(self.convert(error: error))
            } else {
                seal.reject(HackerNewsError.scraperError)
            }
        }
        return promise
    }

    private func scraperUpvote(post: HNPost) -> Promise<Void> {
        let (promise, seal) = Promise<Void>.pending()
        HNScraper.shared.upvote(Post: post) { error in
            if let error = error {
                seal.reject(self.convert(error: error))
            } else {
                seal.fulfill(())
            }
        }
        return promise
    }

    private func scraperUnvote(post: HNPost) -> Promise<Void> {
        let (promise, seal) = Promise<Void>.pending()
        HNScraper.shared.unvote(Post: post) { error in
            if let error = error {
                seal.reject(self.convert(error: error))
            } else {
                seal.fulfill(())
            }
        }
        return promise
    }
}

extension HNScraperShim { // comments
    func upvote(comment: HackerNewsComment, for post: HackerNewsPost) -> Promise<Void> {
        return firstly {
            getComment(id: comment.id, for: post)
        }.then { comment in
            self.scraperUpvote(comment: comment)
        }
    }

    func unvote(comment: HackerNewsComment, for post: HackerNewsPost) -> Promise<Void> {
        return firstly {
            getComment(id: comment.id, for: post)
        }.then { comment in
            self.scraperUnvote(comment: comment)
        }
    }

    private func getComment(id: Int, for post: HackerNewsPost) -> Promise<HNComment> {
        let (promise, seal) = Promise<HNComment>.pending()

        HNScraper.shared.getComments(ByPostId: String(post.id)) { (_, comments, error) in
            if let error = error {
                seal.reject(self.convert(error: error))
            } else {
                let comment = self.firstComment(in: comments, for: id)
                if let comment = comment {
                    seal.fulfill(comment)
                } else {
                    seal.reject(HackerNewsError.scraperError)
                }
            }
        }

        return promise
    }

    /// Recursively search the comment tree for a specific `HackerNewsComment` by `id`
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

    private func scraperUpvote(comment: HNComment) -> Promise<Void> {
        let (promise, seal) = Promise<Void>.pending()
        HNScraper.shared.upvote(Comment: comment) { error in
            if let error = error {
                seal.reject(self.convert(error: error))
            } else {
                seal.fulfill(())
            }
        }
        return promise
    }

    private func scraperUnvote(comment: HNComment) -> Promise<Void> {
        let (promise, seal) = Promise<Void>.pending()
        HNScraper.shared.unvote(Comment: comment) { error in
            if let error = error {
                seal.reject(self.convert(error: error))
            } else {
                seal.fulfill(())
            }
        }
        return promise
    }
}

extension HNScraperShim { // authentication
    func login(username: String, password: String) -> Promise<HackerNewsUser> {
        let (promise, seal) = Promise<HackerNewsUser>.pending()
        HNLogin.shared.logout() // need to logout first otherwise will always get current logged in session
        HNLogin.shared.login(username: username, psw: password) { (user, cookie, error) in
            if let user = user, cookie != nil {
                let hackerNewsUser = HackerNewsUser(username: user.username, karma: user.karma, joined: user.age)
                seal.fulfill(hackerNewsUser)
            } else if let error = error {
                seal.reject(self.convert(error: error))
            } else {
                seal.reject(HackerNewsAuthenticationError.unknown)
            }
        }
        return promise
    }

    func logout() {
        HNLogin.shared.logout()
    }

    func isAuthenticated() -> Bool {
        return HNLogin.shared.sessionCookie != nil
    }

    private func convert(error: HNLogin.HNLoginError) -> HackerNewsAuthenticationError {
        switch error {
        case .badCredentials: return .badCredentials
        case .noInternet: return .noInternet
        case .serverUnreachable: return .serverUnreachable
        case .unknown: return .unknown
        }
    }
}

protocol HNScraperShimAuthenticationDelegate: class {
    func didAuthenticate(user: HackerNewsUser, cookie: HTTPCookie)
}

extension HNScraperShim: HNLoginDelegate {
    func didLogin(user: HNUser, cookie: HTTPCookie) {
        let hackerNewsUser = HackerNewsUser(username: user.username, karma: user.karma, joined: user.age)
        authenticationDelegate?.didAuthenticate(user: hackerNewsUser, cookie: cookie)
    }
}
