//
//  SwinjectStoryboardExtension.swift
//  Hackers
//
//  Created by Weiran Zhang on 21/04/2019.
//  Copyright © 2019 Weiran Zhang. All rights reserved.
//

import SwinjectStoryboard

extension SwinjectStoryboard {
    @objc class func setup() {
        let container = defaultContainer
        container.storyboardInitCompleted(NewsViewController.self) { resolver, controller in
            controller.hackerNewsService = resolver.resolve(HackerNewsService.self)!
            controller.authenticationUIService = resolver.resolve(AuthenticationUIService.self)!
            controller.swipeCellKitActions = resolver.resolve(SwipeCellKitActions.self)!
        }
        container.storyboardInitCompleted(CommentsViewController.self) { resolver, controller in
            controller.hackerNewsService = resolver.resolve(HackerNewsService.self)!
            controller.authenticationUIService = resolver.resolve(AuthenticationUIService.self)!
            controller.swipeCellKitActions = resolver.resolve(SwipeCellKitActions.self)!
        }
        container.storyboardInitCompleted(SettingsViewController.self) { resolver, controller in
            controller.sessionService = resolver.resolve(SessionService.self)!
            controller.authenticationUIService = resolver.resolve(AuthenticationUIService.self)!
        }

        container.register(HackerNewsService.self) { _ in HackerNewsService() }
            .inObjectScope(.container)
        container.register(SessionService.self) { resolver in
            SessionService(hackerNewsService: resolver.resolve(HackerNewsService.self)!)
        }.inObjectScope(.container)
        container.register(AuthenticationUIService.self) { resolver in
            AuthenticationUIService(
                hackerNewsService: resolver.resolve(HackerNewsService.self)!,
                sessionService: resolver.resolve(SessionService.self)!)
        }.inObjectScope(.container)
        container.register(SwipeCellKitActions.self) { resolver in
            SwipeCellKitActions(
                authenticationUIService: resolver.resolve(AuthenticationUIService.self)!,
                hackerNewsService: resolver.resolve(HackerNewsService.self)!)
        }
    }

    class func getService<T>() -> T? {
        return defaultContainer.resolve(T.self)
    }
}
