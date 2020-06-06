//
//  HackersKitExtensions.swift
//  Hackers
//
//  Created by Weiran Zhang on 21/09/2019.
//  Copyright © 2019 Weiran Zhang. All rights reserved.
//

import Foundation

extension Post {
    var hackerNewsURL: URL {
        return URL(string: "https://news.ycombinator.com/item?id=\(id)")!
    }
}
