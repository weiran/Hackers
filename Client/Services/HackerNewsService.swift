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
}
