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

        container.storyboardInitCompleted(FeedCollectionViewController.self) { resolver, controller in
            controller.authenticationUIService = resolver.resolve(AuthenticationUIService.self)!
        }
        container.storyboardInitCompleted(CommentsViewController.self) { resolver, controller in
            controller.authenticationUIService = resolver.resolve(AuthenticationUIService.self)!
            controller.swipeCellKitActions = resolver.resolve(SwipeCellKitActions.self)!
            controller.navigationService = resolver.resolve(NavigationService.self)!
        }
        container.storyboardInitCompleted(SettingsViewController.self) { resolver, controller in
            controller.sessionService = resolver.resolve(SessionService.self)!
            controller.authenticationUIService = resolver.resolve(AuthenticationUIService.self)!
        }

        container.register(SessionService.self) { _ in
            SessionService()
        }.inObjectScope(.container)
        container.register(AuthenticationUIService.self) { resolver in
            AuthenticationUIService(sessionService: resolver.resolve(SessionService.self)!)
        }.inObjectScope(.container)
        container.register(SwipeCellKitActions.self) { resolver in
            SwipeCellKitActions(
                authenticationUIService: resolver.resolve(AuthenticationUIService.self)!)
        }
        container.register(NavigationService.self) { _ in
            NavigationService()
        }.inObjectScope(.container)
    }

    class func getService<T>() -> T? {
        return defaultContainer.resolve(T.self)
    }
}
