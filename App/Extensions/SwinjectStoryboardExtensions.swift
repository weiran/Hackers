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

        container.storyboardInitCompleted(CommentsViewController.self) { resolver, controller in
            controller.swipeCellKitActions = resolver.resolve(SwipeCellKitActions.self)!
            controller.navigationService = resolver.resolve(NavigationService.self)!
        }
        container.storyboardInitCompleted(SettingsViewController.self) { resolver, controller in
            controller.sessionService = resolver.resolve(SessionService.self)!
        }

        container.register(SessionService.self) { _ in
            SessionService()
        }.inObjectScope(.container)
        container.register(SwipeCellKitActions.self) { _ in
            SwipeCellKitActions()
        }
        container.register(NavigationService.self) { _ in
            NavigationService()
        }.inObjectScope(.container)
    }

    class func getService<T>() -> T? {
        return defaultContainer.resolve(T.self)
    }
}
