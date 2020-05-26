//
//  HackerNewsData.swift
//  Hackers
//
//  Created by Weiran Zhang on 11/05/2020.
//  Copyright © 2020 Weiran Zhang. All rights reserved.
//

import Foundation
import PromiseKit

class HackerNewsData {
    public static let shared = HackerNewsData()

    let session = URLSession(configuration: .default)

    internal func fetchHtml(url: URL) -> Promise<String> {
        let (promise, seal) = Promise<String>.pending()

        session.dataTask(with: url) { data, _, error in
            if let data = data, let html = String(bytes: data, encoding: .utf8) {
                seal.fulfill(html)
            } else if let error = error {
                seal.reject(error)
            } else {
                seal.reject(HackerNewsError.typeError)
            }
        }.resume()

        return promise
    }
}
