//
//  HackersKit.swift
//  Hackers
//
//  Created by Weiran Zhang on 11/05/2020.
//  Copyright © 2020 Weiran Zhang. All rights reserved.
//

import Foundation

class HackersKit {
    static let shared = HackersKit()
    static let hackerNewsBaseURL = "https://news.ycombinator.com"
    static let hackerNewsHost = "news.ycombinator.com"

    let networkManager = NetworkManager()

    weak var authenticationDelegate: HackerNewsAuthenticationDelegate?

    internal func fetchHtml(url: URL) async throws -> String {
        return try await networkManager.get(url: url)
    }
}

protocol HackerNewsAuthenticationDelegate: AnyObject {
    func didAuthenticate(user: User)
}
