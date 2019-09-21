//
//  HNPostExtensions.swift
//  Hackers
//
//  Created by Weiran Zhang on 21/09/2019.
//  Copyright © 2019 Glass Umbrella. All rights reserved.
//

import HNScraper

extension HNPost {
    var hackerNewsURL: URL {
        return URL(string: "https://news.ycombinator.com/item?id=" + id)!
    }
}
