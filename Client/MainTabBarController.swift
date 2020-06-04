//
//  MainTabBarController.swift
//  Hackers
//
//  Created by Weiran Zhang on 10/09/2017.
//  Copyright © 2017 Weiran Zhang. All rights reserved.
//

import UIKit

class MainTabBarController: UITabBarController {
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTheming()

        guard let viewControllers = viewControllers else { return }

        for (index, viewController) in viewControllers.enumerated() {
            guard let splitViewController = viewController as? UISplitViewController,
                let navigationController = splitViewController.viewControllers.first as? UINavigationController,
                let newsViewController = navigationController.viewControllers.first as? NewsViewController
                else { return }

            if let tabItem = self.tabItem(for: index) {
                newsViewController.postType = tabItem.postType
                splitViewController.tabBarItem.title = tabItem.typeName
                splitViewController.tabBarItem.image = UIImage(systemName: tabItem.iconName)
                splitViewController.tabBarItem.selectedImage = UIImage(systemName: tabItem.selectedIconName)
            }
        }

        tabBar.clipsToBounds = true
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let viewController = OnboardingService.onboardingViewController() {
            present(viewController, animated: true)
        }
    }

    private func tabItem(for index: Int) -> TabItem? {
        switch index {
        case 0:
            return TabItem(postType: .news, typeName: "Top",
                           iconName: "globe", selectedIconName: "globe")
        case 1:
            return TabItem(postType: .ask, typeName: "Ask",
                           iconName: "bubble.left", selectedIconName: "bubble.left.fill")
        case 2:
            return TabItem(postType: .jobs, typeName: "Jobs",
                           iconName: "briefcase", selectedIconName: "briefcase.fill")
        case 3:
            return TabItem(postType: .newest, typeName: "New",
                           iconName: "clock", selectedIconName: "clock.fill")
        default:
            return nil
        }
    }

    struct TabItem {
        let postType: HackerNewsPostType
        let typeName: String
        let iconName: String
        let selectedIconName: String
    }
}

extension MainTabBarController {
    func showPost(id: Int) {
        if let splitController = visibleViewController(),
            let navController = viewController(for: "PostViewNavigationController") as? UINavigationController,
            let vc = navController.children.first as? CommentsViewController {
            vc.postId = id
            splitController.showDetailViewController(navController, sender: self)
        }
    }

    private func visibleViewController() -> UISplitViewController? {
        let viewController = viewControllers?[selectedIndex] as? UISplitViewController
        return viewController
    }

    private func viewController(for identifier: String) -> UIViewController? {
        let storyboard = UIStoryboard(name: "Main", bundle: .main)
        return storyboard.instantiateViewController(identifier: identifier)
    }
}

extension MainTabBarController: Themed {
    func applyTheme(_ theme: AppTheme) {
        overrideUserInterfaceStyle = theme.userInterfaceStyle
    }
}
