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

    let session = URLSession(configuration: .default)
    let scraperShim = HNScraperShim()

    weak var authenticationDelegate: HackerNewsAuthenticationDelegate?

    init() {
        scraperShim.authenticationDelegate = self
    }

    internal func fetchHtml(url: URL) async throws -> String {
        let (data, _) = try await session.data(from: url)

        guard let html = String(bytes: data, encoding: .utf8) else {
            throw HackersKitError.requestFailure
        }

        return html
    }
}
