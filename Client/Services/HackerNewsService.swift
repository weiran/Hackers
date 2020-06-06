//
//  HackerNewsService.swift
//  Hackers
//
//  Created by Weiran Zhang on 21/04/2019.
//  Copyright © 2019 Weiran Zhang. All rights reserved.
//

import PromiseKit
import HNScraper

class HackerNewsService {
    func login(username: String, password: String) -> Promise<(HNUser?, HTTPCookie?)> {
        HNLogin.shared.logout() // need to logout first otherwise will always get current logged in session

        let (promise, seal) = Promise<(HNUser?, HTTPCookie?)>.pending()
        HNLogin.shared.login(username: username, psw: password) { (user, cookie, error) in
            if let error = error, cookie == nil {
                seal.reject(error)
            } else {
                seal.fulfill((user, cookie))
            }
        }
        return promise
    }

    func logout() {
        HNLogin.shared.logout()
    }

    func upvote(post: HNPost) -> Promise<Void> {
        let (promise, seal) = Promise<Void>.pending()
        HNScraper.shared.upvote(Post: post) { error in
            if let error = error {
                seal.reject(error)
            } else {
                seal.fulfill(())
            }
        }
        return promise
    }

    func unvote(post: HNPost) -> Promise<Void> {
        let (promise, seal) = Promise<Void>.pending()
        HNScraper.shared.unvote(Post: post) { error in
            if let error = error {
                seal.reject(error)
            } else {
                seal.fulfill(())
            }
        }
        return promise
    }

    func upvote(comment: HNComment) -> Promise<Void> {
        let (promise, seal) = Promise<Void>.pending()
        HNScraper.shared.upvote(Comment: comment) { error in
            if let error = error {
                seal.reject(error)
            } else {
                seal.fulfill(())
            }
        }
        return promise
    }

    func unvote(comment: HNComment) -> Promise<Void> {
        let (promise, seal) = Promise<Void>.pending()
        HNScraper.shared.unvote(Comment: comment) { error in
            if let error = error {
                seal.reject(error)
            } else {
                seal.fulfill(())
            }
        }
        return promise
    }
}
