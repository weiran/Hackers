//
//  NavigationService.swift
//  Hackers
//
//  Created by Weiran Zhang on 06/06/2020.
//  Copyright © 2020 Weiran Zhang. All rights reserved.
//

import UIKit

class NavigationService {
    weak var mainTabBarController: MainTabBarController?

    func showPost(id: Int) {
        if let splitController = visibleViewController(),
            let navController = viewController(for: "PostViewNavigationController") as? UINavigationController,
            let controller = navController.children.first as? CommentsViewController {
            controller.postId = id
            splitController.showDetailViewController(navController, sender: self)
        }
    }

    private func visibleViewController() -> UISplitViewController? {
        guard let controller = mainTabBarController else {
            return nil
        }
        return controller.viewControllers?[controller.selectedIndex] as? UISplitViewController
    }

    private func viewController(for identifier: String) -> UIViewController? {
        let storyboard = UIStoryboard(name: "Main", bundle: .main)
        return storyboard.instantiateViewController(identifier: identifier)
    }
}
