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
        container.storyboardInitCompleted(CommentsViewController.self) { r, c in
            c.hackerNewsService = r.resolve(HackerNewsService.self)!
        }
        container.storyboardInitCompleted(SettingsViewController.self) { r, c in
            c.sessionService = r.resolve(SessionService.self)!
        }
        
        container.register(HackerNewsService.self) { _ in HackerNewsService() }
            .inObjectScope(.container)
        container.register(SessionService.self) { r in SessionService(hackerNewsService: r.resolve(HackerNewsService.self)!) }
            .inObjectScope(.container)
    }
    
    class func getService<T>() -> T? {
        return defaultContainer.resolve(T.self)
    }
}
