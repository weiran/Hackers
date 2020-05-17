//
//  HackerNewsService.swift
//  Hackers
//
//  Created by Weiran Zhang on 21/04/2019.
//  Copyright © 2019 Glass Umbrella. All rights reserved.
//
// swiftlint:disable trailing_whitespace

import PromiseKit
import HNScraper
import Combine

class HackerNewsService {
    private var cancellableBag = CancellableBag()
    public func getPosts(of type: HNScraper.PostListPageName,
                         nextPageIdentifier: String? = nil) -> Promise<([HNPost], String?)> {
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
        combineGetComments(postItemId: Int(post.id)!)
        let (promise, seal) = Promise<[HNComment]?>.pending()
        HNScraper.shared.getComments(ForPost: post,
                                     buildHierarchy: false,
                                     offsetComments: false) { (_, comments, error) in
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
            if let error = error, cookie == nil {
                seal.reject(error)
            } else {
                seal.fulfill((user, cookie))
            }
        }
        return promise
    }

    public func logout() {
        HNLogin.shared.logout()
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

    public func upvote(comment: HNComment) -> Promise<Void> {
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

    public func unvote(comment: HNComment) -> Promise<Void> {
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

struct StoryItem: Codable {
    // swiftlint:disable identifier_name
    var by: String? = ""
    var id: Int = 0
    var kids: [Int] = []
    var title: String = ""
}

struct CommentItem: Codable {
    // swiftlint:disable identifier_name
    var by: String? = ""
    var id: Int = 0
    var kids: [Int]? = []
    var parent: Int = 0
    var text: String? = ""
}

extension HackerNewsService {
    static private var baseURL = "https://hacker-news.firebaseio.com/v0"
    
    private func makeUrl(itemId: Int) -> URL {
        return URL(string: "\(HackerNewsService.baseURL)/item/\(itemId).json")!
    }
    
    public func fetchComment(id: Int) -> AnyPublisher<CommentItem, Error> {
        let url = makeUrl(itemId: id)
        return URLSession.shared.dataTaskPublisher(for: url)
            .map { $0.data }
            .decode(type: CommentItem.self, decoder: JSONDecoder())
            .eraseToAnyPublisher()
    }
    
    public func combineGetComments(postItemId: Int) -> AnyPublisher<[CommentItem], Error> {
        
        // recommended test data
        // post url -> https://news.ycombinator.com/item?id=23209225
        // post title -> "UC Berkeley hosted a virtual graduation on Minecraft"
        // descendants count: 8
        // let postItemId = 23209225
        let publisher = URLSession.shared.dataTaskPublisher(for: makeUrl(itemId: postItemId))
            .map { $0.data }
            .decode(type: StoryItem.self, decoder: JSONDecoder())
            .map { $0.kids }
            .flatMap { ids -> AnyPublisher<[CommentItem], Error> in
                let comments = ids.map { self.fetchComment(id: $0) }
                return Publishers.ZipMany(comments)
                    .eraseToAnyPublisher()
        }
        .eraseToAnyPublisher()
        
        // test printing out results
        publisher
            .sink(receiveCompletion: { (error) in
                // error to handle
                print(error)
            }, receiveValue: { comments in
                comments.forEach { (comment) in
                    print("by \(comment.by)")
                }
            })
            .cancelled(by: cancellableBag)
        
        return publisher
    }
}
