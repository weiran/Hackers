//
//  MainTabBarController.swift
//  Hackers
//
//  Created by Weiran Zhang on 10/09/2017.
//  Copyright © 2017 Glass Umbrella. All rights reserved.
//

import UIKit
import libHN

class MainTabBarController: UITabBarController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let viewControllers = self.viewControllers else { return }
        
        for (index, viewController) in viewControllers.enumerated() {
            guard let splitViewController = viewController as? UISplitViewController,
                let navigationController = splitViewController.viewControllers.first as? UINavigationController,
                let newsViewController = navigationController.viewControllers.first as? NewsViewController
                else {
                    return
            }
            
            var postType: PostFilterType?
            var typeName: String?
            var iconName: String?
            
            switch index {
                case 1:
                    postType = .ask
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
                case 0:
                    fallthrough
                default:
                    postType = .top
                    typeName = "Top"
                    iconName = "TopIcon"
            }
            
            newsViewController.postType = postType
            splitViewController.tabBarItem.title = typeName
            splitViewController.tabBarItem.image = UIImage(named: iconName!)
        }
        
        tabBar.clipsToBounds = true
    }
}
