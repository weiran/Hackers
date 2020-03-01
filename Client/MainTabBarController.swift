//
//  MainTabBarController.swift
//  Hackers
//
//  Created by Weiran Zhang on 10/09/2017.
//  Copyright © 2017 Glass Umbrella. All rights reserved.
//

import UIKit
import HNScraper

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
            return TabItem(postType: .asks, typeName: "Ask",
                           iconName: "bubble.left", selectedIconName: "bubble.left.fill")
        case 2:
            return TabItem(postType: .jobs, typeName: "Jobs",
                           iconName: "briefcase", selectedIconName: "briefcase.fill")
        case 3:
            return TabItem(postType: .new, typeName: "New",
                           iconName: "clock", selectedIconName: "clock.fill")
        default:
            return nil
        }
    }

    struct TabItem {
        let postType: HNScraper.PostListPageName
        let typeName: String
        let iconName: String
        let selectedIconName: String
    }
}

extension MainTabBarController: Themed {
    func applyTheme(_ theme: AppTheme) {
        overrideUserInterfaceStyle = theme.userInterfaceStyle
    }
}
