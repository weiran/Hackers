//
//  SwinjectStoryboardExtension.swift
//  Hackers
//
//  Created by Weiran Zhang on 21/04/2019.
//  Copyright © 2019 Glass Umbrella. All rights reserved.
//

import SwinjectStoryboard

extension SwinjectStoryboard {
    @objc class func setup() {
        let container = defaultContainer
        container.storyboardInitCompleted(NewsViewController.self) { r, c in
            c.hackerNewsService = r.resolve(HackerNewsService.self)!
        }
        container.register(HackerNewsService.self) { _ in HackerNewsService() }
            .inObjectScope(.container)
    }
}
