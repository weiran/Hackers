//
//  HackerNewsService.swift
//  Hackers
//
//  Created by Weiran Zhang on 21/04/2019.
//  Copyright © 2019 Glass Umbrella. All rights reserved.
//

import PromiseKit
import HNScraper

class HackerNewsService {
    public func getPosts(of type: HNScraper.PostListPageName, nextPageIdentifier: String? = nil) -> Promise<([HNPost], String?)> {
        let (promise, seal) = Promise<([HNPost], String?)>.pending()
        let completionHandler: HNScraper.PostListDownloadCompletionHandler = { (posts, nextPageIdentifier, error) in
            if let error = error {
                seal.reject(error)
            } else {
                seal.fulfill((posts, nextPageIdentifier))
            }
        }
        
        if let nextPageIdentifier = nextPageIdentifier {
            HNScraper.shared.getMoreItems(linkForMore: nextPageIdentifier, completionHandler: completionHandler)
        } else {
            HNScraper.shared.getPostsList(page: type, completion: completionHandler)
        }
        
        return promise
    }
    
    public func getComments(of post: HNPost) -> Promise<[HNComment]?> {
        let (promise, seal) = Promise<[HNComment]?>.pending()
        HNScraper.shared.getComments(ForPost: post, buildHierarchy: false, offsetComments: false) { (post, comments, error) in
            if let error = error {
                seal.reject(error)
            } else {
                seal.fulfill(comments)
            }
        }
        return promise
    }
    
    public func login(username: String, password: String) -> Promise<(HNUser?, HTTPCookie?)> {
        HNLogin.shared.logout() // need to logout first otherwise will always get current logged in session
        
        let (promise, seal) = Promise<(HNUser?, HTTPCookie?)>.pending()
        HNLogin.shared.login(username: username, psw: password) { (user, cookie, error) in
            if let error = error {
                seal.reject(error)
            } else {
                seal.fulfill((user, cookie))
            }
        }
        return promise
    }
    
    public func upvote(post: HNPost) -> Promise<Void> {
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
    
    public func unvote(post: HNPost) -> Promise<Void> {
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
}
