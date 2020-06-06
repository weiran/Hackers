//
//  HackersKit.swift
//  Hackers
//
//  Created by Weiran Zhang on 11/05/2020.
//  Copyright © 2020 Weiran Zhang. All rights reserved.
//

import Foundation
import PromiseKit

class HackersKit {
    static let shared = HackersKit()

    let session = URLSession(configuration: .default)
    let scraperShim = HNScraperShim()

    weak var authenticationDelegate: HackerNewsAuthenticationDelegate?

    init() {
        scraperShim.authenticationDelegate = self
    }

    internal func fetchHtml(url: URL) -> Promise<String> {
        let (promise, seal) = Promise<String>.pending()

        session.dataTask(with: url) { data, _, error in
            if let data = data, let html = String(bytes: data, encoding: .utf8) {
                seal.fulfill(html)
            } else if let error = error {
                seal.reject(error)
            } else {
                seal.reject(HackersKitError.requestFailure)
            }
        }.resume()

        return promise
    }
}
