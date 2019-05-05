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
        
        guard let viewControllers = self.viewControllers else { return }
        
        for (index, viewController) in viewControllers.enumerated() {
            guard let splitViewController = viewController as? UISplitViewController,
                let navigationController = splitViewController.viewControllers.first as? UINavigationController,
                let newsViewController = navigationController.viewControllers.first as? NewsViewController
                else {
                    return
            }
            
            let (postType, typeName, iconName) = tabItems(for: index)
            newsViewController.postType = postType
            splitViewController.tabBarItem.title = typeName
            splitViewController.tabBarItem.image = UIImage(named: iconName)
        }
        
        tabBar.clipsToBounds = true
    }
    
    private func tabItems(for index: Int) -> (HNScraper.PostListPageName, String, String) {
        var postType = HNScraper.PostListPageName.news
        var typeName = "Top"
        var iconName = "TopIcon"
        
        switch index {
        case 0:
            postType = .news
            typeName = "Top"
            iconName = "TopIcon"
            break
        case 1:
            postType = .asks
            typeName = "Ask"
            iconName = "AskIcon"
            break
        case 2:
            postType = .jobs
            typeName = "Jobs"
            iconName = "JobsIcon"
            break
        case 3:
            postType = .new
            typeName = "New"
            iconName = "NewIcon"
            break
        default:
            break
        }
        
        return (postType, typeName, iconName)
    }
}

extension MainTabBarController: Themed {
    func applyTheme(_ theme: AppTheme) {
        tabBar.barTintColor = theme.barBackgroundColor
        tabBar.tintColor = theme.barForegroundColor
    }
}
